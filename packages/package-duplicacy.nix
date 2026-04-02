{
  pkgs,
  lib,
}:
pkgs.stdenv.mkDerivation rec {
  pname = "duplicacy-web";
  version = "1.8.3";

  src = pkgs.fetchurl {
    url = "https://acrosync.com/duplicacy-web/duplicacy_web_linux_x64_${version}";
    hash = "sha256-nNyqh1rl/A/Pk5Qd86UTP7PD/5LIn4e6vdxRG6bdfvg=";
  };

  doCheck = false;

  dontUnpack = true;

  installPhase = ''
    install -D $src $out/duplicacy-web
    chmod a+x $out/duplicacy-web
  '';

  meta = with lib; {
    homepage = "https://duplicacy.com";
    description = "A new generation cloud backup tool";
    platforms = platforms.linux ++ platforms.darwin;
    license = licenses.unfree;
  };
}
