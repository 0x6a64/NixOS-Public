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

  # Desktop environment selector; de/*.nix and home-manager modules key off this
  gearhead.desktop = "gnome";

  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/disk/by-partlabel/luks";
      allowDiscards = true;
    };
  };

  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;

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
    # TPM2 LUKS auto-unlock via systemd-pcrlock; requires configurationLimit <= 8 (below)
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
  # Marks a boot good; without it the tries counter never resets and the system
  # rolls back after 3 boots regardless of health.
  systemd.services.systemd-bless-boot.wantedBy = ["multi-user.target"];
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
  ];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    accept-flake-config = true;
    netrc-file = config.sops.templates."github-netrc".path;
    warn-dirty = false;
    # Trust these caches at the system level so the daemon uses them for any
    # user (john isn't a trusted-user, so the flake's nixConfig is ignored).
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

  # Sets NH_FLAKE for the rebuild/update aliases in home.nix
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

  # Pin the flake registry and legacy <nixpkgs> to this system's locked nixpkgs
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.nixPath = ["nixpkgs=flake:nixpkgs"];

  # Channels are unused on this pure-flake system
  nix.channel.enable = false;

  # command-not-found queries a channel database that doesn't exist here
  programs.command-not-found.enable = false;

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

    # Rendered netrc file used by the nix daemon to authenticate against GitHub
    templates."github-netrc" = {
      content = ''
        machine github.com
        login token
        password ${config.sops.placeholder.github-token}
      '';
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  networking.hostName = "nixos-framework";

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # 50% of RAM compressed = ~100-150% effective with 2-3x compression
    priority = 100;
  };

  services.power-profiles-daemon.enable = true;
  services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";
  services.logind.settings.Login.HandlePowerKey = "hibernate";
  services.logind.settings.Login.HandlePowerKeyLongPress = "poweroff";

  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "1h";
    SuspendState = "mem";
  };

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

  # LUKS auto-unlocks via TPM, so GDM asks for a real password — which also
  # lets pam_gnome_keyring unlock the keyring.
  services.displayManager.autoLogin.enable = false;

  services.fprintd.enable = true;
  # gdm-fingerprint runs as its own PAM conversation, parallel to gdm-password
  # at the greeter, so gating it here never touches the password fallback.
  # fprintd can't hand pam_gnome_keyring a password, so a fingerprint-only
  # first login of a boot would leave the keyring stuck locked; requiring
  # password there instead lets it unlock normally. Once that session exists,
  # fingerprint is fine for the lock screen — the keyring's already unlocked.
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
      cbonsai
      cmatrix
      clock-rs
      cowsay
      dconf2nix
      ddcutil
      dysk
      fastfetch
      figlet
      fortune
      glow
      gtrash
      lolcat
      lsd
      nmap
      pipes-rs
      pond
      nvtopPackages.intel
      ripgrep
      sbctl
      sops
      taskwarrior3
      timg
      toilet
      topgrade
      tree
      wget
      wl-clipboard

      # archives
      p7zip
      unzip
      xz
      zip

      # Development Tools
      alejandra
      ansible
      azure-cli
      bicep
      docker-compose
      jq
      nil
      nixd
      opencode
      powershell
      ptyxis
      shellcheck
      # nixpkgs pins winboat to EOL electron_40; build it against supported electron_41
      #winboat.

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
      aspellDicts.en-computers
      aspellDicts.en-science
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

  # i2c for ddcutil (brightness-control-using-ddcutil extension); the ddccontrol
  # module is off — its ddcci-driver kernel module fails to build on 7.2
  hardware.i2c.enable = true;
  services.udev.packages = with pkgs; [
    ddcutil
    via
    vial
  ];

  # Adjust PAM to have fprintd come after pam_unix
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

  # Lanzaboote inherits this; capped at 8 because systemd-pcrlock can't build a
  # policy for more generations (https://github.com/systemd/systemd/issues/41526).
  boot.loader.systemd-boot.configurationLimit = 8;

  # Release whose stateful-data defaults this system took; leave at first-install version
  system.stateVersion = "25.05";
}
