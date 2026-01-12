# Desktop Environment Selector Module
# Provides a simple interface to select which desktop environment to use
#
# Usage in configuration.nix:
#   desktopEnvironment.active = "gnome"; # or "plasma", "cosmic"
#
# This module automatically:
# - Enables the selected DE configuration
# - Enables appropriate browser extensions
# - Sets up DE-specific home-manager imports
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.desktopEnvironment;
in {
  options.desktopEnvironment = {
    active = mkOption {
      type = types.enum ["gnome" "plasma" "cosmic" "none"];
      default = "gnome";
      description = ''
        Which desktop environment to use.
        Options: "gnome", "plasma", "cosmic", "none"

        GNOME: Modern GTK-based desktop
        Plasma: KDE's feature-rich Qt-based desktop
        COSMIC: System76's Rust-based desktop (requires NixOS 25.05+)
        none: Disable DE selector (use manual imports)
      '';
    };
  };

  # Always import all DE modules - they self-disable if not selected
  imports = [
    ./de/gnome.nix
    ./de/kde.nix
    ./de/cosmic.nix
  ];

  config = mkIf (cfg.active != "none") {
    # Browser GNOME extension support
    nixpkgs.config.firefox.enableGnomeExtensions = mkIf (cfg.active == "gnome") true;
    nixpkgs.config.zen-browser.enableGnomeExtensions = mkIf (cfg.active == "gnome") true;

    # Make the DE selection available to home-manager via specialArgs
    home-manager.extraSpecialArgs = {
      activeDesktopEnvironment = cfg.active;
    };

    # Informational warnings for Plasma and COSMIC
    warnings =
      (optional (cfg.active == "plasma")
        ''
          Desktop Environment: KDE Plasma selected
          The selector automatically imports de/plasma.nix in home-manager.
          Additional manual steps may be needed:
          - Enable plasma-manager in flake.nix inputs (if using HM theming)
        '')
      ++ (optional (cfg.active == "cosmic")
        ''
          Desktop Environment: COSMIC selected
          Note: Consider disabling GNOME-specific Stylix targets in stylix.nix
          Optional: Add nixos-cosmic flake input for latest COSMIC builds
        '');
  };
}
