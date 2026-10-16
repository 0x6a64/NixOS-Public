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

      # Caffeine and superbar both register the mutter keybinding name
      # "toggle-shortcut"; mutter keys its table on that name process-wide, so
      # whichever enables second never binds. Rename caffeine's — its shortcut
      # is unset here, and enable order can't arbitrate this (see CLAUDE.md).
      (gnomeExtensions.caffeine.overrideAttrs {
        postPatch = ''
          substituteInPlace extension.js \
            --replace-fail "const TOGGLE_SHORTCUT = 'toggle-shortcut';" "const TOGGLE_SHORTCUT = 'caffeine-toggle-shortcut';"
          substituteInPlace prefs.js \
            --replace-fail "TOGGLE_SHORTCUT: 'toggle-shortcut'," "TOGGLE_SHORTCUT: 'caffeine-toggle-shortcut',"
          substituteInPlace schemas/org.gnome.shell.extensions.caffeine.gschema.xml \
            --replace-fail '<key type="as" name="toggle-shortcut">' '<key type="as" name="caffeine-toggle-shortcut">'
        '';
      })
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
      # v74 hides the overview on `startup-complete` but only when enabled during
      # `_startingUp`; add the missing late-enable branch from pending PR #2493.
      (gnomeExtensions.dash-to-panel.overrideAttrs {
        postInstall = let
          nl = lib.concatStringsSep "\n";
          old = nl [
            "          if (Config.PACKAGE_VERSION >= '50') Main.overview.hide()"
            "        },"
            "      )"
            "    }"
          ];
          new = nl [
            "          if (Config.PACKAGE_VERSION >= '50') Main.overview.hide()"
            "        },"
            "      )"
            "    } else if (SETTINGS.get_boolean('hide-overview-on-startup')) {"
            "      Main.overview.hide()"
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
      (pkgs.callPackage ../packages/package-superbar.nix {colors = config.lib.stylix.colors;})
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
