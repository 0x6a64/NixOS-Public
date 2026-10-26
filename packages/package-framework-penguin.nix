{
  pkgs,
  lib,
  colors,
}:
pkgs.stdenvNoCC.mkDerivation {
  pname = "plymouth-theme-framework-penguin";
  version = "0-unstable-2026-08-27";

  src = pkgs.fetchFromGitHub {
    owner = "ygurin";
    repo = "framework-penguin";
    rev = "13c0295d65b0ce45116decdc69fadf4679c7d9a7";
    hash = "sha256-GrfUZyhyWXfJHSjFxv7LA7OQmiRaWEyvVzR16RO2PUM=";
  };

  nativeBuildInputs = [pkgs.imagemagick];

  dontBuild = true;
  dontConfigure = true;

  # Recolors upstream's Fedora-blue password box to the stylix palette; the throbber frames
  # have an opaque black fill baked in, so a non-black background shows a square around them
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/plymouth/themes/framework-penguin
    cp -r frames *.png *.script *.plymouth $out/share/plymouth/themes/framework-penguin/
    cd $out/share/plymouth/themes/framework-penguin

    convert ${pkgs.nixos-icons}/share/icons/hicolor/128x128/apps/nix-snowflake-white.png \
      -resize x48 \
      watermark.png

    for f in entry.png lock.png; do
      convert "$f" \
        -fuzz 20% -fill "${colors.withHashtag.base02}" -opaque "#363a3d" \
        -fuzz 15% -fill "${colors.withHashtag.base0D}" -opaque "#1b6acb" \
        "$f"
    done
    convert lock.png -fuzz 15% -fill "${colors.withHashtag.base05}" -opaque "#c0c0c0" lock.png
    convert bullet.png -fuzz 10% -fill "${colors.withHashtag.base0D}" -opaque "#eeeeec" bullet.png

    substituteInPlace framework-penguin.script \
      --replace-fail 'Image.Text(prompt_text, 1, 1, 1)' \
        'Image.Text(prompt_text, ${colors.base05-dec-r}, ${colors.base05-dec-g}, ${colors.base05-dec-b})' \
      --replace-fail 'Image.Text(entry_text, 1, 1, 1)' \
        'Image.Text(entry_text, ${colors.base05-dec-r}, ${colors.base05-dec-g}, ${colors.base05-dec-b})' \
      --replace-fail 'Image.Text(text, 1, 1, 1)' \
        'Image.Text(text, ${colors.base05-dec-r}, ${colors.base05-dec-g}, ${colors.base05-dec-b})'

    substituteInPlace framework-penguin.plymouth \
      --replace-fail /usr/share/plymouth $out/share/plymouth
    runHook postInstall
  '';

  meta = with lib; {
    description = "Plymouth boot screen with Framework's ASCII-art penguin animation, restyled to the stylix palette for LUKS password entry";
    homepage = "https://github.com/ygurin/framework-penguin";
    license = [licenses.mit licenses.gpl2Plus]; # script/theme MIT; bundled spinner icons GPL-2.0-or-later; see upstream LICENSES.md
    platforms = platforms.linux;
    maintainers = [];
  };
}
