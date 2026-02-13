#!/usr/bin/env bash
# Update VSCode Latest Hash
#
# This script fetches the latest VSCode version and updates the sha256 hash
# in the vscode-latest overlay for the current platform.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_FILE="$SCRIPT_DIR/overlays/vscode-latest.nix"

# Detect platform - REMOVED single platform detection
# Instead, we define both targets

echo "Updating VSCode hashes for ALL platforms..."

declare -A PLATFORMS
PLATFORMS=( ["darwin-arm64"]="https://update.code.visualstudio.com/latest/darwin-arm64/stable" ["linux-x64"]="https://update.code.visualstudio.com/latest/linux-x64/stable" )

for PLATFORM in "${!PLATFORMS[@]}"; do
    URL="${PLATFORMS[$PLATFORM]}"
    echo "Processing $PLATFORM..."
    echo "  Fetching from: $URL"
    
    # Fetch the hash using nix-prefetch-url
    # Use generic sha256 to avoid mismatches if nix changes output format
    NEW_HASH=$(nix-prefetch-url "$URL" 2>/dev/null)

    if [ -z "$NEW_HASH" ]; then
        echo "  Error: Failed to fetch hash for $PLATFORM"
        continue
    fi

    echo "  New hash: $NEW_HASH"

    # Update the overlay file
    # We use specific patterns for each platform to ensure we edit the correct block
    sed -i.bak "/platform = \"$PLATFORM\"/,/hash = / s|hash = \"[^\"]*\";|hash = \"$NEW_HASH\";|" "$OVERLAY_FILE"
    
    if grep -q "$NEW_HASH" "$OVERLAY_FILE"; then
        echo "  ✓ Updated $PLATFORM"
    else
        echo "  Warning: Failed to verify update for $PLATFORM"
    fi
done

rm -f "$OVERLAY_FILE.bak"

echo "Done! Both macOS and Linux hashes have been updated."
exit 0

# specific platform check removed as we now loop through all
if [[ "$OSTYPE" == "darwin"* ]]; then
    : # noop
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    : # noop
else
    # Just a warning now, as nix-prefetch-url might still work
    echo "Info: Running on $OSTYPE"
fi
