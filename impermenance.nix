# General impermanence setup
# Note: specifics should live with their respective modules, where possible!
{
  pkgs,
  ...
}: let
  rootExplosion = ''
    echo "Time to 🧨" >/dev/kmsg
    mkdir /btrfs_tmp
    mount -t btrfs -o subvol=/ /dev/mapper/cryptroot /btrfs_tmp

    # Root impermanence
    if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/persist/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%d_%H:%M:%S")
        if [[ ! -e /btrfs_tmp/persist/old_roots/$timestamp ]]; then
          mv /btrfs_tmp/root "/btrfs_tmp/persist/old_roots/$timestamp"
        else
          btrfs subvolume delete /btrfs_tmp/root
        fi
    fi

    ###
    # GC
    ###
    latest_snapshot=$(find /btrfs_tmp/persist/old_roots/ -mindepth 1 -maxdepth 1 -type d | sort -r | head -n 1)
    # Only delete old snapshots if there's at least one that will remain after deletion
    if [ -n "$latest_snapshot" ]; then
        for i in $(find /btrfs_tmp/persist/old_roots/ -mindepth 1 -maxdepth 1 -mtime +30 | grep -v -e "$latest_snapshot"); do
            btrfs subvolume delete -R "$i"
        done
    fi

    btrfs subvolume create /btrfs_tmp/root
    umount /btrfs_tmp
    echo "Done with 🧨. Au revoir!" >/dev/kmsg
  '';
in {
  # Explode / on every boot and resume, see https://grahamc.com/blog/erase-your-darlings/
  boot.initrd.systemd = {
    extraBin = {
      grep = "${pkgs.gnugrep}/bin/grep";
    };
    services = {
      root-explode = {
        enableStrictShellChecks = false;
        wantedBy = ["initrd-root-device.target"];
        # See https://github.com/nix-community/impermanence/issues/250#issuecomment-2603848867
        after = ["systemd-cryptsetup@cryptroot.service" "local-fs-pre.target"];
        before = ["sysroot.mount"];
        # Run on cold boot only, never on resume from hibernation
        unitConfig = {
          ConditionKernelCommandLine = ["!resume="];
          RequiresMountsFor = ["/dev/mapper/cryptroot"];
        };
        serviceConfig = {
          StandardOutput = "journal+console";
          StandardError = "journal+console";
          Type = "oneshot";
        };
        script = rootExplosion;
      };
    };
  };
  boot.tmp.cleanOnBoot = true;
  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      # System configuration (on ephemeral root, needs persistence)
      "/etc/nixos"
      "/etc/NetworkManager/system-connections"

      # These are on root, not /var/lib
      "/var/spool"

      # Root user home
      "/root"
    ];

    files = [
      # Machine identity (must persist - used by systemd/journald for logging)
      "/etc/machine-id"
    ];
  };
    
    # home-manager's impermanence module doesn't have permissions to bootstrap these dirs, so we do it here:
    system.activationScripts.bootstrapPersistHome.text = ''
      mkdir -p /persist/home/user
      chown -R user:users /persist/home/user
      chmod 0700 /persist/home/user
    '';

    programs.fuse.userAllowOther = true; # Needed for home-manager's impermanence allowOther option to work

  # Disable sudo lecture (it would appear on every cold boot otherwise)
  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';
}
