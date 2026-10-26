{
  description = "GNOME extensions overlay — remove once nixpkgs auto-update PR lands";

  outputs = {self}: {
    overlays.default = final: prev: {
      gnomeExtensions =
        prev.gnomeExtensions
        // {
          blur-my-shell = prev.gnomeExtensions.blur-my-shell.overrideAttrs {
            version = "76";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/blur-my-shellaunetx.v76.shell-extension.zip";
              hash = "sha256-xMfy4cYuhApH0/vfzkmKhI7YY2hHVnlViGCDFOlYUhI=";
              stripRoot = false;
            };
          };
          burn-my-windows = prev.gnomeExtensions.burn-my-windows.overrideAttrs {
            version = "49";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/burn-my-windowsschneegans.github.com.v49.shell-extension.zip";
              hash = "sha256-OLUXQept3jCJg1obb0AaoZ/mPoV+KS0hIDYyHZiDghg=";
              stripRoot = false;
            };
          };
          tiling-shell = prev.gnomeExtensions.tiling-shell.overrideAttrs {
            version = "77";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/tilingshellferrarodomenico.com.v77.shell-extension.zip";
              hash = "sha256-bsnKsfJc/OB8FEeG9kEGR80urOIcdgvEZQ8JX9Aw7wQ=";
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
            version = "79";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/user-themegnome-shell-extensions.gcampax.github.com.v79.shell-extension.zip";
              hash = "sha256-S6AmyTORagBr498g6SMzEkktHk7Z0XTcBCzU1kQs2LM=";
              stripRoot = false;
            };
          };
          dash-to-panel = prev.gnomeExtensions.dash-to-panel.overrideAttrs {
            version = "74";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v74.shell-extension.zip";
              hash = "sha256-+O2PmqmTNXJUF1OUae3v7tHahQb7ponrVRjEXtSnM4Q=";
              stripRoot = false;
            };
          };
          alphabetical-app-grid = prev.gnomeExtensions.alphabetical-app-grid.overrideAttrs {
            version = "46";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/AlphabeticalAppGridstuarthayhurst.v46.shell-extension.zip";
              hash = "sha256-4DBACytEI5dkYj+IVC4inSIiBqtKfI4xfDPNDlh+hbs=";
              stripRoot = false;
            };
          };
          appindicator = prev.gnomeExtensions.appindicator.overrideAttrs {
            version = "66";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/appindicatorsupportrgcjonas.gmail.com.v66.shell-extension.zip";
              hash = "sha256-RCMGWHEoRPz+kHq7j/Mx7c9DZ4qHv4/z5q443pYBYm0=";
              stripRoot = false;
            };
          };
          weather-oclock = prev.gnomeExtensions.weather-oclock.overrideAttrs {
            version = "26";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/weatheroclockCleoMenezesJr.github.io.v26.shell-extension.zip";
              hash = "sha256-arNbbS2yOu01llWHQkI7+o0UfRcl6Ii+F9PDbOYLcVI=";
              stripRoot = false;
            };
          };
          caffeine = prev.gnomeExtensions.caffeine.overrideAttrs {
            version = "61";
            src = prev.fetchzip {
              url = "https://extensions.gnome.org/extension-data/caffeinepatapon.info.v61.shell-extension.zip";
              hash = "sha256-uidkGTBiGYFu57Lug3OnxO8CKM6C0zI1C+WyHbJItsk=";
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
