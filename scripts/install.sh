#!/usr/bin/env bash

set -e
set -u

GREEN='\033[1;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Avoids trust prompts; the live ISO's /etc is read-only, so write to a tmpdir
# and point at it with NIX_USER_CONF_FILES (survives sudo).
echo -e "${GREEN}Preseeding nix configuration...${NC}"
NIX_CONF_TMP=$(mktemp -d)/nix.conf
cat > "$NIX_CONF_TMP" << 'EOF'
experimental-features = nix-command flakes
accept-flake-config = true
warn-dirty = false
extra-substituters = https://nix-community.cachix.org https://attic.xuyh0120.win/lantian https://cache.numtide.com
extra-trusted-public-keys = nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc= niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNthL[...]
EOF
export NIX_USER_CONF_FILES="$NIX_CONF_TMP"
echo -e "${GREEN}Nix configuration preseeded at $NIX_CONF_TMP${NC}"

echo -e "${GREEN}Configuring git...${NC}"
git config --global user.name "your-username"
git config --global user.email "user@example.com"

echo -e "${GREEN}Checking GitHub authentication status...${NC}"
if ! nix-shell -p gh --run 'gh auth status' &>/dev/null; then
    echo -e "${GREEN}Not logged in. Starting authentication...${NC}"
    nix-shell -p git gh --run 'gh auth login'
else
    echo -e "${GREEN}Already authenticated with GitHub.${NC}"
fi

# $HOME on the live ISO is temporary; the repo is moved to /mnt/etc/nixos below
REPO_DIR="$HOME/nixos"
if [ -d "$REPO_DIR" ]; then
    echo -e "${GREEN}NixOS repository already exists at $REPO_DIR${NC}"

    echo -e "${GREEN}Fetching latest branches...${NC}"
    cd "$REPO_DIR"
    git fetch --all

    echo -e "${GREEN}Available branches:${NC}"
    git branch -r | grep -v HEAD | sed 's/origin\///'

    echo ""
    read -rp "Do you want to switch to a different branch? (y/N): " switch_branch
    switch_branch=${switch_branch:-n}

    if [[ "$switch_branch" =~ ^[yY]$ ]]; then
        read -rp "Enter branch name to switch to: " branch_name
        git switch "$branch_name"
        git pull origin "$branch_name"
    else
        read -rp "Do you want to remove and re-clone fresh? (y/N): " reclone
        reclone=${reclone:-n}

        if [[ "$reclone" =~ ^[yY]$ ]]; then
            cd ~
            echo -e "${GREEN}Removing existing repository...${NC}"
            rm -rf "$REPO_DIR"
            echo -e "${GREEN}Cloning fresh copy...${NC}"
            git clone https://github.com/0x6a64/NixOS-Public.git "$REPO_DIR"
        else
            echo -e "${GREEN}Using existing repository.${NC}"
        fi
    fi
else
    echo -e "${GREEN}Cloning nixos repository...${NC}"
    git clone https://github.com/0x6a64/NixOS-Public.git "$REPO_DIR"
fi

echo -e "${GREEN}Running disko to partition and format disks...${NC}"
if ! sudo --preserve-env=NIX_USER_CONF_FILES nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount "$REPO_DIR/disko.nix"; then
    echo "ERROR: Disko failed to partition and format disks"
    exit 1
fi

echo -e "${GREEN}Current mount points:${NC}"
mount | grep /mnt || true

echo ""
echo -e "${GREEN}Validating mount points...${NC}"
if ! mountpoint -q /mnt; then
    echo "ERROR: /mnt is not mounted"
    exit 1
fi

if ! mountpoint -q /mnt/boot; then
    echo "ERROR: /mnt/boot is not mounted"
    exit 1
fi

echo -e "${GREEN}Mount points validated successfully${NC}"

echo ""
read -rp "Press Enter to continue with installation or Ctrl+C to abort..."

echo -e "${GREEN}Generating hardware configuration...${NC}"
sudo nixos-generate-config --no-filesystems --root /mnt

