# KDE Plasma 6 config
{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.gearhead.desktop == "kde") {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      wayland.compositor = "kwin"; # Use kwin instead of weston for the greeter
    };
    services.desktopManager.plasma6.enable = true;

    security = {
      # Auto-unlocks the default KDE wallet at login when its password matches
      # the login password; otherwise KDE prompts separately.
      pam = {
        services = {
          user = {
            kwallet = {
              enable = true;
              package = pkgs.kdePackages.kwallet-pam;
            };
          };
        };
      };
    };

    environment.systemPackages = with pkgs; [
      kdePackages.kio-gdrive
      kdePackages.kio-fuse
      kdePackages.kdenetwork-filesharing
      kdePackages.kdegraphics-thumbnailers
      kdePackages.kdeconnect-kde
      kdePackages.kio-extras
      kdePackages.kio-admin
      kdePackages.kio
      kdePackages.kaccounts-providers
      kdePackages.kdepim-addons
      kdePackages.kzones
      kdePackages.plasma-thunderbolt
      kdePackages.plasma-browser-integration
      kdePackages.ksshaskpass
      kdePackages.kio-zeroconf
      plasma-panel-colorizer
    ];
  };
}
