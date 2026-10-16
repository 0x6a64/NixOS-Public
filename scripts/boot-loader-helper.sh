#!/usr/bin/env bash

# Marker-based toggling of the boot loader blocks in configuration.nix,
# instead of fragile sed regexes. Sourced by install.sh and post-install.sh.

MARKER_SYSTEMD_BEGIN="BEGIN_NIXOS_BOOT_SYSTEMD_BOOT"
MARKER_SYSTEMD_END="END_NIXOS_BOOT_SYSTEMD_BOOT"
MARKER_LANZABOOT_BEGIN="BEGIN_NIXOS_BOOT_LANZABOOTE"
MARKER_LANZABOOT_END="END_NIXOS_BOOT_LANZABOOTE"

# Returns 0 if all four markers are present in $1 (configuration.nix)
validate_markers_exist() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        echo "ERROR: Configuration file not found: $config_file"
        return 1
    fi

    local markers_found=0

    if 'grep' -q "$MARKER_SYSTEMD_BEGIN" "$config_file"; then
        ((markers_found++))
    else
        echo "ERROR: Marker not found: $MARKER_SYSTEMD_BEGIN"
    fi

    if 'grep' -q "$MARKER_SYSTEMD_END" "$config_file"; then
        ((markers_found++))
    else
        echo "ERROR: Marker not found: $MARKER_SYSTEMD_END"
    fi

    if 'grep' -q "$MARKER_LANZABOOT_BEGIN" "$config_file"; then
        ((markers_found++))
    else
        echo "ERROR: Marker not found: $MARKER_LANZABOOT_BEGIN"
    fi

    if 'grep' -q "$MARKER_LANZABOOT_END" "$config_file"; then
        ((markers_found++))
    else
        echo "ERROR: Marker not found: $MARKER_LANZABOOT_END"
    fi

    if [ $markers_found -eq 4 ]; then
        return 0
    else
        return 1
    fi
}

# Uncomments the lines between $2 and $3 in $1 (markers themselves untouched)
toggle_block_enable() {
    local config_file="$1"
    local begin_marker="$2"
    local end_marker="$3"

    if [ ! -f "$config_file" ]; then
        echo "ERROR: Configuration file not found: $config_file"
        return 1
    fi

    # Write to /tmp first since the config dir is root-owned
    local tmp_file="/tmp/boot-loader-config-$$.tmp"
    awk -v begin="$begin_marker" -v end="$end_marker" '
    BEGIN { in_block = 0 }
    $0 ~ begin { print; in_block = 1; next }
    $0 ~ end { in_block = 0; print; next }
    in_block {
        if (match($0, /^([[:space:]]*)# (.*)$/, arr)) {
            print arr[1] arr[2]
        } else {
            print
        }
        next
    }
    { print }
    ' "$config_file" > "$tmp_file" || return 1

    sudo mv "$tmp_file" "$config_file" || return 1
    return 0
}

# Comments out the lines between $2 and $3 in $1 (markers themselves untouched)
toggle_block_disable() {
    local config_file="$1"
    local begin_marker="$2"
    local end_marker="$3"

    if [ ! -f "$config_file" ]; then
        echo "ERROR: Configuration file not found: $config_file"
        return 1
    fi

    # Write to /tmp first since the config dir is root-owned
    local tmp_file="/tmp/boot-loader-config-$$.tmp"
    awk -v begin="$begin_marker" -v end="$end_marker" '
    BEGIN { in_block = 0 }
    $0 ~ begin { print; in_block = 1; next }
    $0 ~ end { in_block = 0; print; next }
    in_block {
        if (!match($0, /^[[:space:]]*#/)) {
            if (match($0, /^([[:space:]]*)(.*)$/, arr)) {
                print arr[1] "# " arr[2]
            } else {
                print "# " $0
            }
        } else {
            print
        }
        next
    }
    { print }
    ' "$config_file" > "$tmp_file" || return 1

    sudo mv "$tmp_file" "$config_file" || return 1
    return 0
}

# Returns 0 if $1 has balanced markers and exactly one block active
validate_boot_config() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        echo "ERROR: Configuration file not found: $config_file"
        return 1
    fi

    if ! validate_markers_exist "$config_file"; then
        return 1
    fi

    local active_count=0

    # A block is active when its enable line is uncommented
    if awk -v begin="$MARKER_SYSTEMD_BEGIN" -v end="$MARKER_SYSTEMD_END" '
        BEGIN { in_block = 0; found = 0 }
        $0 ~ begin { in_block = 1; next }
        $0 ~ end { in_block = 0; next }
        in_block && /^[[:space:]]*boot\.loader\.systemd-boot[[:space:]]*=/ && !/^[[:space:]]*#/ { found = 1 }
        END { exit !found }
    ' "$config_file"; then
        ((active_count++))
    fi

    if awk -v begin="$MARKER_LANZABOOT_BEGIN" -v end="$MARKER_LANZABOOT_END" '
        BEGIN { in_block = 0; found = 0 }
        $0 ~ begin { in_block = 1; next }
        $0 ~ end { in_block = 0; next }
        in_block && /^[[:space:]]*boot\.lanzaboote[[:space:]]*=/ && !/^[[:space:]]*#/ { found = 1 }
        END { exit !found }
    ' "$config_file"; then
        ((active_count++))
    fi

    if [ $active_count -eq 1 ]; then
        return 0
    elif [ $active_count -eq 0 ]; then
        echo "ERROR: No boot loader is active (both blocks are commented)"
        return 1
    else
        echo "ERROR: Multiple boot loaders are active (both blocks are uncommented)"
        return 1
    fi
}

# Echoes "systemd-boot", "lanzaboote", or "error" for the config file $1
get_active_boot_loader() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        echo "error"
        return 1
    fi

    if awk -v begin="$MARKER_SYSTEMD_BEGIN" -v end="$MARKER_SYSTEMD_END" '
        BEGIN { in_block = 0; found = 0 }
        $0 ~ begin { in_block = 1; next }
        $0 ~ end { in_block = 0; next }
        in_block && /^[[:space:]]*boot\.loader\.systemd-boot[[:space:]]*=/ && !/^[[:space:]]*#/ { found = 1 }
        END { exit !found }
    ' "$config_file"; then
        echo "systemd-boot"
        return 0
    fi

    if awk -v begin="$MARKER_LANZABOOT_BEGIN" -v end="$MARKER_LANZABOOT_END" '
        BEGIN { in_block = 0; found = 0 }
        $0 ~ begin { in_block = 1; next }
        $0 ~ end { in_block = 0; next }
        in_block && /^[[:space:]]*boot\.lanzaboote[[:space:]]*=/ && !/^[[:space:]]*#/ { found = 1 }
        END { exit !found }
    ' "$config_file"; then
        echo "lanzaboote"
        return 0
    fi

    echo "error"
    return 1
}