# The generated config's kvm module must match the CPU running this installer,
# catching a hardware-configuration.nix carried over from different hardware.
CPU_VENDOR=$(grep -m1 "vendor_id" /proc/cpuinfo | awk '{print $3}')
case "$CPU_VENDOR" in
    GenuineIntel) EXPECTED_KVM_MODULE="kvm-intel" ;;
    AuthenticAMD) EXPECTED_KVM_MODULE="kvm-amd" ;;
    *)
        echo "ERROR: Unrecognized CPU vendor '$CPU_VENDOR' in /proc/cpuinfo"
        exit 1
        ;;
esac

if ! 'grep' -q "\"$EXPECTED_KVM_MODULE\"" /mnt/etc/nixos/hardware-configuration.nix; then
    echo "ERROR: Generated hardware-configuration.nix doesn't contain '$EXPECTED_KVM_MODULE'"
    echo "for detected CPU vendor '$CPU_VENDOR'. Refusing to continue - inspect"
    echo "/mnt/etc/nixos/hardware-configuration.nix manually."
    exit 1
fi

echo -e "${GREEN}Sanity check passed: $EXPECTED_KVM_MODULE present for $CPU_VENDOR${NC}"

echo -e "${GREEN}Moving hardware configuration...${NC}"
rm -f "$REPO_DIR/hardware-configuration.nix"
sudo mv /mnt/etc/nixos/hardware-configuration.nix "$REPO_DIR/"
sudo chown "$(id -u):$(id -g)" "$REPO_DIR/hardware-configuration.nix"

