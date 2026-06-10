{
  config,
  lib,
  ...
}: {
  config = lib.mkIf (config.gearhead.desktop == "cosmic") {
    services.displayManager.cosmic-greeter.enable = true;
    services.desktopManager.cosmic.enable = true;

    # Workaround for COSMIC autologin (similar to GNOME)
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;

    environment.sessionVariables = {
      # Enable clipboard data control (required for clipboard managers)
      COSMIC_DATA_CONTROL_ENABLED = "1";
    };

    # Performance optimization: System76 scheduler
    services.system76-scheduler = {
      enable = true;
      useStockConfig = true;
    };

    # ============================================
    # Notes for COSMIC configuration
    # ============================================
    #
    # The nixpkgs cosmic module already configures xdg portals (cosmic + gtk)
    # and Xwayland (services.desktopManager.cosmic.xwayland.enable, default on).
    # COSMIC Observatory's monitord daemon is not packaged in nixpkgs; use the
    # nixos-cosmic flake if full Observatory monitoring is wanted.
    #
    # Additional configuration needed when switching to COSMIC:
    #
    # 1. In stylix.nix, disable GNOME targets:
    #    stylix.targets.gnome.enable = false;
    #    stylix.targets.gnome-text-editor.enable = false;
    #
    # 2. For Firefox theming, add to firefox.nix settings:
    #    "widget.gtk.libadwaita-colors.enabled" = false;
  };
}
