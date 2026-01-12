#GNOME Config
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf (config.desktopEnvironment.active == "gnome") {
    # Activates GNOME
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
    # gnomeExtensions.dash-to-dock
    # gnomeExtensions.arcmenu
    gnomeExtensions.caffeine
    gnomeExtensions.gsconnect
    # gnomeExtensions.veil
    gnomeExtensions.blur-my-shell
    # gnomeExtensions.clipboard-indicator
    gnomeExtensions.appindicator
    gnomeExtensions.burn-my-windows
    # gnomeExtensions.compiz-windows-effect
    gnomeExtensions.tiling-shell
    # gnomeExtensions.open-bar
    gnomeExtensions.random-wallpaper
    gnomeExtensions.alphabetical-app-grid
    gnomeExtensions.color-picker
    gnomeExtensions.weather-oclock
    gnomeExtensions.pip-on-top
    gnomeExtensions.dash-to-panel
    gnomeExtensions.vlan-controller
    gnomeExtensions.rounded-window-corners-reborn
    # gnomeExtensions.snowy
    gnomeExtensions.custom-hot-corners-extended
    gnomeExtensions.user-themes
    gnomeExtensions.lilypad
    gnomeExtensions.brightness-control-using-ddcutil
    gnomeExtensions.easyeffects-preset-selector
    # gnomeExtensions.copyous - wish this existed
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
      papers
    ];

    # Enable GNOME browser connector for browser extensions
    # Note: Browser GNOME extension flags are set in de-selector.nix
    services.gnome.gnome-browser-connector.enable = true;
  };
}
