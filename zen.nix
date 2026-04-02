{
  inputs,
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  isGnome = osConfig.services.desktopManager.gnome.enable or false;
in {
  imports = [
    inputs.zen-browser.homeModules.beta
  ];
  programs.zen-browser = {
    enable = true;

    policies = {
      AutofillAddressEnabled = true;
      AutofillCreditCardEnabled = false;
      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Category = "strict";
        BaselineExceptions = true;
        ConvenienceExceptions = false;
      };
      DNSOverHTTPS = {
        Enabled = false;
        Locked = true;
      };

      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          default_area = "navbar";
          private_browsing = true;
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          default_area = "navbar";
          private_browsing = true;
        };
        "addon@darkreader.org" = {
          # default_area = "navbar";
          private_browsing = true;
        };
        "sponsorBlocker@ajay.app" = {
          default_area = "menupanel";
        };
      };
    };

    profiles.default = let
      containers = {
        alt = {
          color = "blue";
          icon = "briefcase";
          id = 1;
        };
        secondary = {
          color = "pink";
          icon = "fruit";
          id = 2;
        };
      };

      spaces = {
        "primary" = {
          id = "572910e1-4468-4832-a869-0b3a93e2f165";
          icon = "💠";
          position = 1000;
          theme = {
            type = "gradient";
            colors = [
              {
                red = lib.strings.toInt config.lib.stylix.colors.base00-rgb-r;
                green = lib.strings.toInt config.lib.stylix.colors.base00-rgb-g;
                blue = lib.strings.toInt config.lib.stylix.colors.base00-rgb-b;
                algorithm = "floating";
                type = "explicit-lightness";
              }
            ];
            opacity = 1.0;
            texture = 0.5;
          };
        };
        "secondary" = {
          id = "ec287d7f-d910-4860-b400-513f269dee77";
          icon = "🫟";
          container = containers.secondary.id;
          position = 1001;
          theme = {
            type = "gradient";
            colors = [
              {
                red = lib.strings.toInt config.lib.stylix.colors.base00-rgb-r;
                green = lib.strings.toInt config.lib.stylix.colors.base00-rgb-g;
                blue = lib.strings.toInt config.lib.stylix.colors.base00-rgb-b;
                algorithm = "floating";
                type = "explicit-lightness";
              }
            ];
            opacity = 1.0;
            texture = 0.5;
          };
        };
      };

      pins = {
        "reddit" = {
          id = "48e8a119-5a14-4826-9545-91c8e8dd3bf6";
          workspace = spaces."primary".id;
          url = "https://reddit.com";
          position = 101;
          isEssential = true;
        };
        "youtube" = {
          id = "1eabb6a3-911b-4fa9-9eaf-232a3703db19";
          workspace = spaces."primary".id;
          url = "https://youtube.com";
          position = 102;
          isEssential = true;
        };
        "messages" = {
          id = "2eabb6a3-911b-4fa9-9eaf-232a3703db20";
          workspace = spaces."primary".id;
          url = "https://messages.google.com/web/u/1/conversations";
          position = 103;
          isEssential = true;
        };
        "reddit-secondary" = {
          id = "3eabb6a3-911b-4fa9-9eaf-232a3703db21";
          workspace = spaces."secondary".id;
          url = "https://reddit.com/";
          position = 201;
          isEssential = true;
          container = containers.secondary.id;
        };
      };
    in {
      id = 0;
      isDefault = true;

      extensions = {
        force = true;
        packages = with pkgs.nur.repos.rycee.firefox-addons;
          [
            ublock-origin
            bitwarden
            darkreader
            languagetool
            dont-track-me-google1
            facebook-container
            frankerfacez
            old-reddit-redirect
            proton-vpn
            reddit-enhancement-suite
            simplelogin
            sponsorblock
            tab-session-manager
            tab-stash
          ]
          ++ lib.optionals isGnome (with pkgs.nur.repos.rycee.firefox-addons; [
            gsconnect
          ]);
        settings = {
          "uBlock0@raymondhill.net".settings = {
            selectedFilterLists = [
              "ublock-filters"
              "ublock-badware"
              "ublock-privacy"
              "ublock-unbreak"
              "ublock-quick-fixes"
              "easylist"
              "easyprivacy"
              "curben-phishing"
              "plowe-0"
              "urlhaus-1"
              "adguard-cookies"
              "ublock-cookies-adguard"
              "ublock-annoyances"
            ];
            uiAccentCustom = true;
            uiAccentCustom0 = "${config.lib.stylix.colors.withHashtag.base0D}";
          };
        };
      };

      settings = {
        #Zen specific settings
        "zen.welcome-screen.seen" = true;
        "zen.workspaces.continue-where-left-off" = true;
        "zen.workspaces.force-container-workspace" = true;
        "zen.pinned-tab-manager.restore-pinned-tabs-to-pinned-url" = true;

        # Skip initial startup/welcome screens
        "browser.startup.homepage_override.mstone" = "ignore";
        "browser.aboutwelcome.enabled" = false;
        "datareporting.policy.dataSubmissionPolicyBypassNotification" = true;
        "browser.startup.firstrunSkipsHomepage" = false;

        "apz.gtk.kinetic_scroll.enabled" = false; # Fixes worst scroll
        "general.autoScroll" = true;

        "browser.tabs.warnOnClose" = false;
        "browser.startup.page" = 3; # restore previous session

        # Keep weather enabled (this is the preference that controls it)
        "browser.newtabpage.activity-stream.showWeather" = true;

        # Disable Firefox Suggest (sponsored and trending suggestions from Mozilla)
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
        "browser.urlbar.quicksuggest.enabled" = false;
        "browser.urlbar.quicksuggest.dataCollection.enabled" = false;

        # Disable trending searches
        "browser.urlbar.trending.featureGate" = false;
        "browser.urlbar.suggest.trending" = false;

        # Disable sponsored suggestions
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;

        # DNS over HTTPS settings
        "network.trr.mode" = 5;

        # Extension Update Settings
        "extensions.autoDisableScopes" = 0;
        "extensions.update.autoUpdateDefault" = false;
        "extensions.update.enabled" = false;

        # UI/Toolbar customization state
        "browser.uiCustomization.state" = ''${builtins.toJSON {
            placements = {
              widget-overflow-fixed-list = [];
              unified-extensions-area = [
                "frankerfacez_frankerfacez_com-browser-action"
                "tab-stash_condordes_net-browser-action"
                "addon_simplelogin-browser-action"
                "vpn_proton_ch-browser-action"
                "_contain-facebook-browser-action"
                "tab-session-manager_sienori-browser-action"
                "gsconnect_andyholmes_github_io-browser-action"
                "addon_darkreader_org-browser-action"
                "languagetool-webextension_languagetool_org-browser-action"
                "sponsorblocker_ajay_app-browser-action"
              ];
              nav-bar = [
                "back-button"
                "forward-button"
                "vertical-spacer"
                "urlbar-container"
                "unified-extensions-button"
              ];
              toolbar-menubar = ["menubar-items"];
              TabsToolbar = ["tabbrowser-tabs"];
              vertical-tabs = [];
              PersonalToolbar = ["personal-bookmarks"];
              zen-sidebar-top-buttons = [
                "zen-toggle-compact-mode"
                "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action" # Bitwarden
                "ublock0_raymondhill_net-browser-action"
              ];
              zen-sidebar-foot-buttons = [
                "downloads-button"
                "zen-workspaces-button"
                "stop-reload-button"
                "zen-create-new-button"
              ];
            };
            seen = [
              "frankerfacez_frankerfacez_com-browser-action"
              "tab-stash_condordes_net-browser-action"
              "addon_simplelogin-browser-action"
              "vpn_proton_ch-browser-action"
              "_contain-facebook-browser-action"
              "tab-session-manager_sienori-browser-action"
              "gsconnect_andyholmes_github_io-browser-action"
              "addon_darkreader_org-browser-action"
              "languagetool-webextension_languagetool_org-browser-action"
              "sponsorblocker_ajay_app-browser-action"
              "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
              "ublock0_raymondhill_net-browser-action"
              "developer-button"
              "screenshot-button"
            ];
            dirtyAreaCache = [
              "unified-extensions-area"
              "nav-bar"
              "vertical-tabs"
              "zen-sidebar-foot-buttons"
              "zen-sidebar-top-buttons"
            ];
            currentVersion = 23;
            newElementCount = 3;
          }}'';
      };

      containersForce = true;
      inherit containers;

      userChrome = ''
        @import url("userChrome-custom.css");
      '';

      search = {
        force = true;
        default = "google";
        engines = let
          nixSnowflakeIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        in {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = nixSnowflakeIcon;
            definedAliases = ["np"];
          };
          "Nix Options" = {
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = nixSnowflakeIcon;
            definedAliases = ["nop"];
          };
          "Home Manager Options" = {
            urls = [
              {
                template = "https://home-manager-options.extranix.com/";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                  {
                    name = "release";
                    value = "master"; # unstable
                  }
                ];
              }
            ];
            icon = nixSnowflakeIcon;
            definedAliases = ["hmop"];
          };
          bing.metaData.hidden = "true";
        };
      };

      pinsForce = true;
      spacesForce = true;
      inherit pins spaces;
    };
  };
  stylix.targets.zen-browser.profileNames = ["default"];
  stylix.targets.zen-browser.enable = true;
}
