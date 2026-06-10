#!/usr/bin/env bash
# Regenerates flake.nix with the latest extension versions from extensions.gnome.org.
# Usage: ./update.sh [gnome-shell-version]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_NIX="$SCRIPT_DIR/flake.nix"
GNOME_VER="${1:-$(gnome-shell --version 2>/dev/null | grep -oP '[0-9]+' | head -1)}"

echo "Querying extensions.gnome.org for GNOME $GNOME_VER..." >&2

# Format: "uuid:nixpkgs-attr"
EXTENSIONS=(
  "blur-my-shell@aunetx:blur-my-shell"
  "burn-my-windows@schneegans.github.com:burn-my-windows"
  "tilingshell@ferrarodomenico.com:tiling-shell"
  "randomwallpaper@iflow.space:random-wallpaper"
  "pip-on-top@rafostar.github.com:pip-on-top"
  "lilypad@shendrew.github.io:lilypad"
  "rounded-window-corners@fxgn:rounded-window-corners-reborn"
  "user-theme@gnome-shell-extensions.gcampax.github.com:user-themes"
  "dash-to-panel@jderose9.github.com:dash-to-panel"
  "AlphabeticalAppGrid@stuarthayhurst:alphabetical-app-grid"
  "appindicatorsupport@rgcjonas.gmail.com:appindicator"
  "weatheroclock@CleoMenezesJr.github.io:weather-oclock"
  "caffeine@patapon.info:caffeine"
  "color-picker@tuberry:color-picker"
  "display-brightness-ddcutil@themightydeity.github.com:brightness-control-using-ddcutil"
  # gsconnect is handled separately (fetched from GitHub, not extension zip)
  "custom-hot-corners-extended@G-dH.github.com:custom-hot-corners-extended"
)

make_entry() {
  local attr="$1" ver="$2" url="$3" hash="$4"
  printf '          # %s: v%s\n' "$attr" "$ver"
  printf '          %s = prev.gnomeExtensions.%s.overrideAttrs {\n' "$attr" "$attr"
  printf '            version = "%s";\n' "$ver"
  printf '            src = prev.fetchzip {\n'
  printf '              url = "%s";\n' "$url"
  printf '              hash = "%s";\n' "$hash"
  printf '              stripRoot = false;\n'
  printf '            };\n'
  printf '          };\n'
}

ENTRIES=""
for ext in "${EXTENSIONS[@]}"; do
  uuid="${ext%%:*}"
  attr="${ext#*:}"

  printf '  %-65s' "$uuid" >&2

  result=$(curl -sf "https://extensions.gnome.org/extension-info/?uuid=${uuid}&shell_version=${GNOME_VER}" 2>/dev/null || true)
  version=$(echo "$result" | grep -o '"version": [0-9]*' | tail -1 | awk '{print $2}' || true)

  if [[ -z "$version" ]]; then
    echo "no GNOME $GNOME_VER build, skipping" >&2
    continue
  fi

  url_uuid="${uuid/@/}"
  url="https://extensions.gnome.org/extension-data/${url_uuid}.v${version}.shell-extension.zip"
  hash=$(nix store prefetch-file --unpack --json "$url" 2>/dev/null | grep -o '"hash":"[^"]*"' | cut -d'"' -f4 || true)

  echo "v${version}" >&2
  ENTRIES+="$(make_entry "$attr" "$version" "$url" "$hash")"$'\n'
done

# Single-quoted heredocs pass ${...} through literally as nix syntax, not bash
{
  cat << 'HEADER'
{
  description = "GNOME extensions overlay — remove once nixpkgs auto-update PR lands";

  outputs = {self}: {
    overlays.default = final: prev: {
      gnomeExtensions =
        prev.gnomeExtensions
        // {
HEADER

  printf '%s' "$ENTRIES"

  cat << 'FOOTER'
        };
    };
  };
}
FOOTER
} > "$FLAKE_NIX"

echo "" >&2
echo "Done. Updated $FLAKE_NIX" >&2
echo "NOTE: gsconnect is fetched from GitHub and must be updated manually in flake.nix." >&2
echo "Run: git add overlays/gnome-extensions/flake.nix && rebuild" >&2
