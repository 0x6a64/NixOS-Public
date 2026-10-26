{
  config,
  pkgs,
  lib,
  osConfig,
  inputs,
  ...
}: let
  # Token is read per gh invocation instead of exported, so it never reaches child processes or distrobox
  ghWithToken = pkgs.symlinkJoin {
    name = "gh-with-token";
    paths = [pkgs.gh];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/gh --run 'if [ -z "''${GH_TOKEN-}" ] && [ -r /run/secrets/github-token ]; then GH_TOKEN="$(< /run/secrets/github-token)"; export GH_TOKEN; fi'
    '';
    meta.mainProgram = "gh";
  };
  desktop = osConfig.nixos-framework.desktop or null;
  isGnome = desktop == "gnome";
  isPlasma = desktop == "kde";
  mkGdriveMount = {
    remote,
    dir,
  }: {
    Unit = {
      Description = "rclone mount for ${remote}";
    };
    Service = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/${dir}";
      # vfs-cache-mode full serves previously opened files from disk instead of re-downloading
      ExecStart = "${pkgs.rclone}/bin/rclone mount ${remote}: %h/${dir} --vfs-cache-mode full --vfs-cache-max-size 20G --vfs-cache-max-age 72h --dir-cache-time 1h";
      # Clears a stale mount left by a crash, which would otherwise fail every restart
      ExecStopPost = "-/run/wrappers/bin/fusermount3 -uz %h/${dir}";
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
  # Warms rclone's --dir-cache (metadata only) so the first browse in Files is instant
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
          runtimeInputs = [ghWithToken pkgs.jq];
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
          ".desktop"
          "Downloads"
          "Files"
          "Music"
          "Pictures"
          "Public"
          "Templates"
          "Videos"

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
          ".local/state/nix"
          ".local/share/easyeffects"
          ".local/share/direnv"
          ".local/share/Trash"
          ".local/share/copyous@boerdereinar.dev"
          ".cache/copyous@boerdereinar.dev"
          ".local/share/icons/distrobox"

          # App configs
          ".config/autostart"
          # GOA accounts.conf only; OAuth tokens live in the keyring
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
          # VS Code workspace trust lives here, not in .config/Code
          ".vscode-shared"
          # GSConnect host TLS identity
          ".config/gsconnect"

          # Caches
          ".cache/mozilla"
          ".config/obsidian"
          ".cache/obsidian"
          ".cache/fontconfig"
          ".cache/tealdeer"
          ".cache/claude-cli-nodejs"

          # Re-thumbnailing would re-download Drive images every boot
          ".cache/thumbnails"
          # rclone vfs cache; otherwise every file is re-downloaded each boot
          ".cache/rclone"

          # LocalSearch index; otherwise re-crawled every login
          ".cache/tracker3"

          # Otherwise shaders recompile every boot, freezing gnome-shell ~10-20s
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
          ".config/libvirt" # Boxes VMs vanish without it

          {
            directory = ".claude";
            mode = "0700";
          }
          {
            directory = ".kimi-code";
            mode = "0700";
          }
          {
            directory = ".azure";
            mode = "0700";
          }
          ".bicep"
          ".zcode"
          ".config/ZCode"
          ".config/rclone" # Drive OAuth tokens
          ".config/powershell"
          ".local/share/powershell"
          ".cache/powershell"
        ];
        files = [
          ".zsh_history"
          ".claude.json"
          ".taskrc"
          # Without it kali is recreated every boot (see CLAUDE.md)
          ".config/distrobox/prev_hash"
          ".local/share/applications/kali.desktop"
          # monitors.xml is deliberately absent, see installMonitorsXml
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

          /* Line the sidebar button up with the vertical-tabs favicon column */
          #sidebar-button {
            margin-inline-start: -6px !important;
          }

          /* Nav-bar buttons: no highlight circle, stylix accent icon on hover/open */
          #nav-bar {
            --toolbarbutton-background-color-hover: transparent !important;
            --toolbarbutton-background-color-active: transparent !important;
            --toolbarbutton-outline-color-hover: transparent !important;
          }
          #nav-bar .toolbarbutton-1:not([disabled]):is(:hover, [open], [checked]) {
            fill: ${config.lib.stylix.colors.withHashtag.base0D} !important;
          }

          /* Fixed 219px sidebar: puts the pinned grid's outer columns under the sidebar and extensions buttons */
          #sidebar-container[sidebar-launcher-expanded] {
            width: 219px !important;
            min-width: 219px !important;
            max-width: 219px !important;
          }
          #sidebar-launcher-splitter {
            pointer-events: none !important;
          }

          /* (219 - 2 * 7.5) / 4 = 51px columns: outer ones sit under the sidebar and extensions buttons. ::part() overrides from userChrome don't take effect, so pad via Firefox's own variable */
          #pinned-tabs-container[orient="vertical"] {
            --tab-container-margin-inline-pinned-expanded: 7.5px !important;
          }

          /* Pinned tabs: bare icon when inactive */
          .tabbrowser-tab[pinned]:not(:hover) .tab-background:not([selected], [multiselected]) {
            background-color: transparent !important;
            outline-color: transparent !important;
          }

          /* Selected tab: no pill; its label is underlined in the ring's cycling colours instead */
          #tabbrowser-tabs .tab-background:is([selected], [multiselected]) {
            outline: none !important;
            background: transparent !important;
            box-shadow: none !important;
          }
          /* Underlines are a background bar below the label box, so descenders don't break them */
          #tabbrowser-tabs .tabbrowser-tab:not([pinned]) .tab-label {
            padding-block: 4px !important; /* symmetric, so the text stays centred on the ring */
            background-repeat: no-repeat !important;
            background-position: 0 100%;
            background-size: 100% 2px;
          }
          /* Hover: muted static underline instead of the grey pill */
          #tabbrowser-tabs .tabbrowser-tab:not([pinned]):hover > .tab-stack > .tab-background:not([selected], [multiselected]) {
            background-color: transparent !important;
            outline-color: transparent !important;
          }
          #tabbrowser-tabs .tabbrowser-tab:not([pinned], [selected], [multiselected]):hover .tab-label {
            background-image: linear-gradient(${config.lib.stylix.colors.withHashtag.base03}, ${config.lib.stylix.colors.withHashtag.base03});
          }
          /* Selected: the ring's colours flowing along the underline */
          @keyframes tab-underline-flow {
            to { background-position: 200% 100%; }
          }
          #tabbrowser-tabs .tabbrowser-tab:not([pinned]):is([selected], [multiselected]) .tab-label {
            background-image: linear-gradient(90deg, ${config.lib.stylix.colors.withHashtag.base0D}, ${config.lib.stylix.colors.withHashtag.base0E}, ${config.lib.stylix.colors.withHashtag.base08}, ${config.lib.stylix.colors.withHashtag.base09}, ${config.lib.stylix.colors.withHashtag.base0D});
            background-repeat: repeat-x !important;
            background-size: 200% 2px;
            animation: tab-underline-flow 2.5s linear infinite;
          }

          /* Rotating multi-colour ring with a cycling glow: replaces a selected tab's favicon, or outlines a selected pinned tile as a squircle */
          @property --tab-ring-angle {
            syntax: "<angle>";
            inherits: false;
            initial-value: 0deg;
          }
          @keyframes tab-ring-spin {
            to { --tab-ring-angle: 360deg; }
          }
          @keyframes tab-ring-glow {
            0%, 100% { filter: drop-shadow(0 0 3px ${config.lib.stylix.colors.withHashtag.base0D}); }
            25% { filter: drop-shadow(0 0 3px ${config.lib.stylix.colors.withHashtag.base0E}); }
            50% { filter: drop-shadow(0 0 3px ${config.lib.stylix.colors.withHashtag.base08}); }
            75% { filter: drop-shadow(0 0 3px ${config.lib.stylix.colors.withHashtag.base09}); }
          }
          #tabbrowser-tabs .tabbrowser-tab:not([pinned]):is([selected], [multiselected]) .tab-icon-stack,
          #tabbrowser-tabs .tabbrowser-tab[pinned]:is([selected], [multiselected]) .tab-background {
            position: relative !important;
          }
          #tabbrowser-tabs .tabbrowser-tab:not([pinned]):is([selected], [multiselected]) .tab-icon-stack::before,
          #tabbrowser-tabs .tabbrowser-tab[pinned]:is([selected], [multiselected]) .tab-background::before {
            content: "";
            position: absolute;
            box-sizing: border-box;
            padding: 2px;
            background: conic-gradient(from var(--tab-ring-angle), ${config.lib.stylix.colors.withHashtag.base0D}, ${config.lib.stylix.colors.withHashtag.base0E}, ${config.lib.stylix.colors.withHashtag.base08}, ${config.lib.stylix.colors.withHashtag.base09}, ${config.lib.stylix.colors.withHashtag.base0D});
            mask: linear-gradient(#000 0 0) content-box exclude, linear-gradient(#000 0 0);
            pointer-events: none;
            animation: tab-ring-spin 2.5s linear infinite;
          }
          /* The icon stack isn't square (22x14), so size the ring explicitly, anchored to the favicon's left edge */
          #tabbrowser-tabs .tabbrowser-tab:not([pinned]):is([selected], [multiselected]) .tab-icon-stack::before {
            left: -0.5px;
            top: 50%;
            width: 18px;
            height: 18px;
            margin-top: -9px;
            border-radius: 50%;
          }
          #tabbrowser-tabs .tabbrowser-tab[pinned]:is([selected], [multiselected]) .tab-background::before {
            inset: 0;
            border-radius: 12px;
          }
          #tabbrowser-tabs .tabbrowser-tab:not([pinned]):is([selected], [multiselected]) .tab-icon-stack > * {
            visibility: hidden !important;
          }
          /* Glow goes on the ring's parent because a filter on the masked ring itself would be masked away */
          #tabbrowser-tabs .tabbrowser-tab:not([pinned]):is([selected], [multiselected]) .tab-icon-stack,
          #tabbrowser-tabs .tabbrowser-tab[pinned]:is([selected], [multiselected]) .tab-background {
            animation: tab-ring-glow 2.5s linear infinite;
          }
          @media (prefers-reduced-motion: reduce) {
            #tabbrowser-tabs .tabbrowser-tab:is([selected], [multiselected]) :is(.tab-icon-stack, .tab-background, .tab-label),
            #tabbrowser-tabs .tabbrowser-tab:is([selected], [multiselected]) :is(.tab-icon-stack, .tab-background)::before {
              animation: none;
            }
          }
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

      # GLib's replace-destination writes break bind mounts and symlinks, so install from the repo
      # each activation; copy GUI display changes back to dots/monitors.xml to keep them
      activation.installMonitorsXml = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm644 ${./dots/monitors.xml} \
          "${config.home.homeDirectory}/.config/monitors.xml"
      '';
      # The ~/.config/mozilla bind mount hides HM symlinks, so copy the managed files into /persist
      activation.syncFirefoxFiles = lib.hm.dag.entryAfter ["linkGeneration"] ''
        src="$newGenPath/home-files/.config/mozilla/firefox"
        dest="/persist${config.home.homeDirectory}/.config/mozilla/firefox"
        if [[ -d "$src" && -d "$dest" ]]; then
          $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -aL --no-o --no-g --chmod=Du+rwx,Fu+rw "$src/" "$dest/"
        fi
      '';
    };

    xdg = {
      configFile."xdg-terminals.list".text = "org.gnome.Ptyxis.desktop\n";

      # Hide default .desktop entries by overriding them
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
            additional_packages = ["systemd"];
            home = "${config.home.homeDirectory}/Kali";
            # http.kali.org redirects to random mirrors, some dead; kali.download is Kali's CDN (HTTP: image has no CA certs, apt checks GPG)
            pre_init_hooks = [
              "sed -i 's|http://http.kali.org|http://kali.download|' /etc/apt/sources.list.d/kali.sources"
            ];
            init_hooks = [
              "apt-get update && apt-get install -y kali-linux-headless"
            ];
            pull = true;
            replace = true;
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

      bash.enable = true;

      gh = {
        enable = true;
        package = ghWithToken;
        gitCredentialHelper.enable = true;
        settings = {
          git_protocol = "https";
          editor = "code --wait";
        };
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

        # The extension's own startup fetch never fires (dconf is wiped each boot), so request it
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

    # Run `rclone config` once per remote to authorize each account
    systemd.user.services.rclone-gdrive-personal = mkGdriveMount {
      remote = "gdrive-personal";
      dir = "GoogleDrive-Personal";
    };
    systemd.user.services.rclone-gdrive-work = mkGdriveMount {
      remote = "gdrive-work";
      dir = "GoogleDrive-work";
    };
    systemd.user.services.rclone-gdrive-org = mkGdriveMount {
      remote = "gdrive-org";
      dir = "GoogleDrive-Org";
    };
    systemd.user.services.rclone-gdrive-personal-prefetch = mkGdrivePrefetch {
      unit = "rclone-gdrive-personal";
      dir = "GoogleDrive-Personal";
    };
    systemd.user.services.rclone-gdrive-work-prefetch = mkGdrivePrefetch {
      unit = "rclone-gdrive-work";
      dir = "GoogleDrive-work";
    };
    systemd.user.services.rclone-gdrive-org-prefetch = mkGdrivePrefetch {
      unit = "rclone-gdrive-org";
      dir = "GoogleDrive-Org";
    };

    programs.claude-code = {
      enable = true;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
      mcpServers.nixos = {
        type = "stdio";
        command = lib.getExe inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.mcp-nixos;
      };
      # OAuth is handled in-browser via /mcp; the callback opens Claude via x-scheme-handler/claude above
      mcpServers.robinhood = {
        type = "http";
        url = "https://agent.robinhood.com/mcp/trading";
      };
    };

    programs.home-manager.enable = true;

    home.stateVersion = "25.11";

    xdg.userDirs.setSessionVariables = true; # Silence stateVersion < 26.05 warning

    # Nautilus dropped these from the default sidebar
    gtk.gtk3.bookmarks = [
      "file:///home/user/Downloads Downloads"
      "file:///home/user/Files Documents"
      "file:///home/user/Music Music"
      "file:///home/user/Pictures Pictures"
      "file:///home/user/Videos Videos"
      "file:///home/user/Code Code"
    ];
  }
