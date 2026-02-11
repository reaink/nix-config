# Custom Overlays

This directory contains custom Nix overlays for packages that need special handling or the latest versions.

## VSCode Latest

The `vscode-latest.nix` overlay provides a `vscode-latest` package that always fetches the latest stable version directly from Microsoft's official download server.

### Why?

The VSCode package in nixpkgs (even on unstable channel) can lag behind official releases by days or weeks. This overlay ensures you always have access to the absolute latest version.

### Platform Support

✅ **Linux (x86_64)** - Downloads from `linux-x64` endpoint  
✅ **macOS (Apple Silicon)** - Downloads from `darwin-arm64` endpoint

The overlay automatically detects your platform and fetches the appropriate version.

### How it works

The overlay fetches VSCode from platform-specific URLs:
- **Linux**: `https://update.code.visualstudio.com/latest/linux-x64/stable`
- **macOS**: `https://update.code.visualstudio.com/latest/darwin-arm64/stable`

These URLs always redirect to the newest stable release for each platform.

### Updating the hash

When Microsoft releases a new VSCode version, the content at the URL changes but the URL stays the same. This means you need to update the SHA256 hash in the overlay for your platform.

#### Method 1: Using the update script (Recommended)

Run the provided update script from the repository root:

```bash
./update-vscode-hash.sh
```

The script automatically detects your platform and updates the corresponding hash.

#### Method 2: Manual update

1. Run `nix-prefetch-url` to get the current hash for your platform:
   ```bash
   # On Linux:
   nix-prefetch-url https://update.code.visualstudio.com/latest/linux-x64/stable
   
   # On macOS:
   nix-prefetch-url https://update.code.visualstudio.com/latest/darwin-arm64/stable
   ```

2. Update the corresponding `hash` value in `vscode-latest.nix`:
   - For Linux: Update the hash in the `linux-x64` platform block
   - For macOS: Update the hash in the `darwin-arm64` platform block

3. Rebuild your system:
   ```bash
   # NixOS
   sudo nixos-rebuild switch --flake .#nixos
   
   # macOS
   darwin-rebuild switch --flake .#mac
   ```

### Usage

The `vscode-latest` package is already configured in `home/rea/common.nix`. It will be available on both NixOS and macOS systems with platform-appropriate binaries.

### First-time setup

On first build, if the hash is set to `lib.fakeSha256`, Nix will fail with an error message showing the correct hash. This is intentional - simply run the update script or manually update the hash as described above, then rebuild.
