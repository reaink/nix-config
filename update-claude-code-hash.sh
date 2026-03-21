#!/usr/bin/env bash
# Update Claude Code hashes in overlays/claude-code-latest.nix
#
# Fetches the latest version info from npm registry and updates:
#   - version
#   - src hash (from dist.integrity in npm metadata)
#   - npmDepsHash (via prefetch-npm-deps on package-lock.json)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_FILE="$SCRIPT_DIR/overlays/claude-code-latest.nix"

echo "Fetching latest @anthropic-ai/claude-code info from npm..."

METADATA=$(curl -fsSL "https://registry.npmjs.org/@anthropic-ai/claude-code/latest")
LATEST_VERSION=$(echo "$METADATA" | jq -r '.version')
SRC_HASH=$(echo "$METADATA" | jq -r '.dist.integrity')
TARBALL_URL=$(echo "$METADATA" | jq -r '.dist.tarball')

CURRENT_VERSION=$(grep -oP 'version = "\K[^"]+' "$OVERLAY_FILE" | head -1)

echo "Current version: $CURRENT_VERSION"
echo "Latest version:  $LATEST_VERSION"

if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
  echo "Already up to date."
  exit 0
fi

echo "Updating to $LATEST_VERSION..."
echo "  src hash: $SRC_HASH"

# Compute npmDepsHash via prefetch-npm-deps on package-lock.json from the tarball
echo "  Computing npmDepsHash (downloading tarball)..."
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

curl -fsSL "$TARBALL_URL" -o "$TMPDIR/pkg.tgz"
tar -xzf "$TMPDIR/pkg.tgz" -C "$TMPDIR"

LOCKFILE="$TMPDIR/package/package-lock.json"
if [[ -f "$LOCKFILE" ]]; then
  NPM_DEPS_HASH=$(nix run nixpkgs#prefetch-npm-deps -- "$LOCKFILE" 2>/dev/null)
  echo "  npmDepsHash: $NPM_DEPS_HASH"
else
  echo "  Warning: package-lock.json not found, using empty hash"
  NPM_DEPS_HASH="sha256-$(echo -n '{}' | nix hash file --sri /dev/stdin 2>/dev/null || echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==')"
fi

# Update overlay file
sed -i \
  -e "s|version = \"[^\"]*\"; # Updated by update-claude-code-hash.sh|version = \"${LATEST_VERSION}\"; # Updated by update-claude-code-hash.sh|" \
  -e "s|hash = \"[^\"]*\"; # Updated by update-claude-code-hash.sh|hash = \"${SRC_HASH}\"; # Updated by update-claude-code-hash.sh|" \
  -e "s|npmDepsHash = \"[^\"]*\"; # Updated by update-claude-code-hash.sh|npmDepsHash = \"${NPM_DEPS_HASH}\"; # Updated by update-claude-code-hash.sh|" \
  "$OVERLAY_FILE"

echo "Done! Updated claude-code to $LATEST_VERSION"
echo "Run 'rebuild' to apply."
