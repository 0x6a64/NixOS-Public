#!/bin/bash

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes
GREEN='\033[1;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Preseed nix config to avoid trust prompts during installation
# Write to tmpdir since live ISO /etc is read-only, use NIX_USER_CONF_FILES for sudo compatibility
echo -e "${GREEN}Preseeding nix configuration...${NC}"
NIX_CONF_TMP=$(mktemp -d)/nix.conf
cat > "$NIX_CONF_TMP" << 'EOF'
experimental-features = nix-command flakes
accept-flake-config = true
warn-dirty = false
extra-substituters = https://nix-community.cachix.org https://attic.xuyh0120.win/lantian https://cache.numtide.com
extra-trusted-public-keys = nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc= niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
EOF
export NIX_USER_CONF_FILES="$NIX_CONF_TMP"
echo -e "${GREEN}Nix configuration preseeded at $NIX_CONF_TMP${NC}"

# Configure git
echo -e "${GREEN}Configuring git...${NC}"
git config --global user.name "your-username"
git config --global user.email "user@example.com"

# Check GitHub authentication status
echo -e "${GREEN}Checking GitHub authentication status...${NC}"
if ! nix-shell -p gh --run 'gh auth status' &>/dev/null; then
    echo -e "${GREEN}Not logged in. Starting authentication...${NC}"
    nix-shell -p git gh --run 'gh auth login'
else
    echo -e "${GREEN}Already authenticated with GitHub.${NC}"
fi

# Check if nixos directory already exists
# Note: $HOME in the live ISO is temporary (e.g., /home/nixos)
# This is intentional - the repo will be moved to /mnt/etc/nixos during installation
REPO_DIR="$HOME/nixos"
if [ -d "$REPO_DIR" ]; then
    echo -e "${GREEN}NixOS repository already exists at $REPO_DIR${NC}"

    # Check for available branches
    echo -e "${GREEN}Fetching latest branches...${NC}"
    cd "$REPO_DIR"
    git fetch --all

    echo -e "${GREEN}Available branches:${NC}"
    git branch -r | grep -v HEAD | sed 's/origin\///'

    echo ""
    read -p "Do you want to switch to a different branch? (y/N): " switch_branch
    switch_branch=${switch_branch:-n}

    if [[ "$switch_branch" =~ ^[yY]$ ]]; then
        read -p "Enter branch name to switch to: " branch_name
        git switch "$branch_name"
        git pull origin "$branch_name"
    else
        read -p "Do you want to remove and re-clone fresh? (y/N): " reclone
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

# Run disko to partition and format disks
echo -e "${GREEN}Running disko to partition and format disks...${NC}"
if ! sudo --preserve-env=NIX_USER_CONF_FILES nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount "$REPO_DIR/disko.nix"; then
    echo "ERROR: Disko failed to partition and format disks"
    exit 1
fi

# Display mount points and validate
echo -e "${GREEN}Current mount points:${NC}"
mount | grep /mnt || true

# Validate critical mount points exist
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

# Wait for user confirmation
echo ""
read -p "Press Enter to continue with installation or Ctrl+C to abort..."

# Generate hardware configuration
echo -e "${GREEN}Generating hardware configuration...${NC}"
sudo nixos-generate-config --no-filesystems --root /mnt

# Move hardware configuration to the repo
echo -e "${GREEN}Moving hardware configuration...${NC}"
rm -f "$REPO_DIR/hardware-configuration.nix"
sudo mv /mnt/etc/nixos/hardware-configuration.nix "$REPO_DIR/"
sudo chown "$(id -u):$(id -g)" "$REPO_DIR/hardware-configuration.nix"

echo -e "${GREEN}Moving configuration files to /mnt/etc/nixos...${NC}"
# Move all repository files (including .git) to /mnt/etc/nixos
# This empties $REPO_DIR, but that's intentional - the repo will be
# in /etc/nixos after reboot. For post-install.sh, either:
# 1. Clone repo fresh to ~/nixos and run from there, OR
# 2. Run post-install.sh directly from /etc/nixos/scripts/
# Use nullglob/dotglob for safer glob expansion
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

