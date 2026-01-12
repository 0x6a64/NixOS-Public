#!/usr/bin/env bash
# root-diff.sh
# Script to compare current root with old root snapshots
# For NixOS impermanence setups

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
OLD_ROOTS_DIR="/persist/old_roots"
CURRENT_ROOT="/"

# Directories to exclude (system paths)
EXCLUDE_DIRS=(
    "nix"
    "persist"
    "var/lib"
    "var/log"
    "boot"
    "proc"
    "sys"
    "dev"
    "run"
    "tmp"
)

# Persisted paths from impermanence.nix (system-level)
# Also includes tmp paths (wiped by boot.tmp.cleanOnBoot)
PERSISTED_SYSTEM=(
    "etc/nixos"
    "etc/NetworkManager/system-connections"
    "var/spool"
    "root"
    # Tmp paths - wiped on boot anyway
    "tmp"
    "var/tmp"
)

# Persisted paths from home.nix (user home directories)
# These are relative to home/user/
PERSISTED_HOME=(
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
    ".gnupg"
    ".ssh"
    ".local/share/keyrings"
    # Nix profiles
    ".local/state/nix"
    ".local/share/easyeffects"
    # App configs
    ".config/autostart"
    ".config/obs-studio"
    ".config/spotify"
    ".config/Plexamp"
    ".config/discord"
    ".config/teams-for-linux"
    ".config/Code"
    ".config/input-remapper-2"
    # Caches
    ".cache/mozilla"
    ".cache/zen"
    ".cache/spotify"
    ".cache/obsidian"
    ".cache/fontconfig"
    ".cache/tealdeer"
    ".cache/claude-cli-nodejs"
    # Browser profiles
    ".mozilla"
    ".zen"
    # Other apps
    ".duplicacy-web"
    ".claude"
)

usage() {
    cat <<EOF
Usage: $0 [OPTIONS] [TIMESTAMP]

Compare current root with old root snapshots.

OPTIONS:
    -l, --list          List available snapshots (with index numbers)
    -h, --help          Show this help
    -a, --all           Compare with all snapshots
    -n NUM              Select snapshot by index (like journalctl -b)
                        0 = most recent, 1 = previous, 2 = two ago, etc.

EXAMPLES:
    $0 --list           # List snapshots with indices
    $0                  # Compare with most recent (index 0)
    $0 -n 1             # Compare with previous snapshot
    $0 -n 2             # Compare with snapshot from 2 boots ago

EOF
    exit "${1:-0}"
}

