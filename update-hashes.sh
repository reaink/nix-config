#!/usr/bin/env bash
# Update versions and hashes for packages outside nixpkgs
#
# Usage:
#   update-hashes.sh [TARGET]
#
# TARGET:
#   all          Update everything (default)
#   claude-code  Update Claude Code version and per-platform binary checksums
#   orca-ide     Update Orca IDE version and per-platform binary checksums
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# macOS sed requires an explicit empty string for in-place edit without backup
if [[ "$(uname)" == "Darwin" ]]; then
    SED_INPLACE=(sed -i '')
else
    SED_INPLACE=(sed -i)
fi

TARGET="all"

for arg in "$@"; do
    case "$arg" in
        all|claude-code|orca-ide) TARGET="$arg" ;;
        *) echo "Unknown argument: $arg"; exit 1 ;;
    esac
done

update_claude_code() {
    local overlay="$SCRIPT_DIR/overlays/claude-code-latest.nix"
    echo "==> Updating Claude Code..."

    # Version comes from the npm registry (the canonical "latest" pointer).
    local latest_version
    latest_version=$(curl -fsSL "https://registry.npmjs.org/@anthropic-ai/claude-code/latest" | jq -r '.version')

    local current_version
    current_version=$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$overlay" | head -1)

    echo "  current: $current_version"
    echo "  latest:  $latest_version"

    # Since v2.1.113 claude-code ships per-platform native binaries; nixpkgs
    # fetches the zstd-compressed claude.zst, whose sha256 lives in the upstream
    # manifest.zst.json — exactly what fetchurl needs, no binary download here.
    local manifest
    manifest=$(curl -fsSL "https://downloads.claude.ai/claude-code-releases/${latest_version}/manifest.zst.json")

    # The overlay tracks two platforms: this mac (darwin-arm64) and the nixos host (linux-x64).
    for platform in darwin-arm64 linux-x64; do
        local checksum
        checksum=$(echo "$manifest" | jq -r ".platforms[\"${platform}\"].checksum")

        if [[ -z "$checksum" || "$checksum" == "null" ]]; then
            echo "  [$platform] Error: no checksum in manifest for $latest_version"
            exit 1
        fi

        "${SED_INPLACE[@]}" \
            "s|\"${platform}\" = \"[^\"]*\"; # Updated by update-hashes.sh (${platform})|\"${platform}\" = \"${checksum}\"; # Updated by update-hashes.sh (${platform})|" \
            "$overlay"

        if grep -qF "$checksum" "$overlay"; then
            echo "  [$platform] $checksum"
        else
            echo "  [$platform] Warning: failed to verify update"
        fi
    done

    # Bump the version last, after both checksums are in place.
    "${SED_INPLACE[@]}" \
        "s|version = \"[^\"]*\"; # Updated by update-hashes.sh|version = \"${latest_version}\"; # Updated by update-hashes.sh|" \
        "$overlay"

    echo "==> Claude Code updated to $latest_version."
}

update_orca_ide() {
    local package="$SCRIPT_DIR/pkgs/orca-ide.nix"
    echo "==> Updating Orca IDE..."

    local release
    if ! { command -v gh >/dev/null 2>&1 && release=$(gh api repos/stablyai/orca/releases/latest); }; then
        release=$(curl -fsSL --retry 2 "https://api.github.com/repos/stablyai/orca/releases/latest")
    fi

    local latest_version
    latest_version=$(echo "$release" | jq -er '.tag_name | select(test("^v[0-9]+\\.[0-9]+\\.[0-9]+$")) | ltrimstr("v")')
    echo "  latest: $latest_version"

    # Validate both published digests before changing the Nix expression.
    local linux_checksum darwin_checksum
    linux_checksum=$(echo "$release" | jq -er '.assets[] | select(.name == "orca-linux.AppImage") | .digest | select(test("^sha256:[0-9a-f]{64}$")) | ltrimstr("sha256:")')
    darwin_checksum=$(echo "$release" | jq -er --arg name "Orca-${latest_version}-arm64-mac.zip" '.assets[] | select(.name == $name) | .digest | select(test("^sha256:[0-9a-f]{64}$")) | ltrimstr("sha256:")')

    local updated_package
    updated_package=$(sed \
        -e "s|version = \"[^\"]*\"; # Updated by update-hashes.sh (orca-ide)|version = \"${latest_version}\"; # Updated by update-hashes.sh (orca-ide)|" \
        -e "s|sha256 = \"[^\"]*\"; # Updated by update-hashes.sh (orca-ide x86_64-linux)|sha256 = \"${linux_checksum}\"; # Updated by update-hashes.sh (orca-ide x86_64-linux)|" \
        -e "s|sha256 = \"[^\"]*\"; # Updated by update-hashes.sh (orca-ide aarch64-darwin)|sha256 = \"${darwin_checksum}\"; # Updated by update-hashes.sh (orca-ide aarch64-darwin)|" \
        "$package")
    if ! grep -qF "version = \"${latest_version}\"; # Updated by update-hashes.sh (orca-ide)" <<< "$updated_package"; then
        echo "  Error: failed to update Orca IDE version" >&2
        return 1
    fi
    for checksum in "$linux_checksum" "$darwin_checksum"; do
        if ! grep -qF "$checksum" <<< "$updated_package"; then
            echo "  Error: failed to update Orca IDE checksum" >&2
            return 1
        fi
    done
    printf '%s\n' "$updated_package" > "$package"
    echo "==> Orca IDE updated to $latest_version."
}

case "$TARGET" in
    all)
        update_claude_code
        update_orca_ide
        ;;
    claude-code)
        update_claude_code
        ;;
    orca-ide)
        update_orca_ide
        ;;
esac

echo ""
echo "Run 'rebuild' to apply."
