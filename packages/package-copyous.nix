{
  pkgs,
  lib,
}: let
  version = "1.3.0";
  uuid = "copyous@boerdereinar.dev";
in
  pkgs.stdenv.mkDerivation {
    pname = "gnome-shell-extension-copyous";
    inherit version;

    src = pkgs.fetchzip {
      url = "https://github.com/boerdereinar/copyous/releases/download/v${version}/copyous%40boerdereinar.dev.zip";
      hash = "sha256-Nq49kM6LcH7tp3AiaiE0M7wbHn16LSMhOHEQq4VFEuo=";
      stripRoot = false;
    };

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/gnome-shell/extensions/${uuid}
      cp -r * $out/share/gnome-shell/extensions/${uuid}/
      runHook postInstall
    '';

    passthru = {
      extensionUuid = uuid;
      extensionPortalSlug = "copyous";
    };

    meta = with lib; {
      description = "Modern Clipboard Manager for GNOME";
      homepage = "https://github.com/boerdereinar/copyous";
      license = licenses.gpl3Plus;
      platforms = platforms.linux;
      maintainers = [];
    };
  }
