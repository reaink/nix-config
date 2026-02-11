#!/usr/bin/env bash
# Update VSCode Latest Hash
#
# This script fetches the latest VSCode version and updates the sha256 hash
# in the vscode-latest overlay for the current platform.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_FILE="$SCRIPT_DIR/overlays/vscode-latest.nix"

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="darwin-arm64"
    PLATFORM_KEY="darwin-arm64"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux-x64"
    PLATFORM_KEY="linux-x64"
else
    echo "Error: Unsupported platform: $OSTYPE"
    exit 1
fi

VSCODE_URL="https://update.code.visualstudio.com/latest/$PLATFORM/stable"

echo "Detected platform: $PLATFORM"
echo "Fetching latest VSCode from: $VSCODE_URL"
echo "This may take a moment..."

# Fetch the hash using nix-prefetch-url
NEW_HASH=$(nix-prefetch-url "$VSCODE_URL" 2>/dev/null)

if [ -z "$NEW_HASH" ]; then
    echo "Error: Failed to fetch hash"
    exit 1
fi

echo "New hash for $PLATFORM: $NEW_HASH"

# Update the overlay file for the specific platform
# We need to find the line with the platform and update its hash
if [[ "$PLATFORM" == "darwin-arm64" ]]; then
    # Update Darwin hash line
    sed -i.bak "/platform = \"darwin-arm64\"/,/hash = / s|hash = super.lib.fakeSha256;|hash = \"$NEW_HASH\";|; s|hash = \"sha256-[^\"]*\";|hash = \"$NEW_HASH\";|" "$OVERLAY_FILE" || \
    sed -i.bak "/platform = \"darwin-arm64\"/,/hash = / s|hash = \"[^\"]*\";|hash = \"$NEW_HASH\";|" "$OVERLAY_FILE"
else
    # Update Linux hash line
    sed -i.bak "/platform = \"linux-x64\"/,/hash = / s|hash = super.lib.fakeSha256;|hash = \"$NEW_HASH\";|; s|hash = \"sha256-[^\"]*\";|hash = \"$NEW_HASH\";|" "$OVERLAY_FILE" || \
    sed -i.bak "/platform = \"linux-x64\"/,/hash = / s|hash = \"[^\"]*\";|hash = \"$NEW_HASH\";|" "$OVERLAY_FILE"
fi

# Check if update was successful
if grep -q "$NEW_HASH" "$OVERLAY_FILE"; then
    echo "✓ Successfully updated overlay file with new hash for $PLATFORM"
    rm -f "$OVERLAY_FILE.bak"
else
    echo "Warning: Could not automatically update hash in overlay file"
    echo "Please manually update the hash for $PLATFORM in: $OVERLAY_FILE"
    echo "New hash: $NEW_HASH"
    # Restore backup if update failed
    if [ -f "$OVERLAY_FILE.bak" ]; then
        mv "$OVERLAY_FILE.bak" "$OVERLAY_FILE"
    fi
fi

echo "Done! You can now rebuild your system with the latest VSCode."
