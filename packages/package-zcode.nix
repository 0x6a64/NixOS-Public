{pkgs}: let
  pname = "zcode";
  version = "3.16.2";
  src = pkgs.fetchurl {
    url = "https://cdn-zcode.z.ai/zcode/electron/releases/${version}/linux-x64/ZCode-${version}-linux-x64.AppImage";
    hash = "sha256-gj88AkqsU4rIeXYFU5pACwajk+uiUQzBT6pYK5fm/Zg=";
  };
  contents = pkgs.appimageTools.extract {inherit pname version src;};
in
  pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm444 ${contents}/zcode.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/zcode.desktop \
        --replace-fail 'Exec=AppRun --no-sandbox' 'Exec=zcode'
      cp -r ${contents}/usr/share/icons $out/share
    '';

    meta = {
      description = "Z.ai ZCode desktop coding agent";
      homepage = "https://z.ai";
      license = pkgs.lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      mainProgram = "zcode";
    };
  }
