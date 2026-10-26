# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib.hm.gvariant; {
  dconf.settings = {
    "org/gnome/mutter" = {
      edge-tiling = false; # conflicts with Tiling Shell
    };
    "org/gnome/settings-daemon/plugins/housekeeping" = {
      "donation-reminder-enabled" = false;
    };
    # Explicit directories, NOT "$HOME": a $HOME crawl walks the rclone Drive mounts (see CLAUDE.md "File indexing")
    "org/freedesktop/tracker/miner/files" = {
      index-recursive-directories = [
        "&DESKTOP"
        "&DOCUMENTS"
        "&DOWNLOAD"
        "&MUSIC"
        "&PICTURES"
        "&PUBLIC_SHARE"
        "&TEMPLATES"
        "&VIDEOS"
        "${config.home.homeDirectory}/Code"
        "${config.home.homeDirectory}/Nixos"
        "${config.home.homeDirectory}/Projects"
      ];
      # Schema default also excludes ".git" (every repo); keep the markers so a repo can opt out
      ignored-directories-with-content = [".trackerignore" ".nomedia"];
      # Basename-only matching (no absolute paths), so keep this narrow; ploopy-qmk is vendored filename noise
      ignored-directories = [
        "po"
        "CVS"
        "core-dumps"
        "lost+found"
        ".Trash-1000"
        ".pnpm-store"
        "node_modules"
        ".direnv"
        ".venv"
        "__pycache__"
        "dist"
        "ploopy-qmk"
      ];
    };
    "org/gnome/desktop/sound" = {
      theme-name = "modern-minimal-ui-sounds-v1.1";
      event-sounds = true;
    };
    "org/gnome/shell" = {
      disable-extension-version-validation = true;
      favorite-apps = [
        "firefox.desktop"
        "org.gnome.Ptyxis.desktop"
        "org.gnome.Nautilus.desktop"
      ];
      disabled-extensions = [];
      enabled-extensions = [
        # Keep dash-to-panel first: it must enable before startup-complete (see CLAUDE.md)
        "dash-to-panel@jderose9.github.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "AlphabeticalAppGrid@stuarthayhurst"
        "appindicatorsupport@rgcjonas.gmail.com"
        "blur-my-shell@aunetx"
        "display-brightness-ddcutil@themightydeity.github.com"
        "burn-my-windows@schneegans.github.com"
        "caffeine@patapon.info"
        "color-picker@tuberry"
        "copyous@boerdereinar.dev"
        "gsconnect@andyholmes.github.io"
        "lilypad@shendrew.github.io"
        "pip-on-top@rafostar.github.com"
        "randomwallpaper@iflow.space"
        "superbar@Furkan-rgb.github.io"
        "tilingshell@ferrarodomenico.com"
        "updated-vlan-switcher@jrvolt.github.io"
        "weatheroclock@CleoMenezesJr.github.io"
      ];
    };
    "org/gnome/desktop/app-folders" = {
      folder-children = ["System" "Utilities" "LibreOffice"];
    };
    "org/gnome/desktop/app-folders/folders/System" = {
      name = "X-GNOME-Shell-System.directory";
      translate = true;
      apps = [
        "org.gnome.baobab.desktop"
        "org.gnome.DiskUtility.desktop"
        "ca.desrt.dconf-editor.desktop"
        "com.mattjakeman.ExtensionManager.desktop"
        "org.gnome.Extensions.desktop"
        "org.gnome.Logs.desktop"
        "menulibre.desktop"
        "org.gnome.Settings.desktop"
        "org.gnome.SystemMonitor.desktop"
        "org.gnome.tweaks.desktop"
      ];
    };
    "org/gnome/desktop/app-folders/folders/LibreOffice" = {
      name = "LibreOffice";
      translate = false;
      apps = [
        "startcenter.desktop"
        "writer.desktop"
        "calc.desktop"
        "impress.desktop"
        "draw.desktop"
        "base.desktop"
        "math.desktop"
      ];
    };
    "org/gnome/desktop/app-folders/folders/Utilities" = {
      name = "X-GNOME-Shell-Utilities.directory";
      translate = true;
      apps = [
        "org.gnome.Decibels.desktop"
        "btop.desktop"
        "org.gnome.Calculator.desktop"
        "org.gnome.Calendar.desktop"
        "org.gnome.Snapshot.desktop"
        "org.gnome.Characters.desktop"
        "org.gnome.Connections.desktop"
        "com.github.wwmm.easyeffects.desktop"
        "org.gnome.font-viewer.desktop"
        "org.gnome.Loupe.desktop"
        "org.gnome.seahorse.Application.desktop"
        "org.gnome.TextEditor.desktop"
        "org.gnome.Papers.desktop"
        "org.gnome.Evince.desktop"
        "org.gnome.FileRoller.desktop"
        "org.gnome.Showtime.desktop"
        "org.gnome.Weather.desktop"
      ];
    };
    "org/gnome/desktop/calendar" = {
      week-start-day = "monday";
    };
    "org/gnome/desktop/peripherals/touchpad" = {
      natural-scroll = false;
      two-finger-scrolling-enabled = true;
    };
    "org/gnome/desktop/wm/keybindings" = {
      close = ["<Alt>q"];
      maximize = [];
      switch-input-source = [];
      switch-input-source-backward = [];
      unmaximize = [];
      switch-applications = ["<Super>Tab"];
      switch-applications-backward = ["<Shift><Super>Tab"];
      switch-windows = ["<Alt>Tab"];
      switch-windows-backward = ["<Shift><Alt>Tab"];
    };
    "org/gnome/shell/keybindings" = {
      show-screenshot-ui = ["<Shift><Super>s"];
      toggle-message-tray = [];
    };
    "org/gnome/desktop/privacy" = {
      remove-old-temp-files = true;
      remove-old-trash-files = true;
    };
    "org/gnome/settings-daemon/plugins/power" = {
      ambient-enabled = false;
    };
    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
      night-light-schedule-automatic = true;
    };
    "org/gnome/desktop/interface" = {
      font-antialiasing = "grayscale";
      font-hinting = "slight";
      clock-show-weekday = true;
      clock-format = "24h";
      enable-hot-corners = true;
      show-battery-percentage = true;
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,close";
      focus-mode = "click";
    };
    "org/gnome/Ptyxis" = {
      cursor-blink-mode = "on";
      default-profile-uuid = "6599cd63709e767b8426be616928f947";
      font-name = "MesloLGS NF 10";
      profile-uuids = ["6599cd63709e767b8426be616928f947"];
      restore-session = false;
      use-system-font = false;
    };
    "org/gnome/Ptyxis/Profiles/6599cd63709e767b8426be616928f947" = {
      opacity = mkDouble config.stylix.opacity.terminal;
      palette = "Hybrid";
    };
    "org/gnome/shell/extensions/burn-my-windows" = {
      active-profile = "${config.home.homeDirectory}/.config/burn-my-windows/profiles/1767406314858751.conf";
    };
    "org/gnome/Weather" = {
      locations = [
        (mkVariant (mkTuple [
          (mkUint32 2)
          (mkVariant (mkTuple [
            "YourCity"
            "KMEM"
            true
            [
              (mkTuple [
                (mkDouble "0.6119318263572016")
                (mkDouble "-1.5705345274070974")
              ])
            ]
            [
              (mkTuple [
                (mkDouble "0.6134750988416926")
                (mkDouble "-1.5716511890625235")
              ])
            ]
          ]))
        ]))
      ];
    };
    # GNOME Shell weather client (read by Weather O'Clock); dconf is wiped each boot, so declare it here
    "org/gnome/shell/weather" = {
      locations = [
        (mkVariant (mkTuple [
          (mkUint32 2)
          (mkVariant (mkTuple [
            "YourCity"
            "KMEM"
            true
            [
              (mkTuple [
                (mkDouble "0.6119318263572016")
                (mkDouble "-1.5705345274070974")
              ])
            ]
            [
              (mkTuple [
                (mkDouble "0.6134750988416926")
                (mkDouble "-1.5716511890625235")
              ])
            ]
          ]))
        ]))
      ];
    };
    # Extension - Space iFlow Random Wallpaper
    "org/gnome/shell/extensions/space-iflow-randomwallpaper" = {
      # Fetch interval = hours * 60 + minutes
      hours = 0;
      minutes = 30;
      sources = ["1764395143065" "1787891671600"];
      auto-fetch = true;
      fetch-on-startup = true;
      disable-hover-preview = true;
    };
    "org/gnome/shell/extensions/space-iflow-randomwallpaper/sources/general/1764395143065" = {
      name = "wallhaven";
      type = 1;
    };
    "org/gnome/shell/extensions/space-iflow-randomwallpaper/sources/wallhaven/1764395143065" = {
      allow-nsfw = false;
      allow-sketchy = false;
      ai-art = true;
      aspect-ratios = "21x9, 32x9, 48x9";
      category-anime = true;
      category-people = true;
      minimal-resolution = "5120x1440";
    };
    "org/gnome/shell/extensions/space-iflow-randomwallpaper/sources/general/1787891671600" = {
      name = "unsplash";
      type = 0;
    };
    # api-key comes from sops via the inject-wallpaper-api-keys unit, so it is not declared here
    "org/gnome/shell/extensions/space-iflow-randomwallpaper/sources/unsplash/1787891671600" = {
      topics = "wallpapers";
      orientation = "landscape";
      content-filter = "low";
    };
    "org/gnome/shell/extensions/tilingshell" = {
      enable-autotiling = false;
      enable-blur-selected-tilepreview = false;
      enable-blur-snap-assistant = false;
      enable-smart-window-border-radius = false;
      enable-snap-assist = false;
      enable-tiling-system = true;
      enable-tiling-system-windows-suggestions = true;
      enable-window-border = false;
      enable-wraparound-focus = true;
      layouts-json = "[{\"id\":\"Layout 1\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.22,\"height\":0.5,\"groups\":[1,2]},{\"x\":0,\"y\":0.5,\"width\":0.22,\"height\":0.5,\"groups\":[1,2]},{\"x\":0.22,\"y\":0,\"width\":0.56,\"height\":1,\"groups\":[2,3]},{\"x\":0.78,\"y\":0,\"width\":0.22,\"height\":0.5,\"groups\":[3,4]},{\"x\":0.78,\"y\":0.5,\"width\":0.22,\"height\":0.5,\"groups\":[3,4]}]},{\"id\":\"Layout 2\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.22,\"height\":1,\"groups\":[1]},{\"x\":0.22,\"y\":0,\"width\":0.56,\"height\":1,\"groups\":[1,2]},{\"x\":0.78,\"y\":0,\"width\":0.22,\"height\":1,\"groups\":[2]}]},{\"id\":\"Layout 3\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.33,\"height\":1,\"groups\":[1]},{\"x\":0.33,\"y\":0,\"width\":0.67,\"height\":1,\"groups\":[1]}]},{\"id\":\"Layout 4\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.67,\"height\":1,\"groups\":[1]},{\"x\":0.67,\"y\":0,\"width\":0.33,\"height\":1,\"groups\":[1]}]},{\"id\":\"9503857\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.2375,\"height\":0.5,\"groups\":[1,2]},{\"x\":0.2375,\"y\":0,\"width\":0.38437499999999997,\"height\":1,\"groups\":[5,1]},{\"x\":0,\"y\":0.5,\"width\":0.2375,\"height\":0.5,\"groups\":[2,1]},{\"x\":0.621875,\"y\":0,\"width\":0.23750000000000004,\"height\":1,\"groups\":[3,5]},{\"x\":0.859375,\"y\":0,\"width\":0.14062500000000228,\"height\":0.5,\"groups\":[4,3]},{\"x\":0.859375,\"y\":0.5,\"width\":0.14062500000000228,\"height\":0.5,\"groups\":[4,3]}]}]";
      overridden-settings = "{\"org.gnome.mutter.keybindings\":{\"toggle-tiled-right\":\"['<Super>Right']\",\"toggle-tiled-left\":\"['<Super>Left']\"},\"org.gnome.desktop.wm.keybindings\":{\"maximize\":\"@as []\",\"unmaximize\":\"@as []\"},\"org.gnome.mutter\":{\"edge-tiling\":\"false\"}}";
      selected-layouts = [
        ["9503857"]
        ["9503857"]
      ];
      show-indicator = true;
      span-multiple-tiles-activation-key = ["1"];
      tiling-system-activation-key = ["1"];
      tiling-system-deactivation-key = ["0"];
      window-border-width = mkUint32 3;
      window-use-custom-border-color = false;
    };
    # Extension - Copyous Clipboard Manager
    "org/gnome/shell/extensions/copyous" = {
      clipboard-margin-top = 60;
      clipboard-position-horizontal = "center";
      clipboard-size = 1500;
      disable-hljs-dialog = false;
      open-clipboard-dialog-shortcut = ["<Super>v"];
    };
    # Extension - Superbar - Spotlight-style launcher
    "org/gnome/shell/extensions/superbar" = {
      toggle-shortcut = ["<Super>space"];
      # gnome-apps is the only palette path patched to stylix (see packages/package-superbar.nix)
      color-source = "gnome-apps";
      # Pinned, not derived from stylix.polarity, which also permits "either"
      theme-mode = "dark";
      background-opacity = 100;
      # api.dictionaryapi.dev outage stalls every lookup for 10s; re-enable if it returns
      dictionary-search-enabled = false;
      # Clipboard belongs to copyous; superbar's history file can't be persisted (REPLACE_DESTINATION)
      clipboard-monitor-enabled = false;
      clipboard-search-enabled = false;
      # Weather comes from Weather O'Clock already
      weather-search-enabled = false;
    };
    # Extension - Lilypad - Hides System Tray Icons
    "org/gnome/shell/extensions/lilypad" = {
      ignored-order = [];
      lilypad-order = [
        "tilingshell"
        "color_picker"
        "vlan_indicator"
        "DDCUtilBrightnessSlider"
        "random_wallpaper_menu"
        "StatusNotifierItem"
      ];
      reorder = true;
      rightbox-order = [
        "copyous"
        "lilypad"
        "357e02457a03413b916779b0e29d78d5"
      ];
      show-icons = false;
    };
    "org/gnome/shell/extensions/dash-to-panel" = {
      animate-appicon-hover = true;
      animate-appicon-hover-animation-convexity = [
        (mkDictionaryEntry [
          "RIPPLE"
          (mkDouble "2.0")
        ])
        (mkDictionaryEntry [
          "PLANK"
          (mkDouble "1.0")
        ])
        (mkDictionaryEntry [
          "SIMPLE"
          (mkDouble "0.0")
        ])
      ];
      animate-appicon-hover-animation-extent = [
        (mkDictionaryEntry [
          "RIPPLE"
          4
        ])
        (mkDictionaryEntry [
          "PLANK"
          4
        ])
        (mkDictionaryEntry [
          "SIMPLE"
          1
        ])
      ];
      animate-appicon-hover-animation-type = "SIMPLE";
      appicon-margin = 6;
      appicon-padding = 4;
      appicon-style = "NORMAL";
      dot-position = "TOP";
      dot-style-focused = "DASHES";
      dot-style-unfocused = "SOLID";
      # Impermanence wipes dconf each boot; matching the installed version suppresses the update notification
      extension-version = lib.strings.toInt pkgs.gnomeExtensions.dash-to-panel.version;
      focus-highlight-dominant = true;
      focus-highlight = true;
      dot-color-dominant = true;
      global-border-radius = 2;
      hide-overview-on-startup = true;
      hot-keys = true;
      hotkeys-overlay-combo = "TEMPORARILY";
      intellihide = true;
      intellihide-hide-from-windows = true;
      intellihide-use-pressure = true;
      panel-anchors = ''
        {"CSW-0x00000000":"MIDDLE","SAM-0x00000000":"MIDDLE"}
      '';
      panel-element-positions = ''
        {"CSW-0x00000000":[{"element":"showAppsButton","visible":true,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedBR"},{"element":"leftBox","visible":false,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedTL"},{"element":"dateMenu","visible":true,"position":"centered"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":false,"position":"stackedBR"}],"SAM-0x00000000":[{"element":"showAppsButton","visible":true,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"centered"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":false,"position":"stackedBR"}]}
      '';
      panel-lengths = ''
        {"CSW-0x00000000":70,"SAM-0x00000000":30}
      '';
      panel-positions = ''
        {"CSW-0x00000000":"TOP","SAM-0x00000000":"TOP"}
      '';
      panel-side-padding = 0;
      panel-sizes = ''
        {"CSW-0x00000000":35,"SAM-0x00000000":40}
      '';
      panel-top-bottom-margins = 4;
      panel-top-bottom-padding = 0;
      show-apps-icon-file = "";
      taskbar-locked = false;
      trans-border-custom-color = "rgb(${config.lib.stylix.colors.base0D-rgb-r}, ${config.lib.stylix.colors.base0D-rgb-g}, ${config.lib.stylix.colors.base0D-rgb-b})";
      trans-border-use-custom-color = true;
      trans-border-width = 2;
      trans-panel-opacity = mkDouble config.stylix.opacity.terminal;
      trans-use-border = true;
      trans-use-custom-opacity = false;
      trans-use-dynamic-opacity = false;
      window-preview-title-position = "TOP";
    };
    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      blur = false;
    };
    # v73+ blurs popups/notifications by default; under the stylix theme it leaves black corners
    "org/gnome/shell/extensions/blur-my-shell/popup" = {
      blur = false;
    };
    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur = false;
    };
    # Off = GNOME's stock unlock-dialog blur, which looks the same
    "org/gnome/shell/extensions/blur-my-shell/lockscreen" = {
      blur = false;
    };
    "org/gnome/shell/extensions/blur-my-shell/window-list" = {
      blur = false;
    };
    "org/gnome/shell/extensions/blur-my-shell/coverflow-alt-tab" = {
      blur = false;
    };
    "org/gnome/shell/extensions/alphabetical-app-grid" = {
      folder-order-position = "end";
    };
    "org/gnome/shell/extensions/updated-vlan-switcher" = {
      show-quick-settings = false;
    };
    "org/gnome/shell/extensions/display-brightness-ddcutil" = {
      disable-display-state-check = true;
    };
    # Extension - GSConnect (KDE Connect for GNOME)
    # Declared to keep the pairing; the TLS identity is persisted via home.nix
    "org/gnome/shell/extensions/gsconnect" = {
      name = "nixos-framework";
      devices = ["357e02457a03413b916779b0e29d78d5"];
    };
    "org/gnome/shell/extensions/gsconnect/device/357e02457a03413b916779b0e29d78d5" = {
      name = "Pixel 9 Pro";
      type = "tablet";
      paired = true;
      certificate-pem = ''
        -----BEGIN CERTIFICATE-----
        MIIBizCCATGgAwIBAgIBATAKBggqhkjOPQQDBDBPMSkwJwYDVQQDDCAzNTdlMDI0
        NTdhMDM0MTNiOTE2Nzc5YjBlMjlkNzhkNTEUMBIGA1UECwwLS0RFIENvbm5lY3Qx
        DDAKBgNVBAoMA0tERTAeFw0yNDA0MTQwNTAwMDBaFw0zNTA0MTQwNTAwMDBaME8x
        KTAnBgNVBAMMIDM1N2UwMjQ1N2EwMzQxM2I5MTY3NzliMGUyOWQ3OGQ1MRQwEgYD
        VQQLDAtLREUgQ29ubmVjdDEMMAoGA1UECgwDS0RFMFkwEwYHKoZIzj0CAQYIKoZI
        zj0DAQcDQgAEq0KWqJvoUbAcVXlJMqMv0bUTqSsnenS2jQuv7dSfswbqTd0LY5Ng
        S2Y5KQcvwZZ6RzQF48Lo1qMLX46k5B2WVjAKBggqhkjOPQQDBANIADBFAiBWFeyK
        GS5RLc5hGSieWaJWQvX9XCtEGcIH7un4usuzFQIhAMq+MiNHLtyFyZP2C3un1rur
        UwdfWfb0usd6oDQgS+OJ
        -----END CERTIFICATE-----
      '';
    };
  };

  # Restyle dash-to-panel's panel-button highlight to match its Show Apps button: full-height, 8px (global-border-radius = 2), same tint
  xdg.dataFile."themes/Stylix/gnome-shell/gnome-shell.css".source = let
    theme = pkgs.callPackage "${inputs.stylix}/modules/gnome/theme.nix" {
      inherit (inputs.stylix) inputs;
      inherit (config.lib.stylix) colors;
    };
  in
    lib.mkForce (pkgs.runCommand "stylix-gnome-shell-dtp.css" {} ''
      cat ${theme}/share/gnome-shell/gnome-shell.css - > $out <<'EOF'
      #panel.dashtopanelMainPanel .panel-button,
      #panel.dashtopanelMainPanel .panel-button.clock-display .clock {
        border-width: 0;
        border-radius: 8px; }
      #panel.dashtopanelMainPanel .panel-button:hover,
      #panel.dashtopanelMainPanel .panel-button:focus,
      #panel.dashtopanelMainPanel .panel-button.clock-display:hover .clock,
      #panel.dashtopanelMainPanel .panel-button.clock-display:focus .clock {
        box-shadow: none;
        background-color: rgba(238, 238, 238, 0.1); }
      #panel.dashtopanelMainPanel .panel-button:active,
      #panel.dashtopanelMainPanel .panel-button:checked,
      #panel.dashtopanelMainPanel .panel-button.clock-display:active .clock,
      #panel.dashtopanelMainPanel .panel-button.clock-display:checked .clock {
        box-shadow: none;
        background-color: rgba(238, 238, 238, 0.18); }
      EOF
    '');
}
