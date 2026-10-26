{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./impermanence.nix
    ./network.nix
    ./packages/duplicacy-web.nix
    ./stylix.nix
    ./de
  ];

  nixos-framework.desktop = "gnome";

  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/disk/by-partlabel/luks";
      allowDiscards = true;
    };
  };

  boot.loader.efi.canTouchEfiVariables = true;

  # Lanzaboote doesn't work for initial install bc key bundle doesn't exist yet.
  # BEGIN_NIXOS_BOOT_SYSTEMD_BOOT
  # boot.loader.systemd-boot = {
  # enable = true;
  # consoleMode = lib.mkDefault "max";
  # };
  # END_NIXOS_BOOT_SYSTEMD_BOOT

  # BEGIN_NIXOS_BOOT_LANZABOOTE
  boot.loader.systemd-boot.enable = lib.mkForce false;
  # "max" is full-screen but blurry; every crisp value letterboxes instead
  boot.loader.systemd-boot.consoleMode = lib.mkDefault "max";
  # Menu still opens on a keypress; bootCounting below handles failure recovery
  boot.loader.timeout = 0;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    # TPM2 LUKS auto-unlock via systemd-pcrlock; requires configurationLimit <= 4 (below)
    measuredBoot = {
      enable = true;
      pcrs = [
        0
        4
        7
      ];
    };
    # Fall back to the last-known-good generation after 3 failed boots
    bootCounting.initialTries = 3;
  };
  # No systemd-bless-boot wantedBy: systemd-bless-boot-generator pulls it in only when boot
  # counting is active; forcing it fails every other boot and makes switches exit 4.
  # END_NIXOS_BOOT_LANZABOOTE

  # Core Ultra Series 3 wants a recent kernel (nixos-hardware floors it at 6.17)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Early KMS so the LUKS prompt uses native resolution; this chip binds "xe", not "i915"
  boot.initrd.kernelModules = ["xe"];

  # Stylix's own Plymouth target would conflict with boot.plymouth.theme below
  stylix.targets.plymouth.enable = false;
  boot.plymouth = {
    enable = true;
    theme = "framework-penguin";
    themePackages = [(pkgs.callPackage ./packages/package-framework-penguin.nix {colors = config.lib.stylix.colors;})];
  };

  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    "quiet"
    "boot.shell_on_fail"
    "udev.log_priority=3"
    "rd.systemd.show_status=true"
    # PSR flickers the panel with VBT timings; safest params fix it (fallback: xe.enable_psr=0, see CLAUDE.md "Hardware")
    "xe.psr_safest_params=1"
  ];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    warn-dirty = false;
    # System-level so the daemon uses them for any user (user isn't a trusted-user)
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://cache.numtide.com"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  programs.nh = {
    enable = true;
    flake = "/home/user/Nixos";
    # Replaces nix.gc.automatic (the two conflict)
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 5 --keep-since 3d";
    };
  };

  # Scheduled dedup avoids per-build slowdown from auto-optimise-store
  nix.optimise.automatic = true;

  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.nixPath = ["nixpkgs=flake:nixpkgs"];

  nix.channel.enable = false;

  # Prebuilt nix-index database: flake-friendly command-not-found, nix-locate, and `, <cmd>`
  programs.nix-index-database.comma.enable = true;

  # gpg plus an agent with GNOME's pinentry; SSH stays with HM's ssh-agent
  programs.gnupg.agent.enable = true;

  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/persist/sops-nix/keys.txt";

    secrets.user-password = {
      neededForUsers = true;
    };

    secrets.wallhaven-key = {
      owner = "user";
      mode = "0400";
    };

    secrets.unsplash-key = {
      owner = "user";
      mode = "0400";
    };

    secrets.ssh-key = {
      owner = "user";
      group = "users";
      mode = "0600";
      path = "/home/user/.ssh/default_ssh_25519";
    };

    secrets.github-token = {
      owner = "user";
      mode = "0400";
    };

    # Flake locking runs in the client, so user must be able to read it (root still can)
    templates."nix-access-tokens" = {
      content = ''
        access-tokens = github.com=${config.sops.placeholder.github-token}
      '';
      owner = "user";
      mode = "0400";
    };
  };

  # `!include` skips a missing file, so nix still works before sops renders it
  nix.extraOptions = ''
    !include ${config.sops.templates."nix-access-tokens".path}
  '';

  networking.hostName = "nixos-framework";

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  # Prefer compressing anon pages into zram over evicting page cache
  boot.kernel.sysctl."vm.swappiness" = 180;
  # zram has no seek cost, so swap-in readahead only wastes decompression
  boot.kernel.sysctl."vm.page-cluster" = 0;
  # SysRq bitmask: 4 SAK/unraw, 8 dumps, 16 sync, 32 remount-ro, 128 reboot
  boot.kernel.sysctl."kernel.sysrq" = 188;

  services.power-profiles-daemon.enable = true;
  services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";
  services.logind.settings.Login.HandlePowerKey = "hibernate";
  services.logind.settings.Login.HandlePowerKeyLongPress = "poweroff";

  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "1h";
  };

  # GNOME idle-suspend has no suspend-then-hibernate option, so route every plain suspend through it
  systemd.services.systemd-suspend.serviceConfig.ExecStart = [
    ""
    "${config.systemd.package}/lib/systemd/systemd-sleep suspend-then-hibernate"
  ];

  # btintel_pcie can wedge on D3 entry (-EBUSY), aborting every later suspend/hibernate; unload it across sleep
  # Also unmount the ESP (automount brings it back) so a resume never meets a stale FAT cache; see CLAUDE.md "ESP corruption"
  # Skipped at shutdown: post-boot.service runs these too and is ordered after boot.mount, so a blocking stop deadlocks for 90s
  powerManagement.powerDownCommands = ''
    ${pkgs.kmod}/bin/modprobe -r btintel_pcie || true
    if [ "$(${config.systemd.package}/bin/systemctl is-system-running || true)" != stopping ]; then
      ${config.systemd.package}/bin/systemctl stop boot.mount || true
    fi
  '';
  # FLR first: a controller left mid-state by the hibernate leg fires an IRQ during probe and oopses the driver
  powerManagement.resumeCommands = ''
    echo 1 > /sys/bus/pci/devices/0000:00:14.7/reset || true
    ${pkgs.kmod}/bin/modprobe btintel_pcie
  '';

  # Adjust permissions without creating an empty file that would break sops
  systemd.tmpfiles.rules = [
    "z ${config.sops.age.keyFile} 0640 root root -"
  ];

  # Creates home dirs after mounts are in place, unlike the activation script (nixpkgs#6481)
  services.userborn.enable = true;

  services.hardware.bolt.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      cups-filters
      cups-browsed
    ];
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };

    spiceUSBRedirection.enable = true;

    docker = {
      enable = true;
      rootless = {
        enable = false; # Disabled - winboat requires non-rootless Docker
      };
      storageDriver = "btrfs";
    };
  };
  programs.virt-manager.enable = true;

  users.mutableUsers = false;
  users.users.user = {
    isNormalUser = true;
    description = "User";
    hashedPasswordFile = config.sops.secrets.user-password.path;
    extraGroups = [
      "docker"
      "i2c"
      "libvirtd"
      "networkmanager"
      "video"
      "wheel"
    ];
    shell = pkgs.zsh;
  };

  services.claude-cowork.enable = true;

  programs.zsh.enable = true;

  # A real GDM password (not autologin) lets pam_gnome_keyring unlock the keyring
  services.displayManager.autoLogin.enable = false;

  services.fprintd.enable = true;
  # fprintd can't unlock the keyring, so require a password at the first login of a boot
  security.pam.services.gdm-fingerprint.rules.auth.session-exists = {
    control = "requisite";
    modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
    args = [
      "quiet"
      "${pkgs.writeShellScript "gdm-fingerprint-session-guard" ''
        uid=$(${pkgs.coreutils}/bin/id -u "$PAM_USER") || exit 1
        test -S "/run/user/$uid/wayland-0"
      ''}"
    ];
    order = config.security.pam.services.gdm-fingerprint.rules.auth.shells.order - 1;
  };

  services.btrfs.autoScrub.enable = true;

  # setcap wrapper so mtr's raw sockets work without sudo
  programs.mtr.enable = true;

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages =
    (with pkgs; [
      # CommandLine Utilities
      age
      bc
      binutils # strings, objdump, readelf
      cbonsai
      cmatrix
      clock-rs
      cowsay
      dconf2nix
      ddcutil
      dos2unix
      dysk
      entr
      fastfetch
      fd
      figlet
      file
      fortune
      gettext # envsubst
      glow
      gtrash
      inotify-tools
      lolcat
      lsd
      ncdu
      nix-tree
      nmap
      pipes-rs
      pond
      psmisc # killall, pstree, fuser
      pv
      nvtopPackages.intel
      ripgrep
      sbctl
      sops
      sqlite
      sysstat # iostat, sar, mpstat
      taskwarrior3
      timg
      tmux
      toilet
      topgrade
      tree
      wget
      whois
      wl-clipboard
      xxd
      yq-go

      # archives
      p7zip
      unzip
      xz
      zip

      # Development Tools
      alejandra
      ansible
      # azure-cli # broken: python3Packages.fabric (nixpkgs#575989)
      bicep
      docker-compose
      jq
      nil
      nixd
      opencode
      opencode-claude-auth
      powershell
      ptyxis
      shellcheck
      (pkgs.callPackage ./packages/package-zcode.nix {})
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.kimi-code
      winboat

      # Hardware & Diagnostics
      dmidecode
      dnsutils # dig, nslookup
      ethtool
      inxi
      iotop
      iperf3
      iw
      lm_sensors # sensors
      lshw
      lsof
      pciutils # lspci
      powertop
      smartmontools # smartctl
      tcpdump
      traceroute
      usbutils # lsusb

      # System Utilities
      bibata-cursors
      bibata-cursors-translucent
      dconf-editor
      duplicacy
      frog
      fprintd
      gnome-boxes
      menulibre
      oreo-cursors-plus
      qmk
      qmk_hid

      # My Apps
      chromium
      discord
      discordo
      evince
      libreoffice-stable
      pinta
      plexamp
      signal-desktop
      teams-for-linux
      (pkgs.wrapOBS {
        plugins = with pkgs.obs-studio-plugins; [
          droidcam-obs
          obs-backgroundremoval
          obs-gstreamer
          obs-pipewire-audio-capture
          obs-vaapi # hardware video encode via Intel VAAPI (iHD)
          obs-vkcapture
          wlrobs
          droidcam-obs
        ];
      })

      #Dictionary
      aspell
      aspellDicts.en
      hunspell
      hunspellDicts.en_US
    ])
    ++ [
      inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

  fonts.packages = with pkgs; [
    nerd-fonts.ubuntu
    nerd-fonts.ubuntu-mono
    nerd-fonts.adwaita-mono
    nerd-fonts.droid-sans-mono
    meslo-lgs-nf
    corefonts
    vista-fonts
  ];

  environment.sessionVariables = {
    SOPS_AGE_KEY_FILE = config.sops.age.keyFile;
    # Stops az from downloading its own bicep into ~/.azure/bin
    AZURE_BICEP_USE_BINARY_FROM_PATH = "true";
  };

  programs.obs-studio.enableVirtualCamera = true;

  programs.steam.enable = true;

  hardware.fw-fanctrl.enable = true;
  services.fwupd.enable = true;

  hardware.keyboard.qmk.enable = true;

  # i2c for ddcutil (brightness extension); ddccontrol stays off, its kernel module fails to build
  hardware.i2c.enable = true;
  services.udev.packages = with pkgs; [
    ddcutil
    via
    vial
  ];

  security.pam.services.sudo.rules.auth.unix.order =
    config.security.pam.services.sudo.rules.auth.fprintd.order - 1;
  security.pam.services.polkit-1.rules.auth.unix.order =
    config.security.pam.services.polkit-1.rules.auth.fprintd.order - 1;

  networking.firewall.allowedTCPPortRanges = [
    # KDE Connect
    {
      from = 1714;
      to = 1764;
    }
  ];
  networking.firewall.allowedUDPPortRanges = [
    # KDE Connect
    {
      from = 1714;
      to = 1764;
    }
  ];

  # Lanzaboote inherits this; pcrlock can't build a policy for more (https://github.com/systemd/systemd/issues/41526)
  boot.loader.systemd-boot.configurationLimit = 4;

  system.stateVersion = "25.05";
}
