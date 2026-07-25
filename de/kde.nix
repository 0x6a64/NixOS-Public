# KDE Plasma 6 config
{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.gearhead.desktop == "kde") {
    #Activates Plasma
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      wayland.compositor = "kwin"; # Use kwin instead of weston for the greeter
    };
    services.desktopManager.plasma6.enable = true;

    security = {
      # If enabled, pam_wallet will attempt to automatically unlock the user’s default KDE wallet upon login.
      # If the user has no wallet named “kdewallet”, or the login password does not match their wallet password,
      # KDE will prompt separately after login.
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

    # KDE Specific Packages
    environment.systemPackages = with pkgs; [
      # KDE Apps
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
