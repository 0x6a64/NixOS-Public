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

  # Upstream ships a Fedora-blue LUKS password box (charcoal fill #363a3d,
  # blue border/bullets #1b6acb, silver lock icon #c0c0c0) and a Fedora
  # watermark. Recolor the password box and prompt text to the stylix
  # (kanagawa) palette, driven by `colors`, so a scheme change here follows
  # stylix automatically instead of needing another hand-edit. Background is
  # left untouched (Plymouth's default black) on purpose: the throbber frames
  # (frames/throbber-*.png) are opaque 500x500 images with a pure-black fill
  # baked in — any non-black window background (e.g. stylix's base00, a dark
  # navy) shows up as a visible mismatched square around the animation.
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
