{
  config,
  pkgs,
  lib,
  osConfig,
  inputs,
  ...
}: let
  ghTokenInit = ''
    if [ -f /run/secrets/github-token ]; then
      export GH_TOKEN="$(cat /run/secrets/github-token)"
    fi
  '';
  desktop = osConfig.gearhead.desktop or null;
  isGnome = desktop == "gnome";
  isPlasma = desktop == "kde";
  mkGdriveMount = {
    remote,
    dir,
  }: {
    Unit = {
      Description = "rclone mount for ${remote}";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };
    Service = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/${dir}";
      # vfs-cache-mode full: on-demand read caching, so a file you've already
      # opened/thumbnailed once is served from disk instead of re-downloaded
      # on every access. Lazy (only what you touch), capped to bound disk use.
      ExecStart = "${pkgs.rclone}/bin/rclone mount ${remote}: %h/${dir} --vfs-cache-mode full --vfs-cache-max-size 20G --vfs-cache-max-age 72h --dir-cache-time 1h";
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
  # Walks the mounted tree once after mount to warm rclone's --dir-cache
  # (metadata only, no file contents), so first browse in Files feels instant.
  mkGdrivePrefetch = {
    unit,
    dir,
  }: {
    Unit = {
      Description = "Warm dir-cache for rclone mount at ${dir}";
      After = ["${unit}.service"];
      Requisite = ["${unit}.service"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.findutils}/bin/find %h/${dir} -type d";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
in
  with lib; {
    imports =
      [
        ./stylix.nix
        ./firefox.nix
      ]
      ++ optional isGnome ./de/dconf.nix
      ++ optional isPlasma ./de/plasma.nix;

    home = {
      username = "user";
      homeDirectory = "/home/user";

      packages = [
        (pkgs.writeShellApplication {
          name = "sync-cleanup";
          runtimeInputs = [pkgs.gh pkgs.jq];
          text = builtins.readFile ./scripts/sync-pr-cleanup.sh;
        })
        (pkgs.writeShellScriptBin "root-diff" (builtins.readFile ./scripts/root-diff.sh))
        pkgs.rclone
        pkgs.xdg-terminal-exec # GLib needs this to launch Terminal=true entries (distrobox's kali)
      ];

      persistence."/persist" = {
        hideMounts = true;
        allowTrash = true;
        directories = [
          # XDG user directories
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

          # Security
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

          # Nix profiles & app state
          ".local/state/nix" # Home-manager profiles and generations
          ".local/share/easyeffects"
          ".local/share/direnv" # direnv allow state
          ".local/share/Trash"
          ".local/share/copyous@boerdereinar.dev"
          ".cache/copyous@boerdereinar.dev"

          # App configs
          ".config/autostart" # Desktop autostart entries (Stylix, etc.)
          # GNOME Online Accounts (accounts.conf); the OAuth tokens themselves
          # live in the login keyring, persisted under .local/share/keyrings.
          ".config/goa-1.0"
          ".config/copyous@boerdereinar.dev"
          ".config/discordo"

          # Claude Desktop GUI app state (auth, sessions, config) — distinct from
          # the Claude Code CLI's ~/.claude / ~/.claude.json below
          {
            directory = ".config/Claude";
            mode = "0700";
          }

          # Media & creativity
          ".config/easyeffects"
          ".config/obs-studio"
          ".config/Plexamp"
          ".config/libreoffice"

          # Communication
          ".config/Signal"
          ".config/discord"
          ".config/Vencord"
          ".config/teams-for-linux"
          ".config/Code"

          # GSConnect host TLS identity (certificate.pem + private.pem);
          # the paired device record itself is declared in de/dconf.nix
          ".config/gsconnect"

          # Caches
          ".cache/mozilla"
          ".config/obsidian"
          ".cache/obsidian"
          ".cache/fontconfig"
          ".cache/tealdeer"
          ".cache/claude-cli-nodejs"

          # Without this every boot re-thumbnails everything, which for the rclone
          # Drive mounts means re-downloading the image bytes to do it.
          ".cache/thumbnails"
          # rclone's vfs-cache-mode full cache; without this, every boot
          # re-downloads every file's content again on first read.
          ".cache/rclone"

          # Without this every boot recompiles all compositor shaders, freezing
          # gnome-shell for ~10-20s at login.
          ".cache/mesa_shader_cache"
          ".cache/mesa_shader_cache_db"

          # Browser profiles
          ".config/mozilla"
          ".config/chromium"
          ".cache/chromium"

          # Gaming
          ".steam"
          ".local/share/Steam"

          # Other apps
          ".duplicacy-web"
          ".task"
          ".local/share/gnome-boxes"

          {
            directory = ".claude";
            mode = "0700";
          }
          # Azure CLI profile, tokens and installed extensions
          {
            directory = ".azure";
            mode = "0700";
          }
          ".bicep" # bicep registry module cache
          ".config/rclone" # Google Drive remotes' OAuth tokens (rclone.conf)
          ".config/powershell" # pwsh profile
          ".local/share/powershell" # Install-Module -Scope CurrentUser (Az, ...) + PSReadLine history
          ".cache/powershell" # module analysis cache
        ];
        files = [
          ".zsh_history"
          ".claude.json"
          ".taskrc"
          # ~/.config/monitors.xml deliberately isn't here — it is installed from
          # dots/ by installMonitorsXml below.
        ];
      };

      file = {
        # Custom Firefox userChrome additions (appends to stylix GNOME theme)
        ".config/mozilla/firefox/default/chrome/userChrome-custom.css".text = ''
          #nav-bar-overflow-button {
            display: none !important;
          }

          #firefox-view-button {
            display: none !important;
          }

          /* "List all tabs" button */
          #alltabs-button {
            display : none !important;
          }
          .tab-label-container[pinned] { visibility: hidden !important; }
        '';

        "Code/.envrc".text = ''
          # Auto-pull git repos if local is not ahead of remote
          auto_pull_if_not_ahead() {
            if ! git rev-parse --git-dir > /dev/null 2>&1; then
              return 0
            fi

            local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
            if [ -z "$branch" ]; then
              return 0
            fi

            git fetch origin "$branch" --quiet 2>/dev/null || return 0

            local ahead=$(git rev-list --count "origin/$branch..$branch" 2>/dev/null || echo "0")
            local behind=$(git rev-list --count "$branch..origin/$branch" 2>/dev/null || echo "0")

            if [ "''${ahead:-0}" -eq 0 ] && [ "''${behind:-0}" -gt 0 ]; then
              echo "direnv: pulling latest changes for $branch..."
              git pull --quiet origin "$branch"
            elif [ "''${ahead:-0}" -gt 0 ]; then
              echo "direnv: local is ''${ahead} commit(s) ahead of remote, skipping pull"
            fi
          }

          auto_pull_if_not_ahead
        '';

        ".p10k.zsh".source = ./dots/p10k.zsh;
        ".config/burn-my-windows/profiles/1767406314858751.conf".source = ./dots/config/burn-my-windows/profiles/1767406314858751.conf;
        ".local/share/sounds/MIUI".source = ./dots/local/share/sounds/MIUI;
        ".local/share/sounds/modern-minimal-ui-sounds-v1.1".source = ./dots/local/share/sounds/modern-minimal-ui-sounds-v1.1;
      };

      sessionVariables = {
        NIXOS_OZONE_WL = "1";
      };

      activation.createNixOSPublicEnvrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [ -d "$HOME/Code/NixOS-Public" ]; then
          run --quiet bash -c 'printf "# Inherit parent .envrc (auto-pull logic from ~/Code/.envrc)\nsource_up\n" > "$HOME/Code/NixOS-Public/.envrc"'
        fi
      '';

      # The impermanence bind mount on ~/.config/mozilla hides the HM symlinks, so
      # copy the managed files into the persist path after every generation switch.
      # GNOME's Displays panel rewrites monitors.xml through GLib's
      # replace-destination path (temp file, unlink, rename), so the file can be
      # neither bind-mounted (the rename fails with EBUSY) nor symlinked (the
      # link is replaced and the write is stranded on the ephemeral root). It is
      # installed from the repo each activation instead; after changing layout,
      # scale or VRR in the GUI, copy ~/.config/monitors.xml back to
      # dots/monitors.xml, otherwise the change is gone at the next boot.
      activation.installMonitorsXml = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm644 ${./dots/monitors.xml} \
          "${config.home.homeDirectory}/.config/monitors.xml"
      '';
      activation.syncFirefoxFiles = lib.hm.dag.entryAfter ["linkGeneration"] ''
        src="$newGenPath/home-files/.config/mozilla/firefox"
        dest="/persist${config.home.homeDirectory}/.config/mozilla/firefox"
        if [[ -d "$src" && -d "$dest" ]]; then
          $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -aL --no-o --no-g --chmod=Du+rwx,Fu+rw "$src/" "$dest/"
        fi
      '';
    };

    xdg = {
      # Terminal that xdg-terminal-exec hands Terminal=true entries to
      configFile."xdg-terminals.list".text = "org.gnome.Ptyxis.desktop\n";

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
        # libgda5 rides along on the GNOME session path for copyous's Gda typelib
        "applications/gda-browser-5.0.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=GdaBrowser
          Exec=gda-browser-5.0
          NoDisplay=true
        '';
        "applications/gda-control-center-5.0.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Gda Control Center
          Exec=gda-control-center-5.0
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

      mime.enable = true;
      mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/http" = ["firefox.desktop"];
          "x-scheme-handler/https" = ["firefox.desktop"];
          "text/html" = ["firefox.desktop"];
          "application/xhtml+xml" = ["firefox.desktop"];
          "x-scheme-handler/mailto" = ["firefox.desktop"];
          "application/pdf" = ["org.gnome.Evince.desktop"];
          # Claude Desktop deep links (e.g. MCP OAuth callbacks redirect to claude://)
          "x-scheme-handler/claude" = ["claude.desktop"];
        };
      };
    };

    programs = {
      distrobox = {
        enable = true;
        enableSystemdUnit = true;
        containers = {
          kali = {
            image = "kalilinux/kali-rolling:latest";
            additionalPackages = ["systemd"];
            home = "${config.home.homeDirectory}/Kali";
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
          push.autoSetupRemote = true;
          fetch.prune = true;
        };
      };

      ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "*" = {
            IdentityFile = "${config.home.homeDirectory}/.ssh/default_ssh_25519";
            AddKeysToAgent = "yes";
          };
        };
      };

      bash = {
        enable = true;
        initExtra = ghTokenInit;
      };

      gh = {
        enable = true;
        gitCredentialHelper.enable = true;
        settings = {
          git_protocol = "https";
          editor = "code --wait";
        };
        # Token comes from GH_TOKEN or hosts.yml
        hosts."github.com" = {
          user = "your-username";
          git_protocol = "https";
        };
      };

      vscode = {
        enable = true;
        profiles.default = {
          userSettings = {
            "nix.enableLanguageServer" = true;
            "nix.serverPath" = "nixd";
            "nix.serverSettings" = {
              nixd = {
                nixpkgs.expr = ''import (builtins.getFlake "/home/user/Nixos").inputs.nixpkgs { }'';
                options = {
                  nixos.expr = ''(builtins.getFlake "/home/user/Nixos").nixosConfigurations.nixos-framework.options'';
                  home-manager.expr = ''(builtins.getFlake "/home/user/Nixos").nixosConfigurations.nixos-framework.options.home-manager.users.type.getSubOptions []'';
                };
                formatting.command = ["alejandra"];
              };
            };
            "telemetry.telemetryLevel" = "off";
            "update.showReleaseNotes" = false;
            "files.autoSave" = "afterDelay";
            "files.autoSaveDelay" = 1000;
            "editor.wordWrap" = "off";
            "editor.formatOnPaste" = false;
            "editor.formatOnSave" = true;
            "editor.tabSize" = 2;
            "terminal.external.linuxExec" = "ghostty";
            "explorer.confirmDelete" = false;
            "claudeCode.preferredLocation" = "panel";
            "claudeCode.useTerminal" = true;
            "workbench.startupEditor" = "none";
            "[json]" = {
              "editor.defaultFormatter" = "esbenp.prettier-vscode";
            };
            "[nix]" = {
              "editor.insertSpaces" = true;
              "editor.tabSize" = 2;
              "editor.formatOnPaste" = false;
              "editor.formatOnSave" = true;
              "editor.defaultFormatter" = "jnoortheen.nix-ide";
            };
            "chat.viewSessions.orientation" = "stacked";
            "github.copilot.nextEditSuggestions.enabled" = true;
            "chat.tools.urls.autoApprove" = {
              "https://*.github.com" = {
                approveRequest = true;
                approveResponse = true;
              };
              "https://*.github.io" = {
                approveRequest = true;
                approveResponse = true;
              };
            };
          };

          extensions = with pkgs.vscode-marketplace;
          with pkgs.vscode-marketplace-release; [
            ms-python.python
            ms-azuretools.vscode-containers
            ms-vscode-remote.remote-containers
            ms-azuretools.vscode-docker
            codezombiech.gitignore
            ms-toolsai.jupyter
            ms-toolsai.vscode-jupyter-cell-tags
            ms-toolsai.jupyter-keymap
            ms-toolsai.jupyter-renderers
            ms-toolsai.vscode-jupyter-slideshow
            bbenoist.nix
            jnoortheen.nix-ide
            esbenp.prettier-vscode
            ms-python.vscode-pylance
            ms-python.debugpy
            ms-python.vscode-python-envs
            mechatroner.rainbow-csv
            astro-build.astro-vscode
            bierner.github-markdown-preview
            ozaki.markdown-github-dark
          ];
        };
      };

      zsh = {
        enable = true;
        shellAliases = {
          ls = "lsd";
          cat = "bat --paging=never";
          grep = "rg";
          gita = "git add -A && git commit -m";
          # nh self-elevates and reads NH_FLAKE (set via programs.nh in configuration.nix)
          update = "nh os boot --update";
          rebuild = "nh os switch";
          rebuildst = "nh os switch --show-trace";
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
            if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
              source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
            fi

            unsetopt correct

            setopt hist_ignore_all_dups
            setopt hist_reduce_blanks
            setopt inc_append_history # save history entries as soon as they are entered

            setopt auto_list
            setopt auto_menu
            zstyle ':completion:*' menu select # select completions with arrow keys
            zstyle ':completion:*' group-name "" # group results by category
            zstyle ':completion:::::' completer _expand _complete _ignored _approximate # approximate matches
            zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*' # case insensitive completion
            alias cd..='cd ..'

            test -f ~/.p10k.zsh && source ~/.p10k.zsh

            ${ghTokenInit}
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

      direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableZshIntegration = true;
      };
    };

    services = {
      ssh-agent = {
        enable = true;
      };

      easyeffects = {
        enable = true;
      };
    };

    systemd.user.services.inject-wallpaper-api-keys = let
      # <sops secret name>:<random-wallpaper source path under .../sources>
      wallpaperKeys = [
        "wallhaven-key:wallhaven/1764395143065"
        "unsplash-key:unsplash/1787891671600"
      ];
      backendConnection = "/org/gnome/shell/extensions/space-iflow-randomwallpaper/backend-connection";
      injectWallpaperKeys = pkgs.writeShellScript "inject-wallpaper-api-keys" ''
        for pair in ${lib.escapeShellArgs wallpaperKeys}; do
          secret="/run/secrets/''${pair%%:*}"
          [ -f "$secret" ] || continue
          ${pkgs.dconf}/bin/dconf write \
            "/org/gnome/shell/extensions/space-iflow-randomwallpaper/sources/''${pair#*:}/api-key" \
            "'$(cat "$secret")'"
        done

        # The extension's own fetch-on-startup never fires here: dconf is wiped
        # each boot, and its timer treats a zero timer-last-trigger as "just ran".
        # Request the fetch ourselves, once the extension is listening and the
        # keys above are in place.
        for _ in {1..30}; do
          if [ "$(${pkgs.dconf}/bin/dconf read ${backendConnection}/backend-connection-available)" = "true" ]; then
            ${pkgs.dconf}/bin/dconf write ${backendConnection}/request-new-wallpaper true
            break
          fi
          ${pkgs.coreutils}/bin/sleep 1
        done
      '';
    in {
      Unit = {
        Description = "Inject wallpaper source API keys and request a wallpaper";
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${injectWallpaperKeys}";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    # Google Drive mounts via rclone; `rclone config` must be run once per
    # remote (names below) to authorize each account before these come up.
    systemd.user.services.rclone-gdrive-personal = mkGdriveMount {
      remote = "gdrive-personal";
      dir = "GoogleDrive-Personal";
    };
    systemd.user.services.rclone-gdrive-kitsu = mkGdriveMount {
      remote = "gdrive-kitsu";
      dir = "GoogleDrive-Kitsu";
    };
    systemd.user.services.rclone-gdrive-bsides = mkGdriveMount {
      remote = "gdrive-bsides";
      dir = "GoogleDrive-BSides";
    };
    systemd.user.services.rclone-gdrive-personal-prefetch = mkGdrivePrefetch {
      unit = "rclone-gdrive-personal";
      dir = "GoogleDrive-Personal";
    };
    systemd.user.services.rclone-gdrive-kitsu-prefetch = mkGdrivePrefetch {
      unit = "rclone-gdrive-kitsu";
      dir = "GoogleDrive-Kitsu";
    };
    systemd.user.services.rclone-gdrive-bsides-prefetch = mkGdrivePrefetch {
      unit = "rclone-gdrive-bsides";
      dir = "GoogleDrive-BSides";
    };

    # Claude Code: HM owns the package so MCP servers can be baked in via plugin.
    programs.claude-code = {
      enable = true;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
      mcpServers.nixos = {
        type = "stdio";
        command = lib.getExe pkgs.mcp-nixos;
      };
      # OAuth is handled in-browser via /mcp; the callback opens Claude via x-scheme-handler/claude above
      mcpServers.robinhood = {
        type = "http";
        url = "https://agent.robinhood.com/mcp/trading";
      };
    };

    programs.home-manager.enable = true;

    # Home Manager release this config targets; check the release notes before changing
    home.stateVersion = "25.11";

    xdg.userDirs.setSessionVariables = true; # Silence stateVersion < 26.05 warning

    # GNOME 50's Nautilus dropped most of these from the default sidebar;
    # pin them back (stylix.targets.gtk.enable already turns on gtk.gtk3).
    gtk.gtk3.bookmarks = [
      "file:///home/user/Downloads Downloads"
      "file:///home/user/Files Documents"
      "file:///home/user/Music Music"
      "file:///home/user/Pictures Pictures"
      "file:///home/user/Videos Videos"
      "file:///home/user/Code Code"
    ];
  }