# Copy over key files from encrypted USB partition
echo -e "${GREEN}Copying sops age key from encrypted USB partition...${NC}"

LUKS_UUID="a31f440b-936f-4601-82b2-1ec0fef92ead"
LUKS_DEVICE="/dev/disk/by-uuid/$LUKS_UUID"
LUKS_NAME="lstorage-crypt"
MOUNT_POINT="/tmp/lstorage"

if [ ! -e "$LUKS_DEVICE" ]; then
    echo -e "${RED}Error: LUKS partition not found (UUID: $LUKS_UUID)${NC}"
    echo "Make sure your Ventoy USB with LStorage partition is plugged in."
    exit 1
fi

echo -e "${GREEN}Found encrypted partition. Enter LUKS password:${NC}"
sudo cryptsetup luksOpen "$LUKS_DEVICE" "$LUKS_NAME"

sudo mkdir -p "$MOUNT_POINT"
sudo mount "/dev/mapper/$LUKS_NAME" "$MOUNT_POINT"

if [ ! -f "$MOUNT_POINT/keys.txt" ]; then
    echo -e "${RED}Error: keys.txt not found in LStorage partition${NC}"
    sudo umount "$MOUNT_POINT"
    sudo cryptsetup luksClose "$LUKS_NAME"
    sudo rmdir "$MOUNT_POINT" 2>/dev/null || true
    exit 1
fi

sudo mkdir -p /mnt/persist/sops-nix
sudo chmod 700 /mnt/persist/sops-nix
sudo cp "$MOUNT_POINT/keys.txt" /mnt/persist/sops-nix/
echo -e "${GREEN}Key file copied successfully${NC}"

# Cleanup: unmount and close LUKS
sudo umount "$MOUNT_POINT"
sudo cryptsetup luksClose "$LUKS_NAME"
sudo rmdir "$MOUNT_POINT" 2>/dev/null || true
echo -e "${GREEN}Encrypted partition closed${NC}"

# Configure boot loader for initial install
# Note: Files have been moved to /mnt/etc/nixos, so source helper from there
CONFIG_FILE="/mnt/etc/nixos/configuration.nix"
source "/mnt/etc/nixos/scripts/boot-loader-helper.sh"

echo -e "${GREEN}Configuring boot loader for initial install...${NC}"
echo -e "${GREEN}Ensuring systemd-boot is active and lanzaboote is inactive...${NC}"

# Validate markers exist before attempting modifications
if ! validate_markers_exist "$CONFIG_FILE"; then
    echo "ERROR: Boot loader configuration markers not found in $CONFIG_FILE"
    echo "Expected markers:"
    echo "  - BEGIN_NIXOS_BOOT_SYSTEMD_BOOT / END_NIXOS_BOOT_SYSTEMD_BOOT"
    echo "  - BEGIN_NIXOS_BOOT_LANZABOOTE / END_NIXOS_BOOT_LANZABOOTE"
    exit 1
fi

# Enable systemd-boot
if ! toggle_block_enable "$CONFIG_FILE" "BEGIN_NIXOS_BOOT_SYSTEMD_BOOT" "END_NIXOS_BOOT_SYSTEMD_BOOT"; then
    echo "ERROR: Failed to enable systemd-boot. Run: git restore configuration.nix"
    exit 1
fi

# Disable lanzaboote
if ! toggle_block_disable "$CONFIG_FILE" "BEGIN_NIXOS_BOOT_LANZABOOTE" "END_NIXOS_BOOT_LANZABOOTE"; then
    echo "ERROR: Failed to disable lanzaboote. Run: git restore configuration.nix"
    exit 1
fi

# Validate final state
if ! validate_boot_config "$CONFIG_FILE"; then
    echo "ERROR: Boot configuration validation failed. Run: git restore configuration.nix"
    exit 1
fi

# Verify expected boot loader
ACTIVE_BOOT=$(get_active_boot_loader "$CONFIG_FILE")
if [ "$ACTIVE_BOOT" != "systemd-boot" ]; then
    echo "ERROR: Expected systemd-boot to be active, but found: $ACTIVE_BOOT. Run: git restore configuration.nix"
    exit 1
