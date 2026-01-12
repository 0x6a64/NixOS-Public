# NixOS Configuration - Gearhead

Personal NixOS configuration for Framework 13 (AMD 7040) with secure boot, LUKS encryption, Btrfs with impermanence, and Stylix theming.

## System Overview

**Hardware:** Framework 13 (AMD Ryzen 7040)
**Desktop:** GNOME (COSMIC DE available)
**Theme System:** Stylix with Kanagawa color scheme
**Bootloader:** Lanzaboote (Secure Boot)
**Filesystem:** Btrfs with LUKS encryption
**Partition Layout:** Disko-managed with impermanence

## Key Features

- **Security:** Secure Boot with Lanzaboote, LUKS full-disk encryption, sops-nix secrets management
- **Impermanence:** Root and home wiped on cold boot, hibernation-safe (marker file approach)
- **Hybrid Swap:** zram (50% RAM) for active compression + swapfile for hibernation
- **Hardware Support:** Framework-specific optimizations, ZSA keyboard, Thunderbolt, fingerprint reader
- **External Monitor Control:** DDCCI driver for DDC/CI brightness/settings control
- **Development:** VSCode, Claude Code, Git, Docker, Virt-Manager, Ghostty, Distrobox, Direnv
- **Unified Theming:** Stylix manages colors across system, browser extensions, and applications
- **Automation:** GitHub Actions for automated flake.lock and package updates

## Repository Structure

```
nixos/
├── flake.nix              # Main flake with inputs/outputs
├── configuration.nix      # System-level NixOS configuration
├── home.nix               # Home Manager user configuration
├── hardware-configuration.nix
├── stylix.nix             # Unified theming (Kanagawa)
├── gnome.nix              # GNOME desktop environment
├── cosmic.nix             # COSMIC DE (alternative)
├── firefox.nix            # Firefox browser config
├── zen.nix                # Zen Browser config
├── dconf.nix              # GNOME dconf settings
├── disko.nix              # Disk partitioning
├── impermenance.nix       # Impermanence/stateless config
├── flatpak.nix            # Flatpak support
├── network.nix            # NetworkManager profiles (sops-nix)
├── packages/
│   ├── duplicacy-web.nix  # Duplicacy service
│   └── package-duplicacy.nix
├── secrets/
│   └── secrets.yaml       # Encrypted secrets (sops)
├── dots/                  # Dotfiles and configs
├── templates/
│   └── python-direnv/     # Python dev environment template
└── .github/workflows/     # Automated update workflows
```

## Installation

### Prerequisites
- NixOS ISO booted with networking configured
- USB drive with sops-nix `keys.txt` at `/run/media/nixos/miscstorage/keys.txt`

### Install Steps

1. **Clone and run installer:**
   ```bash
   git clone https://github.com/fransole/NixOS-Public.git
   cd nixos
   ./install.sh
   ```

2. **The script will:**
   - Configure git and authenticate with GitHub
   - Partition and format disks using Disko
   - Generate hardware configuration
   - Copy sops-nix keys from USB
   - Install NixOS with the `nixos-framework` flake configuration
   - Create blank Btrfs snapshot for impermanence
   - Prompt for reboot

3. **After installation:**
   - Reboot into new system
   - Run `/home/user/Nixos/post-install.sh` to complete setup

## Post-Installation

The `post-install.sh` script completes the following:

1. **Symlink Configuration:**
   - Removes `/etc/nixos` and symlinks it to the repository path

2. **Secure Boot Setup:**
   - Uncomments lanzaboote configuration in `configuration.nix` if needed
   - Rebuilds system with `sudo nixos-rebuild switch`
   - Checks Secure Boot setup mode status
   - Enrolls Secure Boot keys with `sbctl enroll-keys -m -f`

3. **Manual Steps After Script:**
   - Enable Secure Boot in BIOS/UEFI
   - Reboot to verify Secure Boot is active

## Configuration Highlights

### Filesystem Layout
```
/boot           2GB FAT32 (ESP)
/dev/nvme0n1p2  LUKS encrypted, Btrfs:
  /root         Ephemeral root + home (wiped on cold boot)
  /root-blank   Read-only snapshot for rollback (created post-install)
  /nix          Nix store
  /persist      Persistent state (bind-mounted to ephemeral paths)
  /var/log      Logs
  /var/lib      System state (docker, systemd, bluetooth, etc.)
  /persist/swap Swapfile (34GB, nocow)
```

