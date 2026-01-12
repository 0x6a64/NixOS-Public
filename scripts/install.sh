#!/bin/bash

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes
GREEN='\033[1;32m'
NC='\033[0m' # No Color

# Enable Nix experimental features
export NIX_CONFIG='experimental-features = nix-command flakes'

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
            git clone https://github.com/fransole/NixOS-Public.git "$REPO_DIR"
        else
            echo -e "${GREEN}Using existing repository.${NC}"
        fi
    fi
else
    echo -e "${GREEN}Cloning nixos repository...${NC}"
    git clone https://github.com/fransole/NixOS-Public.git "$REPO_DIR"
fi

# Run disko to partition and format disks
echo -e "${GREEN}Running disko to partition and format disks...${NC}"
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount "$REPO_DIR/disko.nix"

# Display mount points
echo -e "${GREEN}Current mount points:${NC}"
mount | grep /mnt

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

echo -e "${GREEN}Moving configuration files to /mnt/etc/nixos...${NC}"
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

# Copy over key files
echo -e "${GREEN}Copying over key file from USB${NC}"
sudo mkdir -p /mnt/persist/sops-nix
sudo cp /run/media/nixos/miscstorage/keys.txt /mnt/persist/sops-nix/

# Configure boot loader for initial install
echo -e "${GREEN}Configuring boot loader for initial install...${NC}"
echo -e "${GREEN}Uncommenting systemd-boot and commenting out lanzaboote...${NC}"

# Uncomment systemd-boot block
sudo sed -i '/^  # boot\.loader\.systemd-boot = {$/,/^  # };$/ s/^  # /  /' /mnt/etc/nixos/configuration.nix

# Comment out lanzaboote configuration
sudo sed -i '/^  # Secure Boot with Lanzaboote$/,/^  };$/ {
  /^  # Secure Boot with Lanzaboote$/!s/^  /  # /
}' /mnt/etc/nixos/configuration.nix

# =============================================================================
# Bootstrap /persist directories BEFORE nixos-install
# =============================================================================
# Create base directories with numeric UIDs so impermanence activation
# doesn't fail trying to chown with usernames that don't exist in chroot.
# =============================================================================

echo -e "${GREEN}Bootstrapping persist directories...${NC}"

# Base directories with correct ownership (UID:GID)
sudo mkdir -p /mnt/persist/home/user
sudo chown 1000:100 /mnt/persist/home/user
sudo chmod 700 /mnt/persist/home/user

sudo mkdir -p /mnt/persist/root
sudo chmod 700 /mnt/persist/root

echo -e "${GREEN}Persist directories bootstrapped.${NC}"

# Install NixOS
echo -e "${GREEN}Installing NixOS...${NC}"
sudo nixos-install --no-root-passwd --flake /mnt/etc/nixos#nixos-framework

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