fi

echo -e "${GREEN}Boot loader configuration validated: systemd-boot is active${NC}"

# =============================================================================
# Bootstrap /persist directories BEFORE nixos-install
# =============================================================================
# Create base directories with numeric UIDs so impermanence activation
# doesn't fail trying to chown with usernames that don't exist in chroot.
# Note: /persist should already exist from disko mounting the persist subvolume
# =============================================================================

echo -e "${GREEN}Bootstrapping persist directories...${NC}"

# Verify /persist exists (should be mounted by disko)
if [ ! -d /mnt/persist ]; then
    echo "ERROR: /mnt/persist does not exist. Check disko configuration."
    exit 1
fi

# Base directories with correct ownership (UID:GID)
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

# Install NixOS
echo -e "${GREEN}Installing NixOS...${NC}"
sudo --preserve-env=NIX_USER_CONF_FILES nixos-install --no-root-passwd --flake /mnt/etc/nixos#nixos-framework

# =============================================================================
# Copy generated content to /persist
# =============================================================================
# After install, copy directories to /persist so impermanence can bind-mount.
# Only what's in environment.persistence gets mounted; extra files are ignored.
# =============================================================================

echo -e "${GREEN}Copying system state to persist...${NC}"

# /etc - contains machine-id, nixos config, NetworkManager connections, etc.
sudo mkdir -p /mnt/persist/etc
sudo cp -a /mnt/etc/. /mnt/persist/etc/
echo "  Copied /etc"

# /root - root user's home (directory already created in bootstrap)
sudo cp -a /mnt/root/. /mnt/persist/root/
echo "  Copied /root"

# /home - user home directories (directory already created in bootstrap)
sudo cp -a /mnt/home/. /mnt/persist/home/
sudo chown -R 1000:100 /mnt/persist/home/user
echo "  Copied /home"

# Note: EasyEffects presets are copied via post-install.sh for impermanence compatibility

# /var/spool - mail, cron, etc. (on ephemeral root, needs persistence)
sudo mkdir -p /mnt/persist/var/spool
if [ -d "/mnt/var/spool" ]; then
    sudo cp -a /mnt/var/spool/. /mnt/persist/var/spool/
fi
echo "  Created /var/spool"

# /srv - server data directory
sudo mkdir -p /mnt/persist/srv
if [ -d "/mnt/srv" ]; then
    sudo cp -a /mnt/srv/. /mnt/persist/srv/
fi
echo "  Created /srv"

# Remove ALL symlinks from persist - impermanence creates symlinks during nixos-install
# that point to /persist/..., which become circular when copied to persist itself
sudo find /mnt/persist -type l -delete
echo "  Cleaned symlinks from persist"

echo -e "${GREEN}System state copied to persist.${NC}"

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""

# =============================================================================
# Impermanence Notes
# =============================================================================
# The impermanence rollback runs via boot.initrd.systemd.services.rollback
# on COLD BOOT only (skipped during hibernation resume). It:
#
#   1. Moves existing /root to /old_roots/<timestamp>
#   2. Deletes old roots older than 30 days
#   3. Creates fresh empty root subvolume
#
# The system rebuilds itself from:
#   - /nix store (all system files)
#   - Impermanence bind mounts (persistent data from /persist)
#   - NixOS activation scripts (creates /etc, /var, etc.)
#
# Hibernation is handled via ConditionKernelCommandLine=!resume= which
# prevents the rollback service from running when resume= is present
# in the kernel command line (i.e., when resuming from hibernation).
#
# No root-blank snapshot is needed - we create a fresh subvolume each boot.
# =============================================================================

echo -e "${GREEN}Impermanence is configured using the official btrfs approach.${NC}"
echo "On each boot, the root subvolume will be recreated fresh."
echo "Persistent data is stored in /persist and bind-mounted by impermanence."
echo ""

# Prompt for reboot
while true; do
    read -p "Do you want to reboot now? (Y/n): " choice
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
