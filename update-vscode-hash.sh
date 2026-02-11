#!/usr/bin/env bash
# Update VSCode Latest Hash
#
# This script fetches the latest VSCode version and updates the sha256 hash
# in the vscode-latest overlay.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_FILE="$SCRIPT_DIR/overlays/vscode-latest.nix"
VSCODE_URL="https://update.code.visualstudio.com/latest/linux-x64/stable"

echo "Fetching latest VSCode from: $VSCODE_URL"
echo "This may take a moment..."

# Fetch the hash using nix-prefetch-url
NEW_HASH=$(nix-prefetch-url "$VSCODE_URL" 2>/dev/null)

if [ -z "$NEW_HASH" ]; then
    echo "Error: Failed to fetch hash"
    exit 1
fi

echo "New hash: $NEW_HASH"

# Update the overlay file
# Look for either lib.fakeSha256 or an existing hash and replace it
if grep -q "lib.fakeSha256" "$OVERLAY_FILE"; then
    sed -i "s|sha256 = super.lib.fakeSha256;|sha256 = \"$NEW_HASH\";|g" "$OVERLAY_FILE"
    echo "Updated overlay file with new hash"
elif grep -q 'sha256 = "sha256-' "$OVERLAY_FILE"; then
    sed -i "s|sha256 = \"sha256-[^\"]*\";|sha256 = \"$NEW_HASH\";|g" "$OVERLAY_FILE"
    echo "Updated overlay file with new hash"
else
    echo "Warning: Could not find hash placeholder in overlay file"
    echo "Please manually update the hash in: $OVERLAY_FILE"
    echo "New hash: $NEW_HASH"
fi

echo "Done! You can now rebuild your system with the latest VSCode."
