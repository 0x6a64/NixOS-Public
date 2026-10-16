# Single knob for DE switching; each de/*.nix activates itself via gearhead.desktop
{lib, ...}: {
  imports = [
    ./gnome.nix
    ./kde.nix
    ./cosmic.nix
  ];

  options.gearhead.desktop = lib.mkOption {
    type = lib.types.enum ["gnome" "kde" "cosmic"];
    default = "gnome";
    description = "Which desktop environment to enable. Home-manager modules read this via osConfig.";
  };
}
