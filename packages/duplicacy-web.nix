{
  pkgs,
  config,
  lib,
  ...
}: let
  duplicacy-web = pkgs.callPackage ./package-duplicacy.nix {inherit pkgs lib;};
in {
  environment.systemPackages = [
    duplicacy-web
  ];

  # Install systemd service
  systemd.services."duplicacy-web" = {
    enable = true;
    wants = ["network-online.target"];
    after = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    description = "Start the Duplicacy backup service and web UI";
    serviceConfig = {
      Type = "simple";
      User = "user";
      Group = "users";
      ExecStart = "${duplicacy-web}/bin/duplicacy-web";
      Restart = "on-failure";
      RestartSec = 10;
      KillMode = "process";
      Environment = "HOME=${config.users.users.user.home}";
    };
  };
}
