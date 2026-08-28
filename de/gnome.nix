{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.gearhead.desktop == "gnome") {
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    # Copyous imports gi://Gda and gi://GSound, and gnome-shell's own wrapper puts
    # neither typelib on GI_TYPELIB_PATH. sessionPath appends them for the GNOME
    # session; pin libgda5, libgda6 crashes gnome-shell.
    services.desktopManager.gnome.sessionPath = [pkgs.libgda5 pkgs.gsound];

    # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;

    environment.systemPackages = with pkgs; [
      gnome-extension-manager
      gnome-tweaks

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
      # GNOME 50 enables extensions after the startup animation has already
      # finished, so upstream's `_startingUp` gate leaves hide-overview-on-startup
      # doing nothing. Mirrors the pending upstream fix, dash-to-panel PR #2493.
      (gnomeExtensions.dash-to-panel.overrideAttrs {
        postInstall = let
          nl = lib.concatStringsSep "\n";
          old = nl [
            "    if ("
            "      SETTINGS.get_boolean('hide-overview-on-startup') &&"
            "      Main.layoutManager._startingUp"
            "    ) {"
            "      Main.sessionMode.hasOverview = false"
            "      startupCompleteHandler = Main.layoutManager.connect("
            "        'startup-complete',"
            "        () => (Main.sessionMode.hasOverview = this._realHasOverview),"
            "      )"
            "    }"
          ];
          new = nl [
            "    if (SETTINGS.get_boolean('hide-overview-on-startup')) {"
            "      if (Main.layoutManager._startingUp) {"
            "        Main.sessionMode.hasOverview = false"
            "        startupCompleteHandler = Main.layoutManager.connect("
            "          'startup-complete',"
            "          () => {"
            "            Main.sessionMode.hasOverview = this._realHasOverview"
            "            Main.overview.hide()"
            "          },"
            "        )"
            "      } else {"
            "        Main.overview.hide()"
            "      }"
            "    }"
          ];
        in ''
          substituteInPlace $out/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/extension.js \
            --replace-fail ${lib.escapeShellArg old} ${lib.escapeShellArg new}
        '';
      })
      gnomeExtensions.updated-vlan-switcher
      gnomeExtensions.user-themes
      gnomeExtensions.lilypad
      gnomeExtensions.brightness-control-using-ddcutil
      (pkgs.callPackage ../packages/package-copyous.nix {})
    ];

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

    # Nautilus audio/video Properties tab needs GStreamer plugins on PATH
    # https://github.com/NixOS/nixpkgs/issues/195936 (re-login required)
    environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
      gst-plugins-good
      gst-plugins-bad
      gst-plugins-ugly
      gst-libav
    ]);
  };
}
