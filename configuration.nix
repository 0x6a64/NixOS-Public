{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    # ./ddcci.nix
    ./disko.nix
    ./flatpak.nix
    ./hardware-configuration.nix
    ./impermanence.nix
    ./network.nix
    ./packages/duplicacy-web.nix
    ./stylix.nix
    ./de/gnome.nix
    #./de/kde.nix
    #./de/cosmic.nix
  ];

  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/disk/by-partlabel/luks";
      allowDiscards = true;
    };
  };

  # Bootloader
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;

  # Lanzaboote doesn't work for initial install bc key bundle doesn't exist yet.
  # BEGIN_NIXOS_BOOT_SYSTEMD_BOOT
  # boot.loader.systemd-boot = {
  # enable = true;
  # consoleMode = lib.mkDefault "max";
  # };
  # END_NIXOS_BOOT_SYSTEMD_BOOT

  # Secure Boot with Lanzaboote
  # BEGIN_NIXOS_BOOT_LANZABOOTE
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.systemd-boot.consoleMode = lib.mkDefault "max";
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
  # END_NIXOS_BOOT_LANZABOOTE

  boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  # Set modprobe options for audio popping issue
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0
  '';

  # Set up Plymouth
  boot.plymouth.enable = false;
  # boot.plymouth.theme = "cuts_alt";
  # boot.plymouth.themePackages = with pkgs; [
  #   # By default we would install all themes
  #   # Check for options https://github.com/NixOS/nixpkgs/blob/7241bcbb4f099a66aafca120d37c65e8dda32717/pkgs/by-name/ad/adi1090x-plymouth-themes/shas.nix
  #   (adi1090x-plymouth-themes.override {
  #     selected_themes = [ "cuts_alt" ];
  #   })
  # ];
  stylix.targets.plymouth.enable = false;

  # Enable "Silent boot"
  boot.consoleLogLevel = 3;
  # boot.initrd.verbose = true;  # Show detailed boot messages
  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "udev.log_priority=3"
    "rd.systemd.show_status=true"
    "plymouth.use-simpledrm"
  ];

  # Nix Settings
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    accept-flake-config = true;
    auto-optimise-store = true;
  };

  # Nix-Sops - System level configuration
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
  };

  # Networking
  networking.hostName = "nixos-framework"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # 50% of RAM compressed = ~100-150% effective with 2-3x compression
    priority = 100; # Higher priority = used first
  };

  services.power-profiles-daemon.enable = true;
  # Suspend first then hibernate when closing the lid
  services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
  # Hibernate on power button pressed
  services.logind.settings.Login.HandlePowerKey = "hibernate";
  services.logind.settings.Login.HandlePowerKeyLongPress = "poweroff";

  # Define time delay for hibernation
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';

  # Ensure sops age key file has correct permissions
  systemd.tmpfiles.rules = [
    "f ${config.sops.age.keyFile} 0640 root root"
  ];

  # Use userborn for user/group management (runs as systemd service, not activation script)
  # This fixes timing issues with impermanence - home dirs are created AFTER mounts are in place
  # See: https://github.com/NixOS/nixpkgs/issues/6481
  services.userborn.enable = true;

  # Enable Thunderbolt support
  services.hardware.bolt.enable = true;

  # Enable Printing
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

  # Enable virtualization/docker
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
        setSocketVariable = true;
      };
      storageDriver = "btrfs";
    };
  };
  programs.virt-manager.enable = true;

  # Enable sound with pipewire - Limiting profiles due to GVC crashes with HFP/HSP
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    wireplumber = {
      enable = true;
      configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/51-bluetooth-fixes.conf" ''
          monitor.bluez.properties = {
            bluez5.enable-sbc-xq = true
            bluez5.enable-msbc = true
            bluez5.enable-hw-volume = true
            # Only enable A2DP profiles, disable HFP/HSP which cause GVC issues
            bluez5.roles = [ a2dp_sink a2dp_source ]
          }
        '')
      ];
    };
  };

  # Enable Bluetooth - Limiting profiles due to GVC crashes with HFP/HSP
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        ControllerMode = "dual";
        FastConnectable = true;
        # Disable AVRCP to prevent GVC crash
        Disable = "avrcp";
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  # Define a user account
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

  # Enable ZSH
  programs.zsh.enable = true;

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "user";

  # Enable fingerprint authentication
  services.fprintd.enable = true;

  # Periodic btrfs scrub to detect and fix data corruption
  services.btrfs.autoScrub.enable = true;

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages =
    (with pkgs; [
      # CommandLine Utilities
      age
      # bat # Managed by home-manager programs.bat
      # btop # Managed by home-manager programs.btop
      cbonsai
      cmatrix
      clock-rs
      cowsay
      dconf2nix
      dysk
      fastfetch
      figlet
      fortune
      # fzf # Managed by home-manager programs.fzf
      glow
      gtrash
      lolcat
      lsd
      nmap
      pipes-rs
      pond
      nvtopPackages.amd
      ripgrep
      sbctl
      sops
      # tealdeer # Managed by home-manager programs.tealdeer
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
      distrobox
      docker-compose
      git
      github-cli
      # ghostty # Managed by home-manager programs.ghostty
      jq
      nil
      nixd
      ptyxis
      shellcheck
      vscode
      winboat

      # System Utilities
      bibata-cursors
      bibata-cursors-translucent
      easyeffects
      dconf-editor
      duplicacy
      frog
      fprintd
      gnome-boxes
      input-remapper
      libgda6 # Required for copyous GNOME extension
      menulibre
      oreo-cursors-plus

      # My Apps
      discord
      keymapp
      obsidian
      onlyoffice-desktopeditors
      plexamp
      spotify
      teams-for-linux
      vencord
      (pkgs.wrapOBS {
        plugins = with pkgs.obs-studio-plugins; [
          droidcam-obs
          obs-backgroundremoval
          obs-gstreamer
          obs-pipewire-audio-capture
          obs-vaapi # optional AMD hardware acceleration
          obs-vkcapture
          wlrobs
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
    ++ (with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
      claude-code
    ]);

  fonts.packages = with pkgs; [
    nerd-fonts.ubuntu
    nerd-fonts.ubuntu-mono
    nerd-fonts.adwaita-mono
    nerd-fonts.droid-sans-mono
    meslo-lgs-nf
    corefonts
    vista-fonts
  ];

  environment.variables = {
    GI_TYPELIB_PATH = "${pkgs.libgda6}/lib/girepository-1.0"; # For Copyous GNOME Extension
  };

  environment.sessionVariables = {
    SOPS_AGE_KEY_FILE = config.sops.age.keyFile;
  };

  # Enables OBS Virtual Camera
  programs.obs-studio.enableVirtualCamera = true;

  # FW-Fanctrl
  hardware.fw-fanctrl.enable = true;

  #DDCCI Driver Config
  hardware.i2c.enable = true;
  boot.kernelModules = [
    "i2c-dev"
  ];
  services.ddccontrol.enable = true;
  services.udev.packages = [pkgs.ddcutil];

  # Adjust PAM to have fprintd come after pam_unix
  security.pam.services.sudo.rules.auth.unix.order =
    config.security.pam.services.sudo.rules.auth.fprintd.order - 1;
  security.pam.services.polkit-1.rules.auth.unix.order =
    config.security.pam.services.polkit-1.rules.auth.fprintd.order - 1;

  # Open ports in the firewall.
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

  # Garbage collection settings
  # keep store blobs for old generations up to 30 days
  nix.gc.options = "--delete-older-than 30d";

  # only keep the last 15 generations (otherwise boot partition can fill up too much)
  boot.loader.systemd-boot.configurationLimit = 15;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
