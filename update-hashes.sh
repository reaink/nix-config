#!/usr/bin/env bash
# Update Nix overlay hashes
#
# Usage:
#   update-hashes.sh [TARGET] [--force]
#
# TARGET:
#   all          Update everything (default)
#   vscode       Update VSCode hashes for all platforms
#   claude-code  Update Claude Code version and npm deps hash
#
# --force: Re-compute claude-code hashes even if version is unchanged

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET="all"
FORCE=false

for arg in "$@"; do
    case "$arg" in
        all|vscode|claude-code) TARGET="$arg" ;;
        --force) FORCE=true ;;
        *) echo "Unknown argument: $arg"; exit 1 ;;
    esac
done

update_vscode() {
    local overlay="$SCRIPT_DIR/overlays/vscode-latest.nix"
    echo "==> Updating VSCode hashes..."

    for platform in darwin-arm64 linux-x64; do
        echo "  [$platform] Fetching..."
        local api_url="https://update.code.visualstudio.com/api/update/${platform}/stable/0000000000000000000000000000000000000000"
        local hex_hash
        hex_hash=$(curl -fsSL "$api_url" | uv run python -c "import sys,json; print(json.load(sys.stdin)['sha256hash'])")

        if [[ -z "$hex_hash" ]]; then
            echo "  [$platform] Error: failed to fetch hash"
            continue
        fi

        local sri_hash
        sri_hash=$(uv run python -c "import sys,base64,binascii; print('sha256-'+base64.b64encode(binascii.unhexlify('${hex_hash}')).decode())")

        sed -i "s|hash = \"[^\"]*\"; # Update with: nix-prefetch-url https://update.code.visualstudio.com/latest/${platform}/stable|hash = \"${sri_hash}\"; # Update with: nix-prefetch-url https://update.code.visualstudio.com/latest/${platform}/stable|" "$overlay"

        if grep -qF "$sri_hash" "$overlay"; then
            echo "  [$platform] $sri_hash"
        else
            echo "  [$platform] Warning: failed to verify update"
        fi
    done

    echo "==> VSCode done."
}

update_claude_code() {
    local overlay="$SCRIPT_DIR/overlays/claude-code-latest.nix"
    echo "==> Updating Claude Code..."

    local metadata latest_version tarball_url
    metadata=$(curl -fsSL "https://registry.npmjs.org/@anthropic-ai/claude-code/latest")
    latest_version=$(echo "$metadata" | jq -r '.version')
    tarball_url=$(echo "$metadata" | jq -r '.dist.tarball')

    local current_version
    current_version=$(grep -oP 'version = "\K[^"]+' "$overlay" | head -1)

    echo "  current: $current_version"
    echo "  latest:  $latest_version"

    if [[ "$current_version" == "$latest_version" ]] && [[ "$FORCE" == false ]]; then
        echo "==> Claude Code already up to date. Use --force to re-compute hashes."
        return
    fi

    # Compute src hash (fetchzip = recursive NAR SHA256 of unpacked tarball)
    echo "  Downloading tarball to compute hashes..."
    local tmpdir
    tmpdir=$(mktemp -d)
    trap "rm -rf $tmpdir" RETURN

    curl -fsSL "$tarball_url" -o "$tmpdir/pkg.tgz"
    tar -xzf "$tmpdir/pkg.tgz" -C "$tmpdir"

    # Recursive NAR hash matches what fetchzip expects
    local src_hash
    src_hash=$(nix --extra-experimental-features 'nix-command flakes' hash path --sri "$tmpdir/package" 2>/dev/null)
    echo "  src hash (fetchzip NAR): $src_hash"

    # Update version and src hash
    sed -i \
        -e "s|version = \"[^\"]*\"; # Updated by update-hashes.sh|version = \"${latest_version}\"; # Updated by update-hashes.sh|" \
        -e "s|hash = \"[^\"]*\"; # Updated by update-hashes.sh (src)|hash = \"${src_hash}\"; # Updated by update-hashes.sh (src)|" \
        "$overlay"

    # npmDepsHash is intentionally not managed here.
    # nixpkgs vendors the package-lock.json and maintains npmDepsHash.
    # If npmDeps need updating after a nixpkgs bump, that's handled by nixpkgs.

    echo "==> Claude Code updated to $latest_version."
}

case "$TARGET" in
    all)
        update_vscode
        update_claude_code
        ;;
    vscode)
        update_vscode
        ;;
    claude-code)
        update_claude_code
        ;;
esac

echo ""
echo "Run 'rebuild' to apply."
