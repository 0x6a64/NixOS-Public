{pkgs, ...}: let
  rootExplosion = ''
    echo "Time to 🧨" >/dev/kmsg
    mkdir /btrfs_tmp
    mount -t btrfs -o subvol=/ /dev/mapper/cryptroot /btrfs_tmp

    if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/persist/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%d_%H:%M:%S")
        if [[ ! -e /btrfs_tmp/persist/old_roots/$timestamp ]]; then
          mv /btrfs_tmp/root "/btrfs_tmp/persist/old_roots/$timestamp"
        else
          btrfs subvolume delete /btrfs_tmp/root
        fi
    fi

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
  boot.initrd.systemd = {
    extraBin = {
      grep = "${pkgs.gnugrep}/bin/grep";
    };
    services = {
      root-explode = {
        enableStrictShellChecks = false;
        wantedBy = ["initrd-root-device.target"];
        after = ["systemd-cryptsetup@cryptroot.service" "local-fs-pre.target"];
        before = ["sysroot.mount"];
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
      "/etc/nixos"
      "/etc/NetworkManager/system-connections"

      # On the ephemeral root, not /var/lib
      "/var/spool"
      "/root"
    ];

    files = [
      # Used by systemd/journald for logging
      "/etc/machine-id"
    ];
  };

  # home-manager's impermanence module doesn't have permissions to bootstrap these dirs, so we do it here:
  system.activationScripts.bootstrapPersistHome.text = ''
    mkdir -p /persist/home/user
    chown -R user:users /persist/home/user
    chmod 0700 /persist/home/user
  '';

  # Boot-time activation runs before userborn, so new /persist dirs stay root:root; repair after userborn (see CLAUDE.md)
  systemd.services.persist-home-ownership = {
    description = "Repair /persist/home/user ownership missed by boot-time activation";
    wantedBy = ["multi-user.target"];
    after = ["userborn.service" "local-fs.target"];
    before = ["systemd-user-sessions.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    # Depth-limited on purpose: persist paths are at most 5 deep, a full walk is 4x the entries
    script = ''
      ${pkgs.findutils}/bin/find /persist/home/user -maxdepth 6 ! -user user \
        -exec ${pkgs.coreutils}/bin/chown user:users {} +
    '';
  };
  programs.fuse.userAllowOther = true; # needed for HM impermanence allowOther

  # Otherwise the sudo lecture shows on every cold boot
  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';
}
