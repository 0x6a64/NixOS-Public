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

    services.system76-scheduler = {
      enable = true;
      useStockConfig = true;
    };

    # Still to do when actually switching to COSMIC: disable the gnome and
    # gnome-text-editor stylix targets, and set
    # "widget.gtk.libadwaita-colors.enabled" = false in firefox.nix.
    # (xdg portals and Xwayland are already handled by the nixpkgs module;
    # Observatory's monitord needs the nixos-cosmic flake.)
  };
}
