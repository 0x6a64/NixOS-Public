#!/usr/bin/env bash

# NixOS Post-Install Configuration Script
#
# This script should be run after install.sh has completed and the system has rebooted.
# It can be run from either:
#   1. A fresh clone of the repo at ~/Nixos (run: ~/Nixos/scripts/post-install.sh)
#   2. Directly from /etc/nixos (run: /etc/nixos/scripts/post-install.sh)
#
# The script will:
#   - Migrate config from /etc/nixos to ~/Nixos (copying hardware-configuration.nix)
#   - Clear /etc/nixos contents (directory kept for impermanence)
#   - Copy EasyEffects presets to /persist
#   - Clone all GitHub repositories to ~/Code (excluding nixos)
#   - Optionally configure Secure Boot with lanzaboote

set -e
set -u

GREEN='\033[1;32m'
NC='\033[0m' # No Color

REPO_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
echo -e "${GREEN}NixOS Post-Install Configuration${NC}"
echo "Repository path: $REPO_PATH"
echo ""

# Step 1: Migrate config from /etc/nixos to ~/Nixos
echo -e "${GREEN}Step 1: Migrating configuration to ~/Nixos${NC}"

TARGET_PATH="$HOME/Nixos"

# Handle running from /etc/nixos directly (fresh install)
if [ "$REPO_PATH" = "/etc/nixos" ]; then
    echo "Repository is at /etc/nixos - will copy to $TARGET_PATH"

    mkdir -p "$TARGET_PATH"

    echo -e "${GREEN}Copying /etc/nixos contents to $TARGET_PATH...${NC}"
    sudo cp -a /etc/nixos/. "$TARGET_PATH/"
    sudo chown -R "$(id -u)":"$(id -g)" "$TARGET_PATH"
    # impermanence creates absolute symlinks that break once copied
    find "$TARGET_PATH" -type l -delete

    REPO_PATH="$TARGET_PATH"

    echo -e "${GREEN}Clearing /etc/nixos contents...${NC}"
    sudo rm -rf /etc/nixos/*
    sudo rm -rf /etc/nixos/.[!.]* 2>/dev/null || true

    echo -e "${GREEN}Config migrated to $TARGET_PATH${NC}"
else
    if [ -f /etc/nixos/hardware-configuration.nix ]; then
        echo -e "${GREEN}Copying hardware-configuration.nix to $REPO_PATH...${NC}"
        sudo cp -f /etc/nixos/hardware-configuration.nix "$REPO_PATH/"
        sudo chown "$(id -u)":"$(id -g)" "$REPO_PATH/hardware-configuration.nix"

        echo -e "${GREEN}Clearing /etc/nixos contents...${NC}"
        sudo rm -rf /etc/nixos/*
        sudo rm -rf /etc/nixos/.[!.]* 2>/dev/null || true
    else
        # post-install.sh already cleared it on an earlier run; regenerate rather
        # than trusting the committed one, which may be from different hardware.
        echo -e "${GREEN}No hardware-configuration.nix in /etc/nixos - regenerating for current hardware...${NC}"
        sudo nixos-generate-config --no-filesystems --show-hardware-config | tee /tmp/hardware-configuration.nix > /dev/null

        CPU_VENDOR=$(grep -m1 "vendor_id" /proc/cpuinfo | awk '{print $3}')
        case "$CPU_VENDOR" in
            GenuineIntel) EXPECTED_KVM_MODULE="kvm-intel" ;;
            AuthenticAMD) EXPECTED_KVM_MODULE="kvm-amd" ;;
            *)
                echo "ERROR: Unrecognized CPU vendor '$CPU_VENDOR' in /proc/cpuinfo"
                rm -f /tmp/hardware-configuration.nix
                exit 1
                ;;
        esac

        if ! 'grep' -q "\"$EXPECTED_KVM_MODULE\"" /tmp/hardware-configuration.nix; then
            echo "ERROR: Regenerated config doesn't contain '$EXPECTED_KVM_MODULE' for CPU vendor '$CPU_VENDOR'"
            rm -f /tmp/hardware-configuration.nix
            exit 1
        fi

        mv /tmp/hardware-configuration.nix "$REPO_PATH/hardware-configuration.nix"
        echo -e "${GREEN}Regenerated hardware-configuration.nix for $CPU_VENDOR${NC}"
    fi
fi

echo ""

# Step 2: Copy EasyEffects presets to persist
echo -e "${GREEN}Step 2: Copying EasyEffects presets to persist${NC}"

if ! mountpoint -q /persist; then
    echo "ERROR: /persist is not mounted. Skipping EasyEffects copy."
    echo "Please ensure the system has rebooted properly after installation."
else
    if [ -d "$REPO_PATH/dots/local/share/easyeffects" ]; then
        echo "Copying EasyEffects presets from dots to /persist..."
        sudo mkdir -p /persist/home/"$USER"/.local/share/easyeffects
        sudo cp -rT "$REPO_PATH/dots/local/share/easyeffects" /persist/home/"$USER"/.local/share/easyeffects/
        sudo chown -R "$(id -u)":"$(id -g)" /persist/home/"$USER"/.local/share/easyeffects
        sudo mkdir -p /persist/home/"$USER"/.config/easyeffects/db
        sudo cp -rT "$REPO_PATH/dots/config/easyeffects/db" /persist/home/"$USER"/.config/easyeffects/db/
        sudo chown -R "$(id -u)":"$(id -g)" /persist/home/"$USER"/.config/easyeffects
        # Symlinks here would be circular once inside /persist
        sudo find /persist/home/"$USER"/.local/share/easyeffects -type l -delete 2>/dev/null || true
        sudo find /persist/home/"$USER"/.config/easyeffects -type l -delete 2>/dev/null || true
        echo -e "${GREEN}EasyEffects presets copied successfully${NC}"
    else
        echo "WARNING: EasyEffects presets not found at $REPO_PATH/dots/local/share/easyeffects"
    fi
fi

echo ""

# Step 3: Clone GitHub repositories to ~/Code
echo -e "${GREEN}Step 3: Cloning GitHub repositories to ~/Code${NC}"

GITHUB_USER="0x6a64"
CODE_DIR="$HOME/Code"
EXCLUDED_REPOS=("nixos" "Nixos" "NixOS")

read -rp "Do you want to clone all GitHub repositories to ~/Code? (Y/n): " clone_choice
clone_choice=${clone_choice:-y}

if [[ "$clone_choice" =~ ^[yY]$ ]]; then
    if ! gh auth status &>/dev/null; then
        echo "ERROR: GitHub CLI is not authenticated. Skipping repository cloning."
        echo "Please ensure GitHub authentication is working and re-run this step."
    else
        mkdir -p "$CODE_DIR"

        echo "Fetching repository list from GitHub..."
        repos=$(gh repo list "$GITHUB_USER" --limit 1000 --json name,isArchived --jq '.[] | select(.isArchived == false) | .name')

        if [ -z "$repos" ]; then
            echo "No repositories found for user $GITHUB_USER"
        else
            cloned_count=0
            skipped_count=0

            while IFS= read -r repo; do
                excluded=false
                for excluded_repo in "${EXCLUDED_REPOS[@]}"; do
                    if [[ "$repo" == "$excluded_repo" ]]; then
                        excluded=true
                        break
                    fi
                done

                if [ "$excluded" = true ]; then
                    echo "Skipping excluded repository: $repo"
                    ((++skipped_count))
                    continue
                fi

                if [ -d "$CODE_DIR/$repo" ]; then
                    echo "Repository already exists: $CODE_DIR/$repo (skipping)"
                    ((++skipped_count))
                    continue
                fi

                echo "Cloning $repo..."
                if gh repo clone "$GITHUB_USER/$repo" "$CODE_DIR/$repo" 2>&1; then
                    ((++cloned_count))
                else
                    echo "WARNING: Failed to clone $repo"
                fi
            done <<< "$repos"

            echo -e "${GREEN}Repository cloning complete: $cloned_count cloned, $skipped_count skipped${NC}"
        fi
    fi
else
    echo "Skipping repository cloning"
fi

echo ""

# Step 4: Set up Secure Boot
echo -e "${GREEN}Step 4: Setting up Secure Boot${NC}"
read -rp "Do you want to set up Secure Boot? (Y/n): " secureboot_choice
secureboot_choice=${secureboot_choice:-y}

if [[ "$secureboot_choice" =~ ^[yY]$ ]]; then
    source "$REPO_PATH/scripts/boot-loader-helper.sh"

    # Keys must exist before lanzaboote can be enabled
    echo ""
    echo -e "${GREEN}Creating Secure Boot signing keys...${NC}"
    if [ ! -d /var/lib/sbctl ]; then
        sudo sbctl create-keys
        echo -e "${GREEN}Keys created successfully${NC}"
    else
        echo "Keys already exist at /var/lib/sbctl"
    fi

    echo ""
    echo -e "${GREEN}Configuring boot loader for Secure Boot...${NC}"
    echo -e "${GREEN}Switching from systemd-boot to lanzaboote...${NC}"

    CONFIG_FILE="$REPO_PATH/configuration.nix"

    if ! validate_markers_exist "$CONFIG_FILE"; then
        echo "ERROR: Boot loader configuration markers not found"
        exit 1
    fi

    if ! toggle_block_disable "$CONFIG_FILE" "BEGIN_NIXOS_BOOT_SYSTEMD_BOOT" "END_NIXOS_BOOT_SYSTEMD_BOOT"; then
        echo "ERROR: Failed to disable systemd-boot. Run: git restore configuration.nix"
        exit 1
    fi

    if ! toggle_block_enable "$CONFIG_FILE" "BEGIN_NIXOS_BOOT_LANZABOOTE" "END_NIXOS_BOOT_LANZABOOTE"; then
        echo "ERROR: Failed to enable lanzaboote. Run: git restore configuration.nix"
        exit 1
    fi

    if ! validate_boot_config "$CONFIG_FILE"; then
        echo "ERROR: Boot configuration validation failed. Run: git restore configuration.nix"
        exit 1
    fi

    ACTIVE_BOOT=$(get_active_boot_loader "$CONFIG_FILE")
    if [ "$ACTIVE_BOOT" != "lanzaboote" ]; then
        echo "ERROR: Expected lanzaboote to be active, but found: $ACTIVE_BOOT. Run: git restore configuration.nix"
        exit 1
    fi

    echo -e "${GREEN}Boot loader configuration validated: lanzaboote is active${NC}"

    # boot rather than switch, to avoid impermanence conflicts
    echo ""
    echo -e "${GREEN}Rebuilding the system...${NC}"
    sudo nixos-rebuild boot --flake "$REPO_PATH" --option warn-dirty false 

    echo ""
    echo -e "${GREEN}System rebuild complete (changes will take effect after reboot)${NC}"

    # Step 5: Enroll Secure Boot keys
    echo ""
    echo -e "${GREEN}Step 5: Enrolling Secure Boot keys${NC}"

    if ! command -v sbctl &> /dev/null; then
        echo "ERROR: sbctl command not found. Please ensure lanzaboote is properly configured."
        exit 1
    fi

    echo -e "${GREEN}Checking Secure Boot status...${NC}"
    echo ""

    # sbctl status exits non-zero when secure boot is off
    set +e
    sbctl_output=$(sudo sbctl status 2>&1)
    set -e

    echo "$sbctl_output"
    echo ""

    if echo "$sbctl_output" | grep -qi "Setup Mode.*Enabled\|Setup Mode.*true"; then
        echo -e "${GREEN}Setup Mode is enabled - ready to enroll keys${NC}"
        setup_mode_enabled=true
    elif echo "$sbctl_output" | grep -qi "Setup Mode.*Disabled\|Setup Mode.*false"; then
        echo "ERROR: Setup Mode is not enabled. Please enable it in your BIOS/UEFI settings."
        echo "Typically this is done by clearing/deleting existing Secure Boot keys."
        read -rp "Continue anyway? (y/N): " force_continue
        force_continue=${force_continue:-n}
        if [[ ! "$force_continue" =~ ^[yY]$ ]]; then
            exit 1
        fi
        setup_mode_enabled=true
    else
        echo -e "${GREEN}Could not automatically determine Setup Mode status${NC}"
        echo "Setup Mode must be enabled in your BIOS/UEFI to enroll keys."
        echo ""
        read -rp "Is Setup Mode enabled? (Y/n): " setup_mode_check
        setup_mode_check=${setup_mode_check:-y}

        if [[ ! "$setup_mode_check" =~ ^[yY]$ ]]; then
            echo "ERROR: Setup Mode is not enabled. Please enable it in your BIOS/UEFI settings."
            echo "Typically this is done by clearing/deleting existing Secure Boot keys."
            exit 1
        fi
        setup_mode_enabled=true
    fi

    if [ "$setup_mode_enabled" = true ]; then
        echo ""
        read -rp "Ready to enroll Secure Boot keys? (Y/n): " enroll_choice
        enroll_choice=${enroll_choice:-y}

        if [[ "$enroll_choice" =~ ^[yY]$ ]]; then
            echo ""
            echo "NOTE: This will enroll keys with the -f (force) flag, which will"
            echo "overwrite any existing keys. If you've already enrolled keys, this"
            echo "may not be what you want."
            read -rp "Continue with key enrollment? (Y/n): " confirm_enroll
            confirm_enroll=${confirm_enroll:-y}

            if [[ "$confirm_enroll" =~ ^[yY]$ ]]; then
                echo -e "${GREEN}Enrolling keys...${NC}"
                sudo sbctl enroll-keys -m -f

                echo ""
                echo -e "${GREEN}Secure Boot keys enrolled successfully${NC}"
                echo -e "${GREEN}Remember to enable Secure Boot in your BIOS/UEFI settings${NC}"
            else
                echo "Skipping key enrollment"
            fi
        else
            echo "Skipping key enrollment"
            echo "You can manually enroll keys later with: sudo sbctl enroll-keys -m -f"
        fi
    fi
else
    echo "Skipping Secure Boot setup"
fi

echo ""
echo -e "${GREEN}Post-install configuration complete!${NC}"
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
            echo -e "${GREEN}Reboot cancelled. Remember to reboot manually for changes to take effect.${NC}"
            exit 0
            ;;
        *)
            echo "Please answer y or n."
            ;;
    esac
done
