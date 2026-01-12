# Disko configuration for LUKS-encrypted btrfs with impermanence subvolumes
# Supports hibernation by using a dedicated swapfile subvolume with nodatacow
{
  disko.devices = {
    disk = {
      nvme0n1 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              label = "boot";
              name = "ESP";
              size = "2G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
              };
            };
            luks = {
              size = "100%";
              label = "luks";
              content = {
                type = "luks";
                name = "cryptroot";
                # For installation, use: --argstr diskPassword "yourpassword"
                # Or set passwordFile = "/tmp/secret.key";
                askPassword = true;
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = ["-L" "nixos" "-f"];
                  subvolumes = {
                    # Root subvolume - wiped on cold boot via impermanence
                    # On each boot, this subvolume is moved to /old_roots/<timestamp>
                    # and a fresh empty subvolume is created in its place.
                    # Old roots are kept for 30 days for recovery purposes.
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = ["subvol=root" "compress=zstd" "noatime"];
                    };
                    # /home is part of ephemeral root - user dirs persisted via impermanence
                    # userborn service handles home dir creation timing (after mounts)
                    #
                    # Nix store - persisted
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = ["subvol=nix" "compress=zstd" "noatime"];
                    };
                    # Persistent state directory
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = ["subvol=persist" "compress=zstd" "noatime"];
                    };
                    # System logs - persisted separately for debugging
                    "/log" = {
                      mountpoint = "/var/log";
                      mountOptions = ["subvol=log" "compress=zstd" "noatime"];
                    };
                    # System state (databases, containers, etc.)
                    "/lib" = {
                      mountpoint = "/var/lib";
                      mountOptions = ["subvol=lib" "compress=zstd" "noatime"];
                    };
                    # Swap subvolume for hibernation - requires nodatacow and no compression
                    "/swap" = {
                      mountpoint = "/persist/swap";
                      mountOptions = ["subvol=swap" "noatime" "nodatacow"];
                      swap = {
                        swapfile.size = "48G";
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # These filesystems must be available early in boot for impermanence and logging
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/var/log".neededForBoot = true;
  fileSystems."/var/lib".neededForBoot = true;
}
