{
  description = "GNOME extensions overlay — remove once nixpkgs auto-update PR lands";

  outputs = {self}: {
    overlays.default = final: prev: {
      gnomeExtensions =
        prev.gnomeExtensions
        // {
          blur-my-shell = prev.gnomeExtensions.blur-my-shell.overrideAttrs {
            version = "72";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/blur-my-shellaunetx.v72.shell-extension.zip";
              hash = "sha256-FksFL8N8vSJ2oy/rJuNqyJgorls7YIP2fPnR28Dmd5g=";
              stripRoot = false;
            };
          };
          burn-my-windows = prev.gnomeExtensions.burn-my-windows.overrideAttrs {
            version = "48";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/burn-my-windowsschneegans.github.com.v48.shell-extension.zip";
              hash = "sha256-iwg7dbpV4PVif2QL1UPl6oQaeITgluvUOfLyPpzUaK8=";
              stripRoot = false;
            };
          };
          tiling-shell = prev.gnomeExtensions.tiling-shell.overrideAttrs {
            version = "76";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/tilingshellferrarodomenico.com.v76.shell-extension.zip";
              hash = "sha256-zkMdNXp+B/0Vm03jrIuR8V08KTyZyHV3wJMT24knm+8=";
              stripRoot = false;
            };
          };
          random-wallpaper = prev.gnomeExtensions.random-wallpaper.overrideAttrs {
            version = "39";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/randomwallpaperiflow.space.v39.shell-extension.zip";
              hash = "sha256-r6lsaCYimAlc3TeAqbsoEVt3kmemzHOfzbwF0caHH40=";
              stripRoot = false;
            };
          };
          pip-on-top = prev.gnomeExtensions.pip-on-top.overrideAttrs {
            version = "13";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/pip-on-toprafostar.github.com.v13.shell-extension.zip";
              hash = "sha256-nMnFccclVuSZJN6kNBNUCPBxpTf87XM69JEjfLtKY9k=";
              stripRoot = false;
            };
          };
          lilypad = prev.gnomeExtensions.lilypad.overrideAttrs {
            version = "17";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/lilypadshendrew.github.io.v17.shell-extension.zip";
              hash = "sha256-w03i2WIMw/iJCohMm7sPBIjsUAius6mFawD/ddpuq2c=";
              stripRoot = false;
            };
          };
          updated-vlan-switcher = prev.gnomeExtensions.updated-vlan-switcher.overrideAttrs {
            version = "6";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/updated-vlan-switcherjrvolt.github.io.v6.shell-extension.zip";
              hash = "sha256-PZdgHKYKuldartyr/JIzOOFjm+sWRzl7Tu9e+NfBNGc=";
              stripRoot = false;
            };
          };
          user-themes = prev.gnomeExtensions.user-themes.overrideAttrs {
            version = "76";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/user-themegnome-shell-extensions.gcampax.github.com.v76.shell-extension.zip";
              hash = "sha256-+c0++eMzdfJFQ1r6IcFLIKXAiXC5yhO3dba5wRXH89g=";
              stripRoot = false;
            };
          };
          dash-to-panel = prev.gnomeExtensions.dash-to-panel.overrideAttrs {
            version = "73";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v73.shell-extension.zip";
              hash = "sha256-85Jw4tUa/kVzSvfmHdfI8IM+rUZZ0YnLuLU9U7FJl98=";
              stripRoot = false;
            };
          };
          alphabetical-app-grid = prev.gnomeExtensions.alphabetical-app-grid.overrideAttrs {
            version = "44";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/AlphabeticalAppGridstuarthayhurst.v44.shell-extension.zip";
              hash = "sha256-+23tm8xd1Y4n6VRU8lriFL/VVUcgwA78MhcSXWRHzcw=";
              stripRoot = false;
            };
          };
          appindicator = prev.gnomeExtensions.appindicator.overrideAttrs {
            version = "64";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/appindicatorsupportrgcjonas.gmail.com.v64.shell-extension.zip";
              hash = "sha256-OR4OuxgQam8YCX6k0kIN1BDxUtOTHtUcXz+sKtdDsug=";
              stripRoot = false;
            };
          };
          weather-oclock = prev.gnomeExtensions.weather-oclock.overrideAttrs {
            version = "25";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/weatheroclockCleoMenezesJr.github.io.v25.shell-extension.zip";
              hash = "sha256-Bmo4S6f/IgBTvCLpY7TaFnUMausHKsuTdWdNpbb/nv4=";
              stripRoot = false;
            };
          };
          caffeine = prev.gnomeExtensions.caffeine.overrideAttrs {
            version = "60";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/caffeinepatapon.info.v60.shell-extension.zip";
              hash = "sha256-yydJz3OBsH9xvWaie1+kaALnC3vlf+UN1qRrZjWPMvk=";
              stripRoot = false;
            };
          };
          color-picker = prev.gnomeExtensions.color-picker.overrideAttrs {
            version = "49";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/color-pickertuberry.v49.shell-extension.zip";
              hash = "sha256-CfDj1fehj6ejADHGQd/mgS4ujEg6AVzoffoGZZ9FxKs=";
              stripRoot = false;
            };
          };
          brightness-control-using-ddcutil = prev.gnomeExtensions.brightness-control-using-ddcutil.overrideAttrs {
            version = "59";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/display-brightness-ddcutilthemightydeity.github.com.v59.shell-extension.zip";
              hash = "sha256-HrdR/2WLtDMeSMuIbmt6I942AnvDWAEfxCVtDlPbUfQ=";
              stripRoot = false;
            };
          };
        };
    };
  };
}
