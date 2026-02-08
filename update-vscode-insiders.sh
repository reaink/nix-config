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

if ! prefetch_output=$(nix-prefetch-url --unpack --name "vscode-insiders" "$url" 2>&1); then
  echo "Failed to fetch sha256"
  echo "$prefetch_output"
  exit 1
fi

sha256=$(printf '%s\n' "$prefetch_output" | tail -n1)

if [ -z "$sha256" ] || ! echo "$sha256" | grep -Eq '^[0-9a-z]{52}$'; then
  echo "Fetcher returned invalid sha256"
  echo "$prefetch_output"
  exit 1
fi

echo "Latest sha256: $sha256"

# Update the nix file (without quotes)
nix_file="vscode-insiders-sha256.nix"
echo "$sha256" > "$nix_file"

echo "✓ Updated $nix_file"
echo "Now run: rebuild"