list_old_roots() {
    echo -e "${BLUE}Available snapshots:${NC}"
    echo

    if [ ! -d "$OLD_ROOTS_DIR" ]; then
        echo -e "${RED}Error: $OLD_ROOTS_DIR not found${NC}"
        exit 1
    fi

    local index=0
    while IFS= read -r dir || [ -n "$dir" ]; do
        local timestamp=$(basename "$dir")
        echo -e "${CYAN}[$index]${NC} ${GREEN}$timestamp${NC}"
        index=$((index + 1))
    done < <(find "$OLD_ROOTS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -r)

    echo
    echo "Total: $index snapshot(s)"
    echo "Use -n INDEX to select a specific snapshot"
}

get_old_root_by_index() {
    local index="${1:-0}"
    # index 0 = most recent, 1 = previous, etc.
    local skip=$((index + 1))
    find "$OLD_ROOTS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -r | head -n "$skip" | tail -n 1
}

get_all_old_roots() {
    find "$OLD_ROOTS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -r
}

perform_diff() {
    local old_root="$1"

    if [ ! -d "$old_root" ]; then
        echo -e "${RED}Error: Snapshot not found: $old_root${NC}"
        exit 1
    fi

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Snapshot: ${YELLOW}$(basename "$old_root")${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo

    # Build exclude expression for find
    local exclude_expr=""
    for dir in "${EXCLUDE_DIRS[@]}"; do
        if [ -z "$exclude_expr" ]; then
            exclude_expr="-path ${CURRENT_ROOT}${dir}"
        else
            exclude_expr="$exclude_expr -o -path ${CURRENT_ROOT}${dir}"
        fi
    done

    echo "Scanning current root..."
    local tmpfile_current=$(mktemp)
    local tmpfile_old=$(mktemp)

    trap "rm -f $tmpfile_current $tmpfile_old" EXIT

    # Get list of files/dirs in current root (excluding certain paths)
    sudo find "$CURRENT_ROOT" -mindepth 1 \( $exclude_expr \) -prune -o -print 2>/dev/null | \
        sed "s|^${CURRENT_ROOT}||" | grep -v '^$' | sort > "$tmpfile_current"

    echo "Scanning old snapshot..."
    # Get list of files/dirs in old root
    sudo find "$old_root" -mindepth 1 -print 2>/dev/null | \
        sed "s|^${old_root}/||" | sort > "$tmpfile_old"

    echo
    echo -e "${BLUE}Changes (excluding persisted paths):${NC}"
    echo

    local new_count=0
    local deleted_count=0
    local modified_count=0
    local processed_count=0
    local skipped_count=0

    # Find new files (in current but not in old)
    while IFS= read -r path || [ -n "$path" ]; do
        processed_count=$((processed_count + 1))

        # Skip persisted system paths
        local skip=false
        for persisted in "${PERSISTED_SYSTEM[@]}"; do
            if [[ "$path" == "$persisted" || "$path" == "$persisted/"* ]]; then
                skip=true
                skipped_count=$((skipped_count + 1))
                break
            fi
        done

        # Skip persisted home paths
        if [ "$skip" = false ]; then
            for persisted in "${PERSISTED_HOME[@]}"; do
                if [[ "$path" == "home/user/$persisted" || "$path" == "home/user/$persisted/"* ]]; then
                    skip=true
                    skipped_count=$((skipped_count + 1))
                    break
                fi
            done
        fi

        # Skip if this is a persisted path
        if [ "$skip" = true ]; then
            continue
        fi

        local current_path="${CURRENT_ROOT}${path}"
        local old_path="${old_root}/${path}"

        if [ ! -e "$old_path" ]; then
            if [ -d "$current_path" ]; then
                echo -e "${CYAN}[NEW DIR]${NC}  $path"
                new_count=$((new_count + 1))
            elif [ -f "$current_path" ]; then
                echo -e "${GREEN}[NEW FILE]${NC} $path"
                new_count=$((new_count + 1))
            elif [ -L "$current_path" ]; then
                echo -e "${YELLOW}[NEW LINK]${NC} $path"
                new_count=$((new_count + 1))
            fi
        elif [ -f "$current_path" ] && [ -d "$old_path" ]; then
            # Type changed: was directory, now file
            echo -e "${YELLOW}[DIR→FILE]${NC} $path"
            modified_count=$((modified_count + 1))
        elif [ -d "$current_path" ] && [ -f "$old_path" ]; then
            # Type changed: was file, now directory
            echo -e "${YELLOW}[FILE→DIR]${NC} $path"
            modified_count=$((modified_count + 1))
        elif [ -f "$current_path" ] && [ -f "$old_path" ]; then
            # Both are files - check if content modified
            if ! sudo cmp -s "$current_path" "$old_path" 2>/dev/null; then
                echo -e "${YELLOW}[MODIFIED]${NC} $path"
                modified_count=$((modified_count + 1))
            fi
        elif [ -L "$current_path" ] && [ ! -L "$old_path" ]; then
            # Type changed: was not a symlink, now is
            echo -e "${YELLOW}[→LINK]${NC}    $path"
            modified_count=$((modified_count + 1))
        elif [ ! -L "$current_path" ] && [ -L "$old_path" ]; then
            # Type changed: was a symlink, now isn't
            echo -e "${YELLOW}[LINK→]${NC}    $path"
            modified_count=$((modified_count + 1))
        fi
    done < "$tmpfile_current"

    # Find deleted files (in old but not in current)
    while IFS= read -r path || [ -n "$path" ]; do
        # Skip persisted system paths
        local skip=false
        for persisted in "${PERSISTED_SYSTEM[@]}"; do
            if [[ "$path" == "$persisted" || "$path" == "$persisted/"* ]]; then
                skip=true
                break
            fi
        done

        # Skip persisted home paths
        if [ "$skip" = false ]; then
            for persisted in "${PERSISTED_HOME[@]}"; do
                if [[ "$path" == "home/user/$persisted" || "$path" == "home/user/$persisted/"* ]]; then
                    skip=true
                    break
                fi
            done
        fi

        # Skip if this is a persisted path
        if [ "$skip" = true ]; then
            continue
        fi

        local current_path="${CURRENT_ROOT}${path}"

        if [ ! -e "$current_path" ]; then
            echo -e "${RED}[DELETED]${NC}  $path"
            deleted_count=$((deleted_count + 1))
        fi
    done < "$tmpfile_old"

    echo
    echo -e "${BLUE}Summary:${NC}"
    echo "  New:      $new_count"
    echo "  Modified: $modified_count"
    echo "  Deleted:  $deleted_count"
    echo "  Total:    $((new_count + modified_count + deleted_count))"
    echo "  (Skipped $skipped_count items in persisted paths)"
    echo
}

# Parse arguments
LIST_ONLY=false
COMPARE_ALL=false
SNAPSHOT_INDEX=0
OLD_ROOT_TIMESTAMP=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        -a|--all)
            COMPARE_ALL=true
            shift
            ;;
        -n)
            SNAPSHOT_INDEX="$2"
            shift 2
            ;;
        -h|--help)
            usage 0
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            usage 1
            ;;
        *)
            OLD_ROOT_TIMESTAMP="$1"
            shift
            ;;
    esac
done

# Main logic
if [ ! -d "$OLD_ROOTS_DIR" ]; then
    echo -e "${RED}Error: $OLD_ROOTS_DIR not found${NC}"
    exit 1
fi

if [ "$LIST_ONLY" = true ]; then
    list_old_roots
    exit 0
fi

if [ -n "$OLD_ROOT_TIMESTAMP" ]; then
    OLD_ROOT="${OLD_ROOTS_DIR}/${OLD_ROOT_TIMESTAMP}"
    if [ ! -d "$OLD_ROOT" ]; then
        echo -e "${RED}Error: Snapshot not found${NC}"
        list_old_roots
        exit 1
    fi
    perform_diff "$OLD_ROOT"
elif [ "$COMPARE_ALL" = true ]; then
    mapfile -t OLD_ROOTS < <(get_all_old_roots)

    if [ ${#OLD_ROOTS[@]} -eq 0 ]; then
        echo -e "${RED}No snapshots found${NC}"
        exit 1
    fi

    for old_root in "${OLD_ROOTS[@]}"; do
        perform_diff "$old_root"
    done
else
    OLD_ROOT=$(get_old_root_by_index "$SNAPSHOT_INDEX")
    if [ -z "$OLD_ROOT" ] || [ ! -d "$OLD_ROOT" ]; then
        echo -e "${RED}Error: Snapshot index $SNAPSHOT_INDEX not found${NC}"
        list_old_roots
        exit 1
    fi
    perform_diff "$OLD_ROOT"
fi

echo -e "${YELLOW}Tip: Add important files to impermanence configuration${NC}"
echo -e "${YELLOW}     See: impermenance.nix and home.nix${NC}"
