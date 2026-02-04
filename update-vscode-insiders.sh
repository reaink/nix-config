#!/usr/bin/env bash
# Auto-update VS Code Insiders sha256

set -e

# Detect platform
case "$(uname -m)-$(uname -s)" in
  x86_64-Linux)
    platform="linux-x64"
    ;;
  aarch64-Linux)
    platform="linux-arm64"
    ;;
  x86_64-Darwin)
    platform="darwin"
    ;;
  arm64-Darwin)
    platform="darwin-arm64"
    ;;
  *)
    echo "Unsupported platform: $(uname -m)-$(uname -s)"
    exit 1
    ;;
esac

echo "Platform: $platform"
echo "Fetching latest VS Code Insiders..."
url="https://code.visualstudio.com/sha/download?build=insider&os=$platform"

# Use nix-prefetch-url to get the sha256
sha256=$(nix-prefetch-url --unpack --name "vscode-insiders" "$url" 2>&1 | tail -n1)

if [ -z "$sha256" ]; then
    echo "Failed to fetch sha256"
    exit 1
fi

echo "Latest sha256: $sha256"

# Update the nix file (without quotes)
nix_file="vscode-insiders-sha256.nix"
echo "$sha256" > "$nix_file"

echo "✓ Updated $nix_file"
echo "Now run: rebuild"
