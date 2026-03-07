#!/usr/bin/env bash
# Update VSCode Latest Hash
#
# Uses the VSCode update API to fetch sha256 hashes directly — no download needed.
# API endpoint: https://update.code.visualstudio.com/api/update/{platform}/stable/0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_FILE="$SCRIPT_DIR/overlays/vscode-latest.nix"

echo "Updating VSCode hashes for ALL platforms..."

for PLATFORM in darwin-arm64 linux-x64; do
    echo "Processing $PLATFORM..."

    API_URL="https://update.code.visualstudio.com/api/update/${PLATFORM}/stable/0000000000000000000000000000000000000000"
    HEX_HASH=$(curl -fsSL "$API_URL" | uv run python -c "import sys,json; print(json.load(sys.stdin)['sha256hash'])")

    if [[ -z "$HEX_HASH" ]]; then
        echo "  Error: Failed to fetch hash for $PLATFORM"
        continue
    fi

    # Convert hex SHA256 to SRI format (sha256-<base64>) accepted by Nix fetchurl
    SRI_HASH=$(uv run python -c "import sys,base64,binascii; print('sha256-'+base64.b64encode(binascii.unhexlify('${HEX_HASH}')).decode())")
    echo "  New hash: $SRI_HASH"

    sed -i "s|hash = \"[^\"]*\"; # Update with: nix-prefetch-url https://update.code.visualstudio.com/latest/${PLATFORM}/stable|hash = \"${SRI_HASH}\"; # Update with: nix-prefetch-url https://update.code.visualstudio.com/latest/${PLATFORM}/stable|" "$OVERLAY_FILE"

    if grep -qF "$SRI_HASH" "$OVERLAY_FILE"; then
        echo "  Done: $PLATFORM"
    else
        echo "  Warning: Failed to verify update for $PLATFORM"
    fi
done

echo "Done! Both macOS and Linux hashes have been updated."
