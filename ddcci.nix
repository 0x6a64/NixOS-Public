# DDCCI Driver Configuration
# DDC/CI (Display Data Channel Command Interface) allows software control of monitor settings
# This configuration sets up the ddcci-driver kernel module for controlling external monitors
#
# Note: This file contains the full ddcci driver configuration.
# Basic I2C and ddccontrol setup remains in configuration.nix.
# Uncomment the import in configuration.nix to enable the full driver.
{
  config,
  pkgs,
  ...
}: {
  # Add ddcci_backlight kernel module (i2c-dev is already loaded in configuration.nix)
  boot.kernelModules = [
    "ddcci_backlight" # DDCCI backlight control module
  ];

  # Add ddcci-driver kernel module (with custom overlay below)
  boot.extraModulePackages = [config.boot.kernelPackages.ddcci-driver];

  # udev rules for automatic DDCCI device detection and permissions
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="i2c-dev", ATTR{name}=="AMDGPU DM*", TAG+="ddcci", TAG+="systemd", ENV{SYSTEMD_WANTS}+="ddcci@$kernel.service"
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="ddcci*", RUN+="${pkgs.coreutils-full}/bin/chgrp video /sys/class/backlight/%k/brightness"
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="ddcci*", RUN+="${pkgs.coreutils-full}/bin/chmod a+w /sys/class/backlight/%k/brightness"
  '';

  # Systemd service to attach ddcci devices automatically
  # This service is triggered by udev rules when an i2c device is detected
  systemd.services."ddcci@" = {
    scriptArgs = "%i";
    script = ''
      echo Trying to attach ddcci to $1
      id=$(echo $1 | cut -d "-" -f 2)
      counter=5
      while [ $counter -gt 0 ]; do
        if ${pkgs.ddcutil}/bin/ddcutil getvcp 10 -b $id; then
          echo ddcci 0x37 > /sys/bus/i2c/devices/$1/new_device
          echo Successfully attached ddcci to $1
          break
        fi
        sleep 1
        counter=$((counter - 1))
      done
    '';
    serviceConfig.Type = "oneshot";
  };

  # Overlay to use a patched version of ddcci-driver
  # This fixes compatibility issues with recent kernels
  nixpkgs.overlays = [
    (self: super: {
      linuxPackages_latest = super.linuxPackages_latest.extend (lpself: lpsuper: {
        ddcci-driver = super.linuxPackages_latest.ddcci-driver.overrideAttrs (oldAttrs: {
          version = super.linuxPackages_latest.ddcci-driver.version + "-FIXED";
          src = pkgs.fetchFromGitLab {
            owner = "ddcci-driver-linux";
            repo = "ddcci-driver-linux";
            rev = "0233e1ee5eddb4b8a706464f3097bad5620b65f4";
            hash = "sha256-Osvojt8UE+cenOuMoSY+T+sODTAAKkvY/XmBa5bQX88=";
          };

          patches = [
            (pkgs.fetchpatch {
              name = "ddcci-e0605c9cdff7bf3fe9587434614473ba8b7e5f63.patch";
              url = "https://gitlab.com/nullbytepl/ddcci-driver-linux/-/commit/e0605c9cdff7bf3fe9587434614473ba8b7e5f63.patch";
              hash = "sha256-sTq03HtWQBd7Wy4o1XbdmMjXQE2dG+1jajx4HtwBHjM=";
            })
          ];
        });
      });
    })
  ];
}
