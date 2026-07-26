#!/usr/bin/env bash
# Update Nix overlay hashes
#
# Usage:
#   update-hashes.sh [TARGET]
#
# TARGET:
#   all          Update everything (default)
#   claude-code  Update Claude Code version and per-platform binary checksums
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
        all|claude-code) TARGET="$arg" ;;
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

    # Since v2.1.113 claude-code ships per-platform native binaries. The upstream
    # manifest.json records a hex sha256 checksum per platform — exactly what
    # fetchurl needs — so no need to download the (~250MB) binaries here.
    local manifest
    manifest=$(curl -fsSL "https://downloads.claude.ai/claude-code-releases/${latest_version}/manifest.json")

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

case "$TARGET" in
    all)
        update_claude_code
        ;;
    claude-code)
        update_claude_code
        ;;
esac

echo ""
echo "Run 'rebuild' to apply."
