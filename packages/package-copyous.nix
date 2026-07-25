{
  pkgs,
  lib,
}: let
  version = "2.0.1";
  uuid = "copyous@boerdereinar.dev";
in
  pkgs.stdenv.mkDerivation {
    pname = "gnome-shell-extension-copyous";
    inherit version;

    src = pkgs.fetchzip {
      url = "https://github.com/boerdereinar/copyous/releases/download/v${version}/copyous%40boerdereinar.dev.zip";
      hash = "sha256-jTVRjVqJu1g4opZ7G57h9iKg3JZ2qbWp27ZF/VoX0Kw=";
      stripRoot = false;
    };

    nativeBuildInputs = [pkgs.glib];
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
