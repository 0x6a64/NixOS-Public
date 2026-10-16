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

  # NixOS activation runs before userborn creates the accounts, so a /persist
  # directory first created during a *boot-time* activation fails its chown
  # ("chown: invalid user: 'john:users'") and is left root:root, breaking whatever
  # owns it. Switch-time activation is fine because the user exists by then, so
  # this only bites `update` (nh os boot) followed by a reboot. Repair it once
  # userborn has run and before any session can start.
  systemd.services.persist-home-ownership = {
    description = "Repair /persist/home/user ownership missed by boot-time activation";
    wantedBy = ["multi-user.target"];
    after = ["userborn.service" "local-fs.target"];
    before = ["systemd-user-sessions.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    # Depth-limited on purpose: every declared persist path is at most 5 levels
    # deep, and this stats 72k entries (~60ms) instead of the full tree's 274k.
    script = ''
      ${pkgs.findutils}/bin/find /persist/home/user -maxdepth 6 ! -user john \
        -exec ${pkgs.coreutils}/bin/chown john:users {} +
    '';
  };
  programs.fuse.userAllowOther = true; # Needed for home-manager's impermanence allowOther option to work

  # Disable sudo lecture (it would appear on every cold boot otherwise)
  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';
}
