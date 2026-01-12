#!/bin/bash

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes
GREEN='\033[1;32m'
NC='\033[0m' # No Color

# Determine the repository path
REPO_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo -e "${GREEN}NixOS Post-Install Configuration${NC}"
echo "Repository path: $REPO_PATH"
echo ""

# Step 1: Delete everything in /etc/nixos and symlink it to the home dir
echo -e "${GREEN}Step 1: Setting up /etc/nixos symlink${NC}"

# Check if symlink already exists and is correct
if [ -L "/etc/nixos" ] && [ "$(readlink -f /etc/nixos)" = "$REPO_PATH" ]; then
    echo "/etc/nixos is already correctly symlinked to $REPO_PATH"
    echo "Skipping symlink creation"
else
    echo "This will delete everything in /etc/nixos and symlink it to $REPO_PATH"
    read -p "Do you want to proceed? (Y/n): " symlink_choice
    symlink_choice=${symlink_choice:-y}

    if [[ "$symlink_choice" =~ ^[yY]$ ]]; then
        # Copy hardware-configuration.nix before removing /etc/nixos
        if [ -f /etc/nixos/hardware-configuration.nix ]; then
            echo -e "${GREEN}Copying hardware-configuration.nix to repository...${NC}"
            sudo cp /etc/nixos/hardware-configuration.nix "$REPO_PATH/"
            sudo chown $USER:$USER "$REPO_PATH/hardware-configuration.nix"
        else
            echo "WARNING: No hardware-configuration.nix found in /etc/nixos"
        fi

        echo -e "${GREEN}Removing existing /etc/nixos...${NC}"
        sudo rm -rf /etc/nixos

        echo -e "${GREEN}Creating symlink to $REPO_PATH...${NC}"
        sudo ln -s "$REPO_PATH" /etc/nixos

        # Verify symlink was created correctly
        if [ -L "/etc/nixos" ] && [ "$(readlink -f /etc/nixos)" = "$REPO_PATH" ]; then
            echo -e "${GREEN}Symlink created successfully${NC}"
        else
            echo "ERROR: Failed to create symlink correctly"
            exit 1
        fi
    else
        echo "Skipping symlink creation"
    fi
fi

echo ""

# Step 2: Copy EasyEffects presets to persist
echo -e "${GREEN}Step 2: Copying EasyEffects presets to persist${NC}"

# EasyEffects presets must be in /persist for impermanence
if [ -d "$REPO_PATH/dots/local/share/easyeffects" ]; then
    echo "Copying EasyEffects presets from dots to /persist..."
    sudo mkdir -p /persist/home/$USER/.local/share/easyeffects
    sudo cp -r "$REPO_PATH/dots/local/share/easyeffects/"* /persist/home/$USER/.local/share/easyeffects/
    sudo chown -R $(id -u):$(id -g) /persist/home/$USER/.local/share/easyeffects
    echo -e "${GREEN}EasyEffects presets copied successfully${NC}"
else
    echo "WARNING: EasyEffects presets not found at $REPO_PATH/dots/local/share/easyeffects"
fi

echo ""

# Step 3: Verify GitHub Authentication
echo -e "${GREEN}Step 3: Verifying GitHub Authentication${NC}"

# Check if github-token secret is accessible
if [ -f /run/secrets/github-token ]; then
    echo -e "${GREEN}GitHub token secret found at /run/secrets/github-token${NC}"

    # Ensure the systemd service has injected the token into the environment
    echo -e "${GREEN}Starting inject-github-token service...${NC}"
    systemctl --user start inject-github-token.service 2>/dev/null || true

    # Reload systemd user environment to pick up the new variable
    systemctl --user import-environment GH_TOKEN 2>/dev/null || true

    # Check GitHub authentication status
    echo -e "${GREEN}Verifying GitHub CLI authentication...${NC}"
    if gh auth status &>/dev/null; then
        echo -e "${GREEN}GitHub authentication successful (using GH_TOKEN)${NC}"
    else
        echo "WARNING: GitHub authentication check failed"
        echo "The GH_TOKEN environment variable will be available after your next login"
        echo "Or you can manually run: systemctl --user start inject-github-token.service"
    fi
