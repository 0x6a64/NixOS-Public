# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{
  config,
  lib,
  ...
}:
with lib.hm.gvariant; {
  dconf.settings = {
    # GNOME Mutter Settings
    "org/gnome/mutter" = {
      experimental-features = [
        "scale-monitor-framebuffer" # Enables fractional scaling (125% 150% 175%)
        "variable-refresh-rate" # Enables Variable Refresh Rate (VRR) on compatible displays
        "xwayland-native-scaling" # Scales Xwayland applications to look crisp on HiDPI screens
      ];
      edge-tiling = false; # Disable edge tiling to prevent conflicts with Tiling Shell extension
    };
    "org/gnome/settings-daemon/plugins/housekeeping" = {
      "donation-reminder-enabled" = false;
    };
    # GNOME - Sound Themes
    "org/gnome/desktop/sound" = {
      theme-name = "modern-minimal-ui-sounds-v1.1";
      event-sounds = true;
    };
    # GNOME - Disable Extension Version Validation & Favorites
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
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "AlphabeticalAppGrid@stuarthayhurst"
        "appindicatorsupport@rgcjonas.gmail.com"
        "blur-my-shell@aunetx"
        "display-brightness-ddcutil@themightydeity.github.com"
        "burn-my-windows@schneegans.github.com"
        "caffeine@patapon.info"
        "custom-hot-corners-extended@G-dH.github.com"
        "color-picker@tuberry"
        "copyous@boerdereinar.dev"
        "dash-to-panel@jderose9.github.com"
        "gsconnect@andyholmes.github.io"
        "lilypad@shendrew.github.io"
        "pip-on-top@rafostar.github.com"
        "randomwallpaper@iflow.space"
        "rounded-window-corners@fxgn"
        "tilingshell@ferrarodomenico.com"
        "vlan-controller@tiagocasalribeiro.github.io"
        "weatheroclock@CleoMenezesJr.github.io"
      ];
    };
    # GNOME - App Folders
    "org/gnome/desktop/app-folders" = {
      folder-children = ["System" "Utilities"];
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
        "org.gnome.Software.desktop"
        "org.gnome.SystemMonitor.desktop"
        "org.gnome.tweaks.desktop"
      ];
    };
    "org/gnome/software" = {
      download-updates-notify = false;
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
        "keymapp.desktop"
        "org.gnome.seahorse.Application.desktop"
        "org.gnome.TextEditor.desktop"
        "org.gnome.Papers.desktop"
        "org.gnome.Evince.desktop"
        "org.gnome.FileRoller.desktop"
        "org.gnome.Showtime.desktop"
        "org.gnome.Weather.desktop"
      ];
    };
    # GNOME - DateTime
    "org/gnome/desktop/datetime" = {
      automatic-timezone = true;
    };
    # GNOME - Touchpad
    "org/gnome/desktop/peripherals/touchpad" = {
      natural-scroll = false; # Turn off world's shittiest scroll
      two-finger-scrolling-enabled = true;
    };
    # GNOME - Extension Manager Settings
    "com/mattjakeman/ExtensionManager" = {
      show-unsupported = true;
    };
    # GNOME - Keybindings
    "org/gnome/desktop/wm/keybindings" = {
      close = ["<Alt>q"];
      maximize = [];
      switch-input-source = [];
      switch-input-source-backward = [];
      unmaximize = [];
    };
    "org/gnome/shell/keybindings" = {
      show-screenshot-ui = ["<Shift><Super>s"];
      toggle-message-tray = [];
    };
    # GNOME - Privacy
    "org/gnome/desktop/privacy" = {
      remove-old-temp-files = true;
      remove-old-trash-files = true;
      remove-old-temporary-files = true;
    };
    # GNOME - Nightlight
    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
      night-light-schedule-from = 22.0;
    };
    # GNOME - Design - Interface
    "org/gnome/desktop/interface" = {
      font-antialiasing = "grayscale";
      font-hinting = "slight";
      clock-show-weekday = true;
      clock-format = "24h";
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,close";
      focus-mode = "mouse";
    };
    # Design - App - Ptyxis
    "org/gnome/Ptyxis" = {
      cursor-blink-mode = "on";
      default-profile-uuid = "6599cd63709e767b8426be616928f947";
      font-name = "MesloLGS NF 10";
      profile-uuids = ["6599cd63709e767b8426be616928f947"];
      use-system-font = false;
    };
    # Design - App - Ptyxis Profile
    "org/gnome/Ptyxis/Profiles/6599cd63709e767b8426be616928f947" = {
      opacity = mkDouble config.stylix.opacity.terminal;
      palette = "Hybrid";
    };
    # Extensions - Burn My Windows
    "org/gnome/shell/extensions/burn-my-windows" = {
      active-profile = "/home/user/.config/burn-my-windows/profiles/1767406314858751.conf";
    };
    # Extensions - GNOME Weather
    "org/gnome/Weather" = {
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
      change-interval = 90;
      source = "wallhaven";
      sources = ["1764395143065"];
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
      #keyword = "-cars, -guns, -videogames, -game, -bright, -white";
      minimal-resolution = "5120x1440";
    };
    # Extension - Tiling Shell
    "org/gnome/shell/extensions/tilingshell" = {
      enable-autotiling = false;
      enable-blur-selected-tilepreview = false;
      enable-blur-snap-assistant = false;
      enable-smart-window-border-radius = false;
      enable-snap-assist = false;
      enable-tiling-system = true;
      enable-tiling-system-windows-suggestions = true;
      enable-window-border = true;
      enable-wraparound-focus = true;
      last-version-name-installed = "17.1";
      layouts-json = "[{\"id\":\"Layout 1\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.22,\"height\":0.5,\"groups\":[1,2]},{\"x\":0,\"y\":0.5,\"width\":0.22,\"height\":0.5,\"groups\":[1,2]},{\"x\":0.22,\"y\":0,\"width\":0.56,\"height\":1,\"groups\":[2,3]},{\"x\":0.78,\"y\":0,\"width\":0.22,\"height\":0.5,\"groups\":[3,4]},{\"x\":0.78,\"y\":0.5,\"width\":0.22,\"height\":0.5,\"groups\":[3,4]}]},{\"id\":\"Layout 2\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.22,\"height\":1,\"groups\":[1]},{\"x\":0.22,\"y\":0,\"width\":0.56,\"height\":1,\"groups\":[1,2]},{\"x\":0.78,\"y\":0,\"width\":0.22,\"height\":1,\"groups\":[2]}]},{\"id\":\"Layout 3\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.33,\"height\":1,\"groups\":[1]},{\"x\":0.33,\"y\":0,\"width\":0.67,\"height\":1,\"groups\":[1]}]},{\"id\":\"Layout 4\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.67,\"height\":1,\"groups\":[1]},{\"x\":0.67,\"y\":0,\"width\":0.33,\"height\":1,\"groups\":[1]}]},{\"id\":\"9503857\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.2375,\"height\":0.5,\"groups\":[1,2]},{\"x\":0.2375,\"y\":0,\"width\":0.38437499999999997,\"height\":1,\"groups\":[5,1]},{\"x\":0,\"y\":0.5,\"width\":0.2375,\"height\":0.5,\"groups\":[2,1]},{\"x\":0.621875,\"y\":0,\"width\":0.23750000000000004,\"height\":1,\"groups\":[3,5]},{\"x\":0.859375,\"y\":0,\"width\":0.14062500000000228,\"height\":0.5,\"groups\":[4,3]},{\"x\":0.859375,\"y\":0.5,\"width\":0.14062500000000228,\"height\":0.5,\"groups\":[4,3]}]}]";
      overridden-settings = "{\"org.gnome.mutter.keybindings\":{\"toggle-tiled-right\":\"['<Super>Right']\",\"toggle-tiled-left\":\"['<Super>Left']\"},\"org.gnome.desktop.wm.keybindings\":{\"maximize\":\"@as []\",\"unmaximize\":\"@as []\"},\"org.gnome.mutter\":{\"edge-tiling\":\"false\"}}";
      selected-layouts = [
        ["9503857"]
        ["9503857"]
      ];
      show-indicator = true;
      span-multiple-tiles-activation-key = ["1"];
      tiling-system-activation-key = ["2"];
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
        "CustomHotCorners"
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
    # Extension - Dash to Panel
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
      extension-version = 72;
      focus-highlight-dominant = true;
      focus-highlight = true;
      dot-color-dominant = true;
      global-border-radius = 2;
      hot-keys = true;
      hotkeys-overlay-combo = "TEMPORARILY";
      intellihide = true;
      intellihide-hide-from-windows = true;
      intellihide-use-pressure = true;
      panel-anchors = ''
        {"BOE-0x00000000":"MIDDLE","SAM-HNTYA00004":"MIDDLE"}
      '';
      panel-element-positions = ''
        {"BOE-0x00000000":[{"element":"showAppsButton","visible":true,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedBR"},{"element":"leftBox","visible":false,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedTL"},{"element":"dateMenu","visible":true,"position":"centered"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":false,"position":"stackedBR"}],"SAM-HNTYA00004":[{"element":"showAppsButton","visible":true,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"centered"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":false,"position":"stackedBR"}]}
      '';
      panel-lengths = ''
        {"BOE-0x00000000":70,"SAM-HNTYA00004":30}
      '';
      panel-positions = ''
        {"BOE-0x00000000":"TOP","SAM-HNTYA00004":"TOP"}
      '';
      panel-side-padding = 0;
      panel-sizes = ''
        {"BOE-0x00000000":35,"SAM-HNTYA00004":40}
      '';
      panel-top-bottom-margins = 4;
      panel-top-bottom-padding = 0;
      prefs-opened = true;
      show-apps-icon-file = "";
      taskbar-locked = false;
      # trans-bg-color = "#222226";
      trans-border-custom-color = "rgb(${config.lib.stylix.colors.base0D-rgb-r}, ${config.lib.stylix.colors.base0D-rgb-g}, ${config.lib.stylix.colors.base0D-rgb-b})";
      trans-border-use-custom-color = true;
      trans-border-width = 2;
      trans-panel-opacity = mkDouble config.stylix.opacity.terminal;
      trans-use-border = true;
      # trans-use-custom-bg = true;
      trans-use-custom-opacity = false;
      trans-use-dynamic-opacity = false;
      window-preview-title-position = "TOP";
    };
    # Extension - Custom Hot Corners Extended
    "org/gnome/shell/extensions/custom-hot-corners-extended/misc" = {
      corners-visible = false;
      show-osd-monitor-indexes = false;
      supported-active-extensions = [];
    };
    "org/gnome/shell/extensions/custom-hot-corners-extended/monitor-0-top-left-0" = {
      action = "toggle-overview";
      barrier-size-h = 25;
      barrier-size-v = 25;
    };
    "org/gnome/shell/extensions/custom-hot-corners-extended/monitor-0-top-right-0" = {
      action = "toggle-overview";
      barrier-size-h = 25;
      barrier-size-v = 25;
    };
    # Extension - Blur My Shell
    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      blur = false;
    };
    # Extension - Alphabetical App Grid
    "org/gnome/shell/extensions/alphabetical-app-grid" = {
      folder-order-position = "end";
    };
    # Extension - Rounded Window Corners Reborn
    "org/gnome/shell/extensions/rounded-window-corners-reborn" = {
      border-width = 2;
      enable-preferences-entry = false;
      focused-shadow = [
        (mkDictionaryEntry [
          "verticalOffset"
          4
        ])
        (mkDictionaryEntry [
          "horizontalOffset"
          0
        ])
        (mkDictionaryEntry [
          "blurOffset"
          28
        ])
        (mkDictionaryEntry [
          "spreadRadius"
          4
        ])
        (mkDictionaryEntry [
          "opacity"
          60
        ])
      ];
      global-rounded-corner-settings = [
        (mkDictionaryEntry [
          "padding"
          (mkVariant [
            (mkDictionaryEntry [
              "left"
              (mkUint32 0)
            ])
            (mkDictionaryEntry [
              "right"
              0
            ])
            (mkDictionaryEntry [
              "top"
              0
            ])
            (mkDictionaryEntry [
              "bottom"
              0
            ])
          ])
        ])
        (mkDictionaryEntry [
          "keepRoundedCorners"
          (mkVariant [
            (mkDictionaryEntry [
              "maximized"
              false
            ])
            (mkDictionaryEntry [
              "fullscreen"
              false
            ])
          ])
        ])
        (mkDictionaryEntry [
          "borderRadius"
          (mkVariant (mkUint32 12))
        ])
        (mkDictionaryEntry [
          "smoothing"
          (mkVariant (mkDouble "1.0"))
        ])
        (mkDictionaryEntry [
          "borderColor"
          (mkVariant (mkTuple [
            (mkDouble (
              toString (builtins.div (lib.strings.toInt config.lib.stylix.colors.base03-rgb-r) 255.0)
            ))
            (mkDouble (
              toString (builtins.div (lib.strings.toInt config.lib.stylix.colors.base03-rgb-g) 255.0)
            ))
            (mkDouble (
              toString (builtins.div (lib.strings.toInt config.lib.stylix.colors.base03-rgb-b) 255.0)
            ))
            (mkDouble "1.0")
          ]))
        ])
        (mkDictionaryEntry [
          "enabled"
          (mkVariant true)
        ])
      ];
      settings-version = mkUint32 7;
      skip-libadwaita-app = false;
      skip-libhandy-app = false;
      unfocused-shadow = [
        (mkDictionaryEntry [
          "verticalOffset"
          2
        ])
        (mkDictionaryEntry [
          "horizontalOffset"
          0
        ])
        (mkDictionaryEntry [
          "blurOffset"
          12
        ])
        (mkDictionaryEntry [
          "spreadRadius"
          (-1)
        ])
        (mkDictionaryEntry [
          "opacity"
          65
        ])
      ];
    };
  };
}
