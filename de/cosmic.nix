{
  config,
  lib,
  ...
}: {
  config = lib.mkIf (config.nixos-framework.desktop == "cosmic") {
    services.displayManager.cosmic-greeter.enable = true;
    services.desktopManager.cosmic.enable = true;

    # Workaround for COSMIC autologin (similar to GNOME)
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;

    environment.sessionVariables = {
      # Required for clipboard managers
      COSMIC_DATA_CONTROL_ENABLED = "1";
    };

    services.system76-scheduler = {
      enable = true;
      useStockConfig = true;
    };

    # TODO on switch: disable gnome and gnome-text-editor stylix targets, set "widget.gtk.libadwaita-colors.enabled" = false in firefox.nix
  };
}