### Impermanence

The system uses a **marker file approach** for hibernation-safe impermanence:

| Event | Marker State | Action |
|-------|--------------|--------|
| Cold boot | Exists | Rollback root → clean slate |
| Hibernate resume | Missing | Skip rollback → preserve state |
| Crash/power loss | Missing | Skip rollback → safe default |

**What's ephemeral (wiped on cold boot):**
- `/` root filesystem
- `/home/*` (except persisted directories)
- Random dotfiles, app caches, temp files

**What's persisted:**
- XDG directories: Desktop, Documents, Downloads, Music, Pictures, Videos, etc.
- Security: `.ssh`, `.gnupg`, `.local/share/keyrings`
- App configs: ghostty, VSCode, OBS, Spotify, Discord, etc.
- System: `/etc/nixos`, NetworkManager connections, machine-id

### Swap Configuration
- **zram:** 50% of RAM, priority 100 (used first)
- **Swapfile:** 34GB at `/persist/swap/swapfile`, priority 10 (fallback + hibernation)

### Power Management
- Lid close: suspend-then-hibernate (hibernates after 30min)
- Power button: hibernate
- Power button long press: poweroff

### Key Software
- **Shell:** Zsh with Home Manager configuration
- **Editor:** VSCode with Nix extensions
- **Terminal:** Ghostty, Ptyxis
- **Browser:** Firefox and Zen Browser with Stylix integration
- **Communication:** Discord (Vencord), Spotify
- **Productivity:** Obsidian, OnlyOffice, OBS Studio
- **Virtualization:** Docker (Btrfs storage), libvirtd/QEMU, Virt-Manager

### Secrets Management
Secrets stored in `secrets/secrets.yaml` encrypted with sops-nix:
- User password
- Wallhaven API key
- SSH keys
- GitHub token

Age key stored at `/persist/sops-nix/keys.txt`

## Maintenance

**Rebuild System:**
```bash
sudo nixos-rebuild switch
```

**Update Flake:**
```bash
nix flake update
sudo nixos-rebuild switch
```

**Garbage Collection:**
- Auto-optimizes store
- Keeps last 15 generations
- Deletes store files older than 30 days

## GitHub Actions (Automated Updates)

This repository includes GitHub Actions workflows for automated maintenance:

### Flake Lock Updates
- **File:** `.github/workflows/update-flake-lock.yml`
- **Schedule:** Weekly (Sundays at midnight UTC)
- **Action:** Updates `flake.lock` and creates a PR for review

### Duplicacy Web Updates
- **File:** `.github/workflows/update-duplicacy-web.yml`
- **Schedule:** Weekly (Mondays at midnight UTC)
- **Action:** Checks for new versions, updates hash, creates PR

**Manual Trigger:** Go to Actions tab → Select workflow → "Run workflow"

**Cost:** Free for public repos. Private repos get 2,000+ free minutes/month (these workflows use ~30 min/month total).

## Development Environment (Direnv)

Direnv is enabled for automatic environment loading. Templates are provided in `templates/`.

### Python Development Setup

1. Copy the template to your project:
   ```bash
   cp -r ~/Nixos/templates/python-direnv/* /path/to/project/
   ```

2. Allow direnv:
   ```bash
   cd /path/to/project
   direnv allow
   ```

3. Customize `flake.nix` with your required packages

The environment auto-loads when you enter the directory and creates a `.venv/` for pip packages.

## Alternative Desktop Environments

### COSMIC DE

System76's COSMIC desktop is available as an alternative to GNOME.

**To switch:**
1. In `configuration.nix`: Comment `./gnome.nix`, add `./cosmic.nix`
2. In `home.nix`: Comment `./dconf.nix`
3. In `stylix.nix`: Disable GNOME targets

See `cosmic.nix` for full configuration and nixos-cosmic flake setup instructions.

## NetworkManager Declarative Profiles

The `network.nix` module provides templates for declarative network configuration with sops-nix secrets.

**Supported profiles:**
- WiFi (WPA-PSK)
- VLAN tagging
- WireGuard VPN

