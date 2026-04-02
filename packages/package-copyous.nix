{
  pkgs,
  lib,
}: let
  version = "2.0.0";
  uuid = "copyous@boerdereinar.dev";
in
  pkgs.stdenv.mkDerivation {
    pname = "gnome-shell-extension-copyous";
    inherit version;

    src = pkgs.fetchzip {
      url = "https://github.com/boerdereinar/copyous/releases/download/v${version}/copyous%40boerdereinar.dev.zip";
      hash = "sha256-AhbB85GlV2LDcbVgs36d8KlChJMP011S2Q0bM3P6v3s=";
      stripRoot = false;
    };

    nativeBuildInputs = [pkgs.glib pkgs.wrapGAppsHook3];
    buildInputs = [pkgs.libgda5 pkgs.gsound];

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/gnome-shell/extensions/${uuid}
      cp -r * $out/share/gnome-shell/extensions/${uuid}/

      if [ -d "$out/share/gnome-shell/extensions/${uuid}/schemas" ]; then
        glib-compile-schemas $out/share/gnome-shell/extensions/${uuid}/schemas
      fi
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
