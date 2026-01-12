{ pkgs, config, lib, cfg, ... }:

let
	duplicacy-web = pkgs.callPackage ./package-duplicacy.nix { inherit pkgs lib; };
in
rec {
	environment.systemPackages = [
		duplicacy-web
	];

	# Install systemd service
	systemd.services."duplicacy-web" = {
		enable = true;
		wants = [ "network-online.target" ];
		after = [ "syslog.target" "network-online.target" ];
        wantedBy = ["default.target"];
		description = "Start the Duplicacy backup service and web UI";
		serviceConfig = {
			Type = "simple";
			ExecStart = ''${duplicacy-web}/duplicacy-web''; 
			Restart = "on-failure";
			RestartSrc = 10;
			KillMode = "process";
			Environment = "HOME=${config.users.users.user.home}";
		};
	};
}
