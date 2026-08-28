# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib.hm.gvariant; {
  dconf.settings = {
    "org/gnome/mutter" = {
      edge-tiling = false; # Disable edge tiling to prevent conflicts with Tiling Shell extension
    };
    "org/gnome/settings-daemon/plugins/housekeeping" = {
      "donation-reminder-enabled" = false;
    };
    # GNOME - Tracker file indexing; dconf is wiped each boot, so declare it here
    "org/freedesktop/tracker/miner/files" = {
      index-recursive-directories = [
        "$HOME"
        "&DOWNLOAD"
        "&DOCUMENTS"
        "&MUSIC"
        "&PICTURES"
        "&VIDEOS"
      ];
    };
    "org/gnome/desktop/sound" = {
      theme-name = "modern-minimal-ui-sounds-v1.1";
      event-sounds = true;
    };
    "org/gnome/shell" = {
      disable-extension-version-validation = true; # Allow installing extensions from other GNOME versions
      favorite-apps = [
        "firefox.desktop"
        "code.desktop"
        "org.gnome.Ptyxis.desktop"
        "org.gnome.Nautilus.desktop"
      ];
      disabled-extensions = [];
      enabled-extensions = [
        # Enabled in list order, one at a time; dash-to-panel now suppresses the
        # startup overview, so it must run before startup-complete — keep it first.
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
    "org/gnome/desktop/datetime" = {
      automatic-timezone = true;
    };
    "org/gnome/desktop/calendar" = {
      week-start-day = "monday";
    };
    "org/gnome/desktop/peripherals/touchpad" = {
      natural-scroll = false; # Turn off world's shittiest scroll
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
      night-light-schedule-automatic = true; # Follow sunset to sunrise
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
      automatic-location = true;
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
        {"CSW-0x00000000":"MIDDLE","SAM-HNTYA00004":"MIDDLE"}
      '';
      panel-element-positions = ''
        {"CSW-0x00000000":[{"element":"showAppsButton","visible":true,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedBR"},{"element":"leftBox","visible":false,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedTL"},{"element":"dateMenu","visible":true,"position":"centered"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":false,"position":"stackedBR"}],"SAM-HNTYA00004":[{"element":"showAppsButton","visible":true,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"centered"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":false,"position":"stackedBR"}]}
      '';
      panel-lengths = ''
        {"CSW-0x00000000":70,"SAM-HNTYA00004":30}
      '';
      panel-positions = ''
        {"CSW-0x00000000":"TOP","SAM-HNTYA00004":"TOP"}
      '';
      panel-side-padding = 0;
      panel-sizes = ''
        {"CSW-0x00000000":35,"SAM-HNTYA00004":40}
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
    # dconf is wiped each boot, so declare the paired device to keep the pairing.
    # The host TLS identity (~/.config/gsconnect/{certificate,private}.pem) is
    # persisted via home.nix; the rest (capabilities/plugins) is renegotiated on connect.
    "org/gnome/shell/extensions/gsconnect" = {
      name = "gearhead";
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
}
