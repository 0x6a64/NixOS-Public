# Stylix Theme - Test
{
  pkgs,
  lib,
  ...
}: let
  scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
in {
  stylix = {
    enable = true;
    autoEnable = true;

    targets.gnome.enable = true;
    targets.gtk.enable = true;

    # Solid color background using base02
    image = pkgs.runCommand "solid-color-background.png" {} ''
      COLOR=$(${lib.getExe pkgs.yq} -r .palette.base02 ${scheme})
      ${lib.getExe pkgs.imagemagick} -size 1x1 xc:$COLOR $out
    '';

    # Use a verified color scheme
    base16Scheme = scheme;

    # base16Scheme = {
    #   system = "base16";
    #   name = "Gearhead";
    #   author = "John Dorion";
    #   variant = "dark";

    #   # base0D = "c88800"; #c88800 - best color
    #   palette = {
    #     base00 = "1F1F28"; # 1F1F28
    #     base01 = "16161D"; # 16161D
    #     base02 = "223249"; # 223249
    #     base03 = "54546D"; # 54546D
    #     base04 = "727169"; # 727169
    #     base05 = "DCD7BA"; # DCD7BA
    #     base06 = "C8C093"; # C8C093
    #     base07 = "717C7C"; # 717C7C
    #     base08 = "C34043"; # C34043
    #     base09 = "FFA066"; # FFA066
    #     base0A = "C0A36E"; # C0A36E
    #     base0B = "76946A"; # 76946A
    #     base0C = "6A9589"; # 6A9589
    #     base0D = "7E9CD8"; # 7E9CD8
    #     base0E = "957FB8"; # 957FB8
    #     base0F = "D27E99"; # D27E99
    #   };
    # };

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
        # package = pkgs.dejavu_fonts;
        # name = "DejaVu Serif";
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };

      sansSerif = {
        # package = pkgs.adwaita-fonts;
        # name = "Adwaita Sans";
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };

      monospace = {
        # package = pkgs.nerd-fonts.adwaita-mono;
        # name = "AdwaitaMono Nerd Font Mono";
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