else
    echo "ERROR: GitHub token secret not found at /run/secrets/github-token"
    echo "Please ensure sops-nix secrets are properly configured and the system has been rebuilt."
fi

echo ""

# Step 4: Set up Secure Boot
echo -e "${GREEN}Step 4: Setting up Secure Boot${NC}"
read -p "Do you want to set up Secure Boot? (Y/n): " secureboot_choice
secureboot_choice=${secureboot_choice:-y}

if [[ "$secureboot_choice" =~ ^[yY]$ ]]; then
    echo ""
    echo -e "${GREEN}Configuring boot loader for Secure Boot...${NC}"
    echo -e "${GREEN}Commenting out systemd-boot and uncommenting lanzaboote...${NC}"

    # Comment out systemd-boot block
    sed -i '/^  boot\.loader\.systemd-boot = {$/,/^  };$/ s/^  /  # /' "$REPO_PATH/configuration.nix"

    # Uncomment lanzaboote configuration
    sed -i '/^  # Secure Boot with Lanzaboote$/,/^  # };$/ {
      /^  # Secure Boot with Lanzaboote$/!s/^  # /  /
    }' "$REPO_PATH/configuration.nix"

    echo -e "${GREEN}Boot loader configuration updated${NC}"

    # Rebuild the system
    echo ""
    echo -e "${GREEN}Rebuilding the system...${NC}"
    sudo nixos-rebuild switch

    echo ""
    echo -e "${GREEN}System rebuild complete${NC}"

    # Step 5: Enroll Secure Boot keys
    echo ""
    echo -e "${GREEN}Step 5: Enrolling Secure Boot keys${NC}"

    # Check if sbctl is available
    if ! command -v sbctl &> /dev/null; then
        echo "ERROR: sbctl command not found. Please ensure lanzaboote is properly configured."
        exit 1
    fi

    # Check Secure Boot status
    echo -e "${GREEN}Checking Secure Boot status...${NC}"
    echo ""

    # Temporarily disable exit on error for sbctl status
    set +e
    sbctl_output=$(sudo sbctl status 2>&1)
    sbctl_exit=$?
    set -e

    echo "$sbctl_output"
    echo ""

    # Try to parse Setup Mode from output
    if echo "$sbctl_output" | grep -qi "Setup Mode.*Enabled\|Setup Mode.*true"; then
        echo -e "${GREEN}Setup Mode is enabled - ready to enroll keys${NC}"
        setup_mode_enabled=true
    elif echo "$sbctl_output" | grep -qi "Setup Mode.*Disabled\|Setup Mode.*false"; then
        echo "ERROR: Setup Mode is not enabled. Please enable it in your BIOS/UEFI settings."
        echo "Typically this is done by clearing/deleting existing Secure Boot keys."
        read -p "Continue anyway? (y/N): " force_continue
        force_continue=${force_continue:-n}
        if [[ ! "$force_continue" =~ ^[yY]$ ]]; then
            exit 1
        fi
        setup_mode_enabled=true
    else
        echo -e "${GREEN}Could not automatically determine Setup Mode status${NC}"
        echo "Setup Mode must be enabled in your BIOS/UEFI to enroll keys."
        echo ""
        read -p "Is Setup Mode enabled? (Y/n): " setup_mode_check
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
        read -p "Ready to enroll Secure Boot keys? (Y/n): " enroll_choice
        enroll_choice=${enroll_choice:-y}

        if [[ "$enroll_choice" =~ ^[yY]$ ]]; then
            echo -e "${GREEN}Enrolling keys...${NC}"
            sudo sbctl enroll-keys -m -f

            echo ""
            echo -e "${GREEN}Secure Boot keys enrolled successfully${NC}"
            echo -e "${GREEN}Remember to enable Secure Boot in your BIOS/UEFI settings${NC}"
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
            echo -e "${GREEN}Reboot cancelled. Remember to reboot manually for changes to take effect.${NC}"
            exit 0
            ;;
        *)
            echo "Please answer y or n."
            ;;
    esac
done