echo -e "${GREEN}Moving configuration files to /mnt/etc/nixos...${NC}"
# Moves everything including .git, emptying $REPO_DIR — the repo lives in
# /etc/nixos after reboot, so run post-install.sh from there or a fresh clone.
shopt -s nullglob dotglob
items=("$REPO_DIR"/*)
shopt -u nullglob dotglob

total=${#items[@]}
count=0
for item in "${items[@]}"; do
  filename=$(basename "$item")
  sudo mv "$item" /mnt/etc/nixos/
  count=$((count + 1))
  printf "\r[%d/%d] Moving: %-50s" "$count" "$total" "$filename"
done
echo "" 

echo -e "${GREEN}Copying sops age key to persist...${NC}"

KEYS_FILE=""
while [ ! -f "$KEYS_FILE" ]; do
    read -rp "Enter the path to keys.txt: " KEYS_FILE
    
    if [ ! -f "$KEYS_FILE" ]; then
        echo -e "${RED}Error: File not found at '$KEYS_FILE'${NC}"
        KEYS_FILE=""
    fi
done

sudo mkdir -p /mnt/persist/sops-nix
sudo chmod 700 /mnt/persist/sops-nix
sudo cp "$KEYS_FILE" /mnt/persist/sops-nix/
echo -e "${GREEN}Key file copied successfully${NC}"

# Files were moved to /mnt/etc/nixos above, so source the helper from there
CONFIG_FILE="/mnt/etc/nixos/configuration.nix"
source "/mnt/etc/nixos/scripts/boot-loader-helper.sh"

echo -e "${GREEN}Configuring boot loader for initial install...${NC}"
echo -e "${GREEN}Ensuring systemd-boot is active and lanzaboote is inactive...${NC}"

if ! validate_markers_exist "$CONFIG_FILE"; then
    echo "ERROR: Boot loader configuration markers not found in $CONFIG_FILE"
    echo "Expected markers:"
    echo "  - BEGIN_NIXOS_BOOT_SYSTEMD_BOOT / END_NIXOS_BOOT_SYSTEMD_BOOT"
    echo "  - BEGIN_NIXOS_BOOT_LANZABOOTE / END_NIXOS_BOOT_LANZABOOTE"
    exit 1
fi

if ! toggle_block_enable "$CONFIG_FILE" "BEGIN_NIXOS_BOOT_SYSTEMD_BOOT" "END_NIXOS_BOOT_SYSTEMD_BOOT"; then
    echo "ERROR: Failed to enable systemd-boot. Run: git restore configuration.nix"
    exit 1
fi

if ! toggle_block_disable "$CONFIG_FILE" "BEGIN_NIXOS_BOOT_LANZABOOTE" "END_NIXOS_BOOT_LANZABOOTE"; then
    echo "ERROR: Failed to disable lanzaboote. Run: git restore configuration.nix"
    exit 1
fi

if ! validate_boot_config "$CONFIG_FILE"; then
    echo "ERROR: Boot configuration validation failed. Run: git restore configuration.nix"
    exit 1
fi

ACTIVE_BOOT=$(get_active_boot_loader "$CONFIG_FILE")
if [ "$ACTIVE_BOOT" != "systemd-boot" ]; then
    echo "ERROR: Expected systemd-boot to be active, but found: $ACTIVE_BOOT. Run: git restore configuration.nix"
    exit 1
fi

echo -e "${GREEN}Boot loader configuration validated: systemd-boot is active${NC}"

# Bootstrap /persist before nixos-install, with numeric UIDs so impermanence
# activation doesn't chown against usernames that don't exist in the chroot.
echo -e "${GREEN}Bootstrapping persist directories...${NC}"

if [ ! -d /mnt/persist ]; then
    echo "ERROR: /mnt/persist does not exist. Check disko configuration."
    exit 1
fi

sudo mkdir -p /mnt/persist/home/user
sudo chown 1000:100 /mnt/persist/home/user
sudo chmod 700 /mnt/persist/home/user

# Pre-create files for impermanence bind mounts (must exist before mount)
sudo touch /mnt/persist/home/user/.zsh_history
sudo chown 1000:100 /mnt/persist/home/user/.zsh_history
sudo chmod 600 /mnt/persist/home/user/.zsh_history

sudo touch /mnt/persist/home/user/.claude.json
sudo chown 1000:100 /mnt/persist/home/user/.claude.json
sudo chmod 600 /mnt/persist/home/user/.claude.json

sudo mkdir -p /mnt/persist/root
sudo chmod 700 /mnt/persist/root

echo -e "${GREEN}Persist directories bootstrapped.${NC}"

echo -e "${GREEN}Installing NixOS...${NC}"
sudo --preserve-env=NIX_USER_CONF_FILES nixos-install --no-root-passwd --flake /mnt/etc/nixos#nixos-framework

# Copy state to /persist so impermanence can bind-mount it; only what's listed
# in environment.persistence gets mounted, extra files are ignored.
echo -e "${GREEN}Copying system state to persist...${NC}"

sudo mkdir -p /mnt/persist/etc
sudo cp -a /mnt/etc/. /mnt/persist/etc/
echo "  Copied /etc"

sudo cp -a /mnt/root/. /mnt/persist/root/
echo "  Copied /root"

sudo cp -a /mnt/home/. /mnt/persist/home/
sudo chown -R 1000:100 /mnt/persist/home/user
echo "  Copied /home"

# EasyEffects presets are copied by post-install.sh instead, for impermanence compatibility

# /var/spool is on the ephemeral root, so it needs persistence
sudo mkdir -p /mnt/persist/var/spool
if [ -d "/mnt/var/spool" ]; then
    sudo cp -a /mnt/var/spool/. /mnt/persist/var/spool/
fi
echo "  Created /var/spool"

sudo mkdir -p /mnt/persist/srv
if [ -d "/mnt/srv" ]; then
    sudo cp -a /mnt/srv/. /mnt/persist/srv/
fi
echo "  Created /srv"

# impermanence's symlinks point into /persist, so they turn circular once copied there
sudo find /mnt/persist -type l -delete
echo "  Cleaned symlinks from persist"

echo -e "${GREEN}System state copied to persist.${NC}"

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""

echo -e "${GREEN}Impermanence is configured using the official btrfs approach.${NC}"
echo "On each boot, the root subvolume will be recreated fresh."
echo "Persistent data is stored in /persist and bind-mounted by impermanence."
echo ""

while true; do
    read -rp "Do you want to reboot now? (Y/n): " choice
    choice=${choice:-y}
    case "$choice" in
        y|Y)
            echo -e "${GREEN}Rebooting system...${NC}"
            systemctl reboot
            ;;
        n|N)
            echo -e "${GREEN}Reboot cancelled. Remember to reboot manually to boot into your new system.${NC}"
            exit 0
            ;;
        *)
            echo "Please answer y or n."
            ;;
    esac
done
