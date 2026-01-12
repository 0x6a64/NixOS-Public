{
  pkgs,
  config,
  lib,
  activeDesktopEnvironment ? "gnome",
  ...
}:
with lib; {
  programs.firefox = {
    enable = true;

    # Policies for enterprise-level settings
    policies = {
      AutofillAddressEnabled = true;
      AutofillCreditCardEnabled = false;
      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true; # save webs for later reading
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
        Enabled = "false";
        Locked = true;
      };

      # Lock toolbar customization to prevent rearrangement on first start
      DisableCustomization = false;

      # Pin extensions to toolbar (works with NUR-installed extensions)
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

    # Profile configuration (at same level as policies, NOT inside it)
    profiles.default = {
      id = 0;
      isDefault = true;

      # Firefox extensions from NUR
      extensions = {
        force = true;
        packages =
          (with pkgs.nur.repos.rycee.firefox-addons; [
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
          ])
          # DE-specific extensions
          ++ (optionals (activeDesktopEnvironment == "gnome")
            (with pkgs.nur.repos.rycee.firefox-addons; [
              gsconnect
            ]))
          ++ (optionals (activeDesktopEnvironment == "plasma")
            (with pkgs.nur.repos.rycee.firefox-addons; [
              plasma-integration
            ]));
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

      # Advanced preferences (for things not supported by policies)
      settings = {
        # Skip initial startup/welcome screens
        "browser.startup.homepage_override.mstone" = "ignore";
        "browser.aboutwelcome.enabled" = false;
        "datareporting.policy.dataSubmissionPolicyBypassNotification" = true;
        "browser.startup.firstrunSkipsHomepage" = false;

        "apz.gtk.kinetic_scroll.enabled" = false;
        "general.autoScroll" = true;

        "browser.tabs.warnOnClose" = false;
        "browser.startup.page" = 3; # restore previous session

        "browser.ml.chat.enabled" = false;
        "browser.ml.chat.page" = false;
        "browser.ml.linkPreview.enabled" = false;
        "browser.ml.linkPreview.optin" = false;
        "browser.tabs.groups.smart.userEnabled" = false;

        # Disable home content via preferences
        "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.feeds.snippets" = false;

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

        "extensions.autoDisableScopes" = 0;
        "extensions.update.autoUpdateDefault" = false;
        "extensions.update.enabled" = false;

        # === THEME SETTINGS ===
        # "gnomeTheme.activeTabContrast" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # === SIDEBAR SETTINGS ===

        # Sidebar position (left or right)
        "sidebar.position_start" = true; # false = right side, true = left side

        # Enable new sidebar redesign (Firefox 131+)
        "sidebar.revamp" = true;

        # Enable vertical tabs in sidebar (requires sidebar.revamp)
        "sidebar.verticalTabs" = true;

        # Show Firefox Tools in sidebar
        # "sidebar.main.tools" = true; # Enables tools section in sidebar

        # Sidebar visibility on startup
        # "sidebar.visibility" = "show-sidebar"; # Options: "always-show", "hide-sidebar", "show-sidebar"

        # Default sidebar panel to show (optional)
        # Options: "viewBookmarksSidebar", "viewHistorySidebar", "viewTabsSidebar", etc.
        # "sidebar.main.default-panel" = "viewTabsSidebar";

        # Enable AI Chatbot in sidebar (Firefox 130+, if available)
        # "browser.ml.chat.sidebar" = true;

        # Dismiss drag-to-pin promo (prevents showing the promo again)
        "sidebar.verticalTabs.dragToPinPromo.dismissed" = true;

        # Enable extensions in sidebar
        # "extensions.sidebar-button.shown" = true;

        # Allow web extensions to access sidebar
        # "extensions.webextensions.sidebar-enabled" = true;

        # Ensure UI customization state is applied and not overridden
        "browser.uiCustomization.state.stored" = true;

        # UI/Toolbar customization state (fixed positions for navbar items)
        "browser.uiCustomization.state" = ''${builtins.toJSON {
            placements = {
              widget-overflow-fixed-list = [];
              unified-extensions-area =
                [
                  "firefoxcolor_mozilla_com-browser-action"
                  "frankerfacez_frankerfacez_com-browser-action"
                  "tab-stash_condordes_net-browser-action"
                  "addon_simplelogin-browser-action"
                  "vpn_proton_ch-browser-action"
                  "_contain-facebook-browser-action"
                  "addon_darkreader_org-browser-action"
                  "languagetool-webextension_languagetool_org-browser-action"
                  "tab-session-manager_sienori-browser-action"
                  "sponsorblocker_ajay_app-browser-action"
                ]
                ++ (optionals (activeDesktopEnvironment == "gnome") [
                  "gsconnect_andyholmes_github_io-browser-action"
                ])
                ++ (optionals (activeDesktopEnvironment == "plasma") [
                  "plasma-browser-integration@kde_org-browser-action"
                ]);
              nav-bar = [
                "firefox-view-button"
                "alltabs-button"
                "vertical-spacer"
                "sidebar-button"
                "stop-reload-button"
                "customizableui-special-spring2"
                "urlbar-container"
                "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action" # Bitwarden
                "ublock0_raymondhill_net-browser-action"
                "unified-extensions-button"
                "forward-button"
                "back-button"
                "downloads-button"
              ];
              toolbar-menubar = ["menubar-items"];
              TabsToolbar = [];
              vertical-tabs = ["tabbrowser-tabs"];
              PersonalToolbar = ["personal-bookmarks"];
            };
            seen =
              [
                "firefoxcolor_mozilla_com-browser-action"
                "frankerfacez_frankerfacez_com-browser-action"
                "tab-stash_condordes_net-browser-action"
                "addon_simplelogin-browser-action"
                "vpn_proton_ch-browser-action"
                "_contain-facebook-browser-action"
                "addon_darkreader_org-browser-action"
                "languagetool-webextension_languagetool_org-browser-action"
                "tab-session-manager_sienori-browser-action"
                "ublock0_raymondhill_net-browser-action"
                "sponsorblocker_ajay_app-browser-action"
                "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
                "developer-button"
                "screenshot-button"
              ]
              ++ (optionals (activeDesktopEnvironment == "gnome") [
                "gsconnect_andyholmes_github_io-browser-action"
              ])
              ++ (optionals (activeDesktopEnvironment == "plasma") [
                "plasma-browser-integration@kde_org-browser-action"
              ]);
            dirtyAreaCache = [
              "unified-extensions-area"
              "nav-bar"
              "TabsToolbar"
              "vertical-tabs"
              "toolbar-menubar"
              "PersonalToolbar"
            ];
            currentVersion = 23;
            newElementCount = 5;
          }}'';
      };

      # Import custom userChrome additions (overlay on top of stylix GNOME theme)
      userChrome = ''
        @import url("userChrome-custom.css");
      '';

      # Firefox Containers configuration
      containers = {
        secondary = {
          color = "pink";
          icon = "fruit";
          id = 1;
        };
        alt = {
          color = "blue";
          icon = "briefcase";
          id = 0;
        };
      };
      containersForce = true;

      # Custom search engines
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
    };
  };
  stylix.targets.firefox.profileNames = ["default"];
  stylix.targets.firefox.colorTheme.enable = true;
  stylix.targets.firefox.colors.enable = true;
  # stylix.targets.firefox.firefoxGnomeTheme.enable = true;
  stylix.targets.firefox.fonts.enable = true;
}
