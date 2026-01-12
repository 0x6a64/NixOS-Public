{
  config,
  pkgs,
  lib,
  activeDesktopEnvironment ? "gnome", # Passed from de-selector.nix
  ...
}:
with lib; {
  imports =
    [
      ./stylix.nix
      ./zen.nix
      ./firefox.nix
    ]
    # Conditionally import DE-specific configs
    ++ (optionals (activeDesktopEnvironment == "gnome") [
      ./de/dconf.nix
    ])
    ++ (optionals (activeDesktopEnvironment == "plasma") [
      ./de/plasma.nix
    ]);

  # Note: QT theming is handled by Stylix via stylix.targets.qt.platform = "adwaita"
  # Do NOT set qt.platformTheme here as it conflicts with Stylix's theming

  home = {
    # Home Manager needs a bit of information about you and the paths it should manage.
    username = "user";
    homeDirectory = "/home/user";

    # The home.packages option allows you to install Nix packages into your environment.
    packages = [
      # # Adds the 'hello' command to your environment. It prints a friendly
      # # "Hello, world!" when run.
      # pkgs.hello

      # # It is sometimes useful to fine-tune packages, for example, by applying
      # # overrides. You can do that directly here, just don't forget the
      # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
      # # fonts?
      # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

      # # You can also create simple shell scripts directly inside your
      # # configuration. For example, this adds a command 'my-hello' to your
      # # environment:
      # (pkgs.writeShellScriptBin "my-hello" ''
      #   echo "Hello, ${config.home.username}!"
      # '')
      pkgs.meslo-lgs-nf
      pkgs.zsh-powerlevel10k
    ];
    # Impermanence - Home Manger
    persistence."/persist" = {
      hideMounts = true;
      directories = [
        # XDG user directories (non-hidden)
        ".desktop"
        "Downloads"
        "Files"
        "Music"
        "Pictures"
        "Public"
        "Templates"
        "Videos"

        # Custom directories
        "Nixos"
        "Code"
        "Kali"

        # ======================
        # Critical - Security
        # ======================
        {
          directory = ".gnupg";
          mode = "0700";
        }
        {
          directory = ".ssh";
          mode = "0700";
        }
        {
          directory = ".local/share/keyrings";
          mode = "0700";
        }

        # ======================
        # Nix Profiles
        # ======================
        ".local/state/nix" # Home-manager profiles and generations
        ".local/share/easyeffects" # EasyEffects 

        # ======================
        # App Configs (.config)
        # ======================
        ".config/autostart" # Desktop autostart entries (Stylix, etc.)

        # Media & Creativity
        ".config/obs-studio"
        ".config/spotify"
        ".config/Plexamp"

        # Communication
        ".config/discord"
        ".config/teams-for-linux"
        ".config/Code"

        # System
        ".config/input-remapper-2"

        # ======================
        # Caches (performance)
        # ======================
        ".cache/mozilla"
        ".cache/zen"
        ".cache/spotify"
        ".cache/obsidian"
        ".cache/fontconfig"
        ".cache/tealdeer/tldr-pages"
        ".cache/claude-cli-nodejs"

        # ======================
        # Browser Profiles
        # ======================
        ".mozilla"
        ".zen"

        # ======================
        # Other Apps
        # ======================
        ".duplicacy-web"

        # ======================
        # Development Tools
        # ======================
        {
          directory = ".claude";
          mode = "0700";
        }
      ];
      files = [
        # Shell history
        ".zsh_history"

        # Claude Code global config (onboarding, OAuth account, project settings)
        ".claude.json"
      ];
    };

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    file = {
      # Custom Firefox userChrome additions (appends to stylix GNOME theme)
      ".mozilla/firefox/default/chrome/userChrome-custom.css".text = ''
        /* Custom CSS additions to GNOME theme */
        #nav-bar-overflow-button {
          display: none !important;
        }

        #firefox-view-button {
          display: none !important;
        }

        /* Hide back and forward buttons */
        #back-button {
          display: none !important;
        }
        #forward-button {
          display: none !important;
        }
        /* "List all tabs" button */
        #alltabs-button {
          display : none !important;
        }
      '';

      ".zen/default/chrome/userChrome-custom.css".text = ''
        :root:not([customizing]) #back-button {
          display: none !important;
        }
        :root:not([customizing]) #forward-button {
          display: none !important;
        }
      '';

      ".p10k.zsh".source = ./dots/p10k.zsh;
      ".config/burn-my-windows/profiles/1767406314858751.conf".source = ./dots/config/burn-my-windows/profiles/1767406314858751.conf;
      ".local/share/sounds/MIUI".source = ./dots/local/share/sounds/MIUI;
      ".local/share/sounds/modern-minimal-ui-sounds-v1.1".source = ./dots/local/share/sounds/modern-minimal-ui-sounds-v1.1;
      ".local/share/icc/FW13_Intel.icm".source = ./dots/local/share/icc/FW13_Intel.icm;
      ".config/easyeffects/db".source = ./dots/config/easyeffects/db;
      # Note: .local/share/easyeffects is managed by impermanence (line 83)
      # Presets are copied from dots to /persist during install.sh
    };

    sessionVariables = {
      # VAR = "/persist/var.var";
    };
  };

  xdg = {
    # Remove default .desktop files by overriding them in ~/.local/share/applications
    dataFile = {
      "applications/cups.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=CUPS
        Exec=xdg-open http://localhost:631/
        NoDisplay=true
      '';
      "applications/nvtop.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=nvtop
        Exec=nvtop
        NoDisplay=true
      '';
      "applications/nixos-manual.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=NixOS Manual
        Exec=nixos-help
        NoDisplay=true
      '';
      "applications/gddccontrol.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=DDC Control
        Exec=gddcontrol
        NoDisplay=true
      '';
    };

    userDirs = {
      enable = true;
      createDirectories = true;
      documents = "${config.home.homeDirectory}/Files";
      desktop = "${config.home.homeDirectory}/.desktop";
    };

    autostart = {
      enable = true;
      # readOnly = false allows Stylix to add its autostart entry
      readOnly = false;
    };

    # XDG Default Applications
    mime.enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        # Web browsing
        "x-scheme-handler/http" = ["firefox.desktop"];
        "x-scheme-handler/https" = ["firefox.desktop"];
        "text/html" = ["firefox.desktop"];
        "application/xhtml+xml" = ["firefox.desktop"];
        # Email
        "x-scheme-handler/mailto" = ["firefox.desktop"];
        # PDFs
        "application/pdf" = ["firefox.desktop"];
      };
    };
  };

  programs = {
    distrobox = {
      enable = true;
      containers = {
        kali = {
          image = "kalilinux/kali-rolling:latest";
          additionalPackages = ["systemd"];
          home = "/home/user/Kali";
          init_hooks = [
            "apt-get install kali-linux-headless -y"
          ];
          pull = true;
          replace = true;
          autoUpgrade = true;
        };
      };
    };

    git = {
      enable = true;
      settings = {
        user.name = "Your Name";
        user.email = "user@example.com";
        init.defaultBranch = "main";
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          identityFile = ["/home/user/.ssh/default_ssh_25519"];
          addKeysToAgent = "yes";
        };
      };
    };
  };

  services = {
    ssh-agent = {
      enable = true;
    };
  };

  programs = {
    bash = {
      enable = true;
      initExtra = ''
        # Export GitHub token from secret file for gh CLI
        if [ -f /run/secrets/github-token ]; then
          export GH_TOKEN="$(cat /run/secrets/github-token)"
        fi
      '';
    };

    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
      settings = {
        git_protocol = "https";
        editor = "code --wait";
      };
      # Configure the host - token is provided via GH_TOKEN env var or hosts.yml
      hosts."github.com" = {
        user = "your-username";
        git_protocol = "https";
      };
    };

    vscode = {
      enable = true;
      # mutableExtensionsDir = false; #Honestly just got so fucking annoying
      profiles.default = {
        userSettings = (
          builtins.fromJSON ''
            {
              "nix.enableLanguageServer": true,
              "nix.serverPath": "nixd",
              "nix.serverSettings": {
                "nixd": {
                  "nixpkgs": {
                    "expr": "import (builtins.getFlake (builtins.toString ./.)).inputs.nixpkgs { }"
                  },
                  "formatting": {
                    "command": ["alejandra"]
                  },
                  "options": {
                    "nixos": {
                      "expr": "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.nixos-framework.options"
                    },
                    "home-manager": {
                      "expr": "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.nixos-framework.options.home-manager.users.type.getSubOptions []"
                    }
                  }
                }
              },
              "telemetry.telemetryLevel": "off",
              "update.showReleaseNotes": false,
              "files.autoSave": "afterDelay",
              "files.autoSaveDelay": 1000,
              "editor.wordWrap": "off",
              "editor.formatOnPaste": false,
              "editor.formatOnSave": true,
              "editor.tabSize": 2,
              "terminal.external.linuxExec": "ghostty",
              "explorer.confirmDelete": false,
              "claudeCode.preferredLocation": "panel",
              "claudeCode.useTerminal": true,
              "workbench.startupEditor": "none",
              "[nix]": {
                "editor.insertSpaces": true,
                "editor.tabSize": 2,
                "editor.formatOnPaste": false,
                "editor.formatOnSave": true,
                "editor.defaultFormatter": "jnoortheen.nix-ide"
              },
              "chat.viewSessions.orientation": "stacked",
              "github.copilot.nextEditSuggestions.enabled": true,
              "chat.tools.urls.autoApprove": {
                "https://*.github.com": {
                  "approveRequest": true,
                  "approveResponse": true
                },
                "https://*.github.io": {
                  "approveRequest": true,
                  "approveResponse": true
                }
              }
            }
          ''
        );

        extensions = with pkgs.vscode-marketplace;
        with pkgs.vscode-marketplace-release; [
          ms-python.python
          ms-azuretools.vscode-containers
          ms-vscode-remote.remote-containers
          ms-azuretools.vscode-docker
          codezombiech.gitignore
          github.copilot-chat
          ms-toolsai.jupyter
          ms-toolsai.vscode-jupyter-cell-tags
          ms-toolsai.jupyter-keymap
          ms-toolsai.jupyter-renderers
          ms-toolsai.vscode-jupyter-slideshow
          bbenoist.nix
          jnoortheen.nix-ide
          esbenp.prettier-vscode
          ms-python.vscode-pylance
          ms-python.python
          ms-python.debugpy
          ms-python.vscode-python-envs
          mechatroner.rainbow-csv
          github.copilot
          anthropic.claude-code
        ];
      };
    };

    zsh = {
      enable = true;
      shellAliases = {
        ls = "lsd";
        cat = "bat --paging=never";
        grep = "rg";
        rm = "gtrash put";
        gita = "git add -A && git commit -m";
        update = "sudo nix flake update && sudo nixos-rebuild boot --flake --upgrade --option warn-dirty false";
        rebuild = "sudo nixos-rebuild switch --flake --option warn-dirty false";
        rebuildst = "sudo nixos-rebuild switch --flake --show-trace --option warn-dirty false";
        clock = "clock-rs -c ${config.lib.stylix.colors.withHashtag.base0D}";
        cdn = "cd ~/Nixos";
        su = "sudo -s";
        sudo = "sudo ";
      };
      plugins = [
        {
          name = "zsh-powerlevel10k";
          src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/";
          file = "powerlevel10k.zsh-theme";
        }
      ];

      initContent = lib.mkMerge [
        (lib.mkBefore ''
          # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
          # Initialization code that may require console input (password prompts, [y/n]
          # confirmations, etc.) must go above this block; everything else may go below.
          #if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          #  source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
          #fi

          # autoSuggestions config

          unsetopt correct # autocorrect commands

          setopt hist_ignore_all_dups # remove older duplicate entries from history
          setopt hist_reduce_blanks # remove superfluous blanks from history items
          setopt inc_append_history # save history entries as soon as they are entered

          # auto complete options
          setopt auto_list # automatically list choices on ambiguous completion
          setopt auto_menu # automatically use menu completion
          zstyle ':completion:*' menu select # select completions with arrow keys
          zstyle ':completion:*' group-name "" # group results by category
          zstyle ':completion:::::' completer _expand _complete _ignored _approximate # enable approximate matches for completion
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*' # case insensitive completion
          alias cd..='cd ..' # fix cd.. typo

          #      bindkey '^I' forward-word         # tab
          #      bindkey '^[[Z' backward-word      # shift+tab
          #      bindkey '^ ' autosuggest-accept   # ctrl+space
          source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
          test -f ~/.p10k.zsh && source ~/.p10k.zsh

          # Export GitHub token from secret file for gh CLI
          if [ -f /run/secrets/github-token ]; then
            export GH_TOKEN="$(cat /run/secrets/github-token)"
          fi
        '')
      ];
    };

    bat = {
      enable = true;
    };

    btop = {
      enable = true;
    };

    fzf = {
      enable = true;
    };

    ghostty = {
      enable = true;
    };

    obsidian = {
      enable = true;
    };

    tealdeer = {
      enable = true;
      enableAutoUpdates = true;
    };

    # Direnv for automatic environment loading in project directories
    # To use: create a .envrc file in your project directory
    # See templates/python-direnv/ for a Python development template
    direnv = {
      enable = true;
      nix-direnv.enable = true; # Better caching for nix environments
      enableZshIntegration = true;
    };

    # Discord
    nixcord = {
      enable = true;
      discord = {
        vencord.enable = true;
        openASAR.enable = true;
      };
      config = {
        autoUpdate = false;
        autoUpdateNotification = false;
        frameless = true;
      };
    };
  };

  # Inject wallhaven API key from sops at runtime
  # Secrets are managed at system level in configuration.nix
  systemd.user.services.inject-wallhaven-key = let
    injectWallhavenKey = pkgs.writeShellScript "inject-wallhaven-key" ''
      if [ -f /run/secrets/wallhaven-key ]; then
        WALLHAVEN_KEY=$(cat /run/secrets/wallhaven-key)
        # GVariant string format requires "'value'" (single quotes inside double quotes)
        ${pkgs.dconf}/bin/dconf write /org/gnome/shell/extensions/space-iflow-randomwallpaper/sources/wallhaven/1764395143065/api-key "'$WALLHAVEN_KEY'"
      fi
    '';
  in {
    Unit = {
      Description = "Inject Wallhaven API key into dconf";
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${injectWallhavenKey}";
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  # Import ICC color profile via systemd service (runs after graphical session starts)
  systemd.user.services.import-color-profile = let
    applyColorProfile = pkgs.writeShellScript "apply-color-profile" ''
      PROFILE_PATH="${config.home.homeDirectory}/.local/share/icc/FW13_Intel.icm"
      DEVICE_ID="xrandr-BOE-0x095f-0x00000000"

      if [ ! -f "$PROFILE_PATH" ]; then
        echo "Profile not found at $PROFILE_PATH"
        exit 0
      fi

      # Import profile if not already present
      if ! ${pkgs.colord}/bin/colormgr find-profile-by-filename "$PROFILE_PATH" &>/dev/null; then
        echo "Importing color profile..."
        if ${pkgs.colord}/bin/colormgr import-profile "$PROFILE_PATH"; then
          # Give colord time to process the import
          sleep 1
        else
          echo "Failed to import profile"
          exit 1
        fi
      fi

      # Get the profile ID assigned by colord
      PROFILE_ID=$(${pkgs.colord}/bin/colormgr find-profile-by-filename "$PROFILE_PATH" 2>/dev/null | grep "Profile ID:" | awk '{print $3}')

      if [ -z "$PROFILE_ID" ]; then
        echo "Failed to get profile ID"
        exit 1
      fi

      # Add profile to device if not already added
      if ! ${pkgs.colord}/bin/colormgr device-get-profile-for-qualifier "$DEVICE_ID" "*" 2>/dev/null | grep -q "$PROFILE_ID"; then
        echo "Adding profile to device..."
        ${pkgs.colord}/bin/colormgr device-add-profile "$DEVICE_ID" "$PROFILE_ID" 2>/dev/null || true
      fi

      # Make it the default profile for this device
      echo "Setting profile as default..."
      ${pkgs.colord}/bin/colormgr device-make-profile-default "$DEVICE_ID" "$PROFILE_ID"
    '';
  in {
    Unit = {
      Description = "Import and apply ICC color profile";
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${applyColorProfile}";
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  # EasyEffects audio effects service
  systemd.user.services.easyeffects = {
    Unit = {
      Description = "EasyEffects audio effects";
      After = ["graphical-session.target" "pipewire.service" "wireplumber.service"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.easyeffects}/bin/easyeffects --gapplication-service";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.
}
