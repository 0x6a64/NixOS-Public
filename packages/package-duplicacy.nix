{ pkgs, lib }:

pkgs.stdenv.mkDerivation rec {
	pname = "duplicacy-web";
	version = "1.8.3";

	src = builtins.fetchurl {
		url = "https://acrosync.com/duplicacy-web/duplicacy_web_linux_x64_${version}";
		sha256 = "9cdcaa875ae5fc0fcf93941df3a5133fb3c3ff92c89f87babddc511ba6dd7ef8";
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
		#license = licenses.unfreeRedistributable;	# TODO: For some reason Nix refuses to install unfree packages despite being configured otherwise. Disable for now.
	};
}