**Setup:**
1. Add secrets to `secrets/secrets.yaml`:
   ```yaml
   wifi-home: "your-password"
   wg-private-key: "your-wireguard-key"
   ```
2. Import `./network.nix` in `configuration.nix`
3. Uncomment and customize desired profiles

---

# Stylix Color API Reference

Stylix exposes colors via `config.lib.stylix.colors`, an attribute set generated by [`mkSchemeAttrs` from base16.nix](https://github.com/SenchoPens/base16.nix/blob/main/DOCUMENTATION.md#mkschemeattrs).

## Base16 Color Names (base00–base0F)

| Attribute      | Example Value | Description                      |
| -------------- | ------------- | -------------------------------- |
| `base08`       | `"ff0000"`    | Raw hex (no `#`)                 |
| `base08-hex`   | `"ff0000"`    | Same as above                    |
| `base08-hex-r` | `"ff"`        | Red component (hex)              |
| `base08-hex-g` | `"00"`        | Green component (hex)            |
| `base08-hex-b` | `"00"`        | Blue component (hex)             |
| `base08-rgb-r` | `"255"`       | Red component (decimal string)   |
| `base08-rgb-g` | `"0"`         | Green component (decimal string) |
| `base08-rgb-b` | `"0"`         | Blue component (decimal string)  |
| `base08-dec-r` | `"0.996094"`  | Red component (0–1 float string) |
| `base08-dec-g` | `"0.0"`       | Green component (0–1 float)      |
| `base08-dec-b` | `"0.0"`       | Blue component (0–1 float)       |

## Named Color Aliases

Standard color names that map to base16 values:

- `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `orange`, `brown`
- `bright-red`, `bright-green`, `bright-yellow`, `bright-blue`, `bright-magenta`, `bright-cyan`

## With Hashtag

Access hex colors with `#` prefix:

```nix
config.lib.stylix.colors.withHashtag.base08  # => "#ff0000"
config.lib.stylix.colors.withHashtag.red     # => "#ff0000"
```

## Helper Functions

From `stylix/colors.nix`:

```nix
# Convert hex color to 0x format
config.lib.stylix.mkHexColor "#ff0000"           # => "0xff0000"

# Convert hex color with opacity (0-1) to 0xRRGGBBAA format
config.lib.stylix.mkOpacityHexColor "#ff0000" 0.5  # => "0x7fff0000"
```

## Base16 Color Meanings

| Color    | Typical Usage                                  |
| -------- | ---------------------------------------------- |
| `base00` | Default Background                             |
| `base01` | Lighter Background (status bars, line numbers) |
| `base02` | Selection Background                           |
| `base03` | Comments, Invisibles                           |
| `base04` | Dark Foreground (status bars)                  |
| `base05` | Default Foreground                             |
| `base06` | Light Foreground                               |
| `base07` | Lightest Foreground                            |
| `base08` | Red (Variables, Errors)                        |
| `base09` | Orange (Integers, Constants)                   |
| `base0A` | Yellow (Classes, Search)                       |
| `base0B` | Green (Strings)                                |
| `base0C` | Cyan (Support, Regex)                          |
| `base0D` | Blue (Functions, Methods)                      |
| `base0E` | Magenta (Keywords)                             |
| `base0F` | Brown (Deprecated, Embedded)                   |

## Usage Examples

### Integer RGB values (for Zen Browser spaces)

```nix
theme.colors = [{
  red = lib.strings.toInt config.lib.stylix.colors.base0E-rgb-r;
  green = lib.strings.toInt config.lib.stylix.colors.base0E-rgb-g;
  blue = lib.strings.toInt config.lib.stylix.colors.base0E-rgb-b;
}];
```

### Hex colors with hashtag (for CSS/extensions)

```nix
uiAccentCustom0 = "${config.lib.stylix.colors.withHashtag.base0D}";
```

### Raw hex (no hashtag)

```nix
background = colors.base00;  # => "1a1b26"
```

## References

- [Stylix Documentation](https://nix-community.github.io/stylix/)
- [base16.nix mkSchemeAttrs](https://github.com/SenchoPens/base16.nix/blob/main/DOCUMENTATION.md#mkschemeattrs)
- [Stylix GitHub](https://github.com/nix-community/stylix)
