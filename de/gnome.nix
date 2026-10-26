{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.nixos-framework.desktop == "gnome") {
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    # Typelibs for copyous (see CLAUDE.md); pin libgda5, libgda6 crashes gnome-shell
    services.desktopManager.gnome.sessionPath = [pkgs.libgda5 pkgs.gsound];

    environment.systemPackages = with pkgs; [
      gnome-extension-manager
      gnome-tweaks

      # Keybinding-name collision with superbar's "toggle-shortcut" (see CLAUDE.md)
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
      # Missing late-enable branch, pending upstream PR #2493
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
      # Sync NM.Client.new() in enable() blocks gnome-shell for up to ~15s after resume
      (gnomeExtensions.updated-vlan-switcher.overrideAttrs {
        postInstall = let
          nl = lib.concatStringsSep "\n";
          file = "$out/share/gnome-shell/extensions/updated-vlan-switcher@jrvolt.github.io/extension.js";
          oldEnable = "        this.client = NM.Client.new(null);";
          newEnable = nl [
            "        this._cancellable = new Gio.Cancellable();"
            "        NM.Client.new_async(this._cancellable, (_source, res) => {"
            "            try {"
            "                this.client = NM.Client.new_finish(res);"
            "            } catch (e) {"
            "                if (!e.matches(Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED))"
            "                    logError(e, 'updated-vlan-switcher');"
            "                return;"
            "            }"
            "            this._cancellable = null;"
            "            this._enableUI();"
            "        });"
            "    }"
            ""
            "    _enableUI() {"
          ];
          oldDisable = nl [
            "    disable() {"
            "        if (this._settingsChangedId) {"
          ];
          newDisable = nl [
            "    disable() {"
            "        this._cancellable?.cancel();"
            "        this._cancellable = null;"
            "        if (this._settingsChangedId) {"
          ];
        in ''
          substituteInPlace ${file} \
            --replace-fail ${lib.escapeShellArg oldEnable} ${lib.escapeShellArg newEnable} \
            --replace-fail ${lib.escapeShellArg oldDisable} ${lib.escapeShellArg newDisable}
        '';
      })
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
