{
  pkgs,
  config,
  ...
} @ args: let
  scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
  # In home-manager: use osConfig. In NixOS: use config directly.
  systemConfig = args.osConfig or config;
  isGnome = (systemConfig.gearhead.desktop or null) == "gnome";
in {
  stylix = {
    enable = true;
    autoEnable = true;

    targets.gnome.enable = isGnome;
    targets.gtk.enable = true;

    # Default wallpaper (random-wallpaper extension may replace it at runtime)
    image = ./dots/wallpaper.jpg;

    base16Scheme = scheme;

    polarity = "dark";

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };

    opacity = {
      applications = 0.80;
      desktop = 0.80;
      popups = 0.80;
      terminal = 0.80;
    };

    fonts = {
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };

      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };

      monospace = {
        package = pkgs.nerd-fonts.noto;
        name = "NotoMono Nerd Font";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 12;
        desktop = 11;
        terminal = 11;
        popups = 10;
      };
    };
  };
}
