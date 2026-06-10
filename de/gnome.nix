#GNOME Config
{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.gearhead.desktop == "gnome") {
    #Activates GNOME
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;

    # Gnome Extensions
    environment.systemPackages = with pkgs; [
      gnome-extension-manager
      gnome-tweaks

      # GNOME Extensions
      gnomeExtensions.caffeine
      gnomeExtensions.gsconnect
      gnomeExtensions.blur-my-shell
      gnomeExtensions.appindicator
      gnomeExtensions.burn-my-windows
      gnomeExtensions.tiling-shell
      gnomeExtensions.random-wallpaper
      gnomeExtensions.alphabetical-app-grid
      gnomeExtensions.color-picker
      gnomeExtensions.weather-oclock
      gnomeExtensions.pip-on-top
      gnomeExtensions.dash-to-panel
      gnomeExtensions.vlan-controller
      gnomeExtensions.user-themes
      gnomeExtensions.lilypad
      gnomeExtensions.brightness-control-using-ddcutil
      (pkgs.callPackage ../packages/package-copyous.nix {})
    ];

    # Excluded GNOME Default Apps
    environment.gnome.excludePackages = with pkgs; [
      gnome-terminal
      gnome-tour
      gnome-clocks
      yelp
      gnome-maps
      simple-scan
      gnome-contacts
      geary
      epiphany
      gnome-music
      gnome-console
      gnome-software
      papers
    ];

    services.gnome.gnome-browser-connector.enable = true;
  };
}
