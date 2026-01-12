# COSMIC Desktop Environment Configuration
# System76's COSMIC DE - written in Rust using iced toolkit
#
# Requirements:
# - NixOS 25.05+ (COSMIC modules added in this release)
# - Or use nixos-cosmic flake for development versions
#
# Documentation: https://wiki.nixos.org/wiki/COSMIC
# Development: https://github.com/lilyinstarlight/nixos-cosmic
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  config = mkIf (config.desktopEnvironment.active == "cosmic") {
    # Enable COSMIC Display Manager (greeter/login screen)
    services.displayManager.cosmic-greeter.enable = true;

    # Enable COSMIC Desktop Environment
    services.desktopManager.cosmic.enable = true;

    # Workaround for COSMIC autologin (similar to GNOME)
    # Comment these out if you want to see the login screen
    # systemd.services."getty@tty1".enable = false;
    # systemd.services."autovt@tty1".enable = false;

    # Session variables for COSMIC
    environment.sessionVariables = {
      # Enable clipboard data control (required for clipboard functionality)
      COSMIC_DATA_CONTROL_ENABLED = "1";
    };

    # XDG portal configuration
    # COSMIC uses its own portal alongside GTK for compatibility
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-cosmic
        xdg-desktop-portal-gtk # For GTK app compatibility
      ];
    };

    # Performance optimization: System76 scheduler
    # Improves desktop responsiveness by prioritizing foreground tasks
    services.system76-scheduler = {
      enable = true;
      useStockConfig = true;
    };

    # Enable monitord for COSMIC Observatory (system monitoring app)
    systemd.services.monitord.wantedBy = lib.mkDefault ["multi-user.target"];

    # Environment packages for COSMIC
    environment.systemPackages = with pkgs; [
      # COSMIC apps are bundled with the desktop
      # These are just useful additions
      wl-clipboard # Wayland clipboard utilities
    ];
  };

  # ============================================
  # Notes for COSMIC configuration
  # ============================================
  #
  # The DE selector automatically handles basic setup.
  # Additional configuration needed:
  #
  # 1. In stylix.nix, disable GNOME targets:
  #    stylix.targets.gnome.enable = false;
  #    stylix.targets.gnome-text-editor.enable = false;
  #
  # 2. For Firefox theming, add to firefox.nix settings:
  #    "widget.gtk.libadwaita-colors.enabled" = false;
  #
  # 3. Nvidia users with phantom display issues:
  #    boot.kernelParams = [ "nvidia_drm.fbdev=1" ];

  # ============================================
  # Using nixos-cosmic flake (for development/latest)
  # ============================================
  #
  # If you want the latest COSMIC builds before they're in nixpkgs:
  #
  # 1. Add to flake.nix inputs:
  #    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
  #
  # 2. Add binary cache for faster builds (in flake.nix):
  #    nixConfig = {
  #      extra-substituters = [ "https://cosmic.cachix.org/" ];
  #      extra-trusted-public-keys = [
  #        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
  #      ];
  #    };
  #
  # 3. Add the module to configuration.nix imports:
  #    inputs.nixos-cosmic.nixosModules.default
}
