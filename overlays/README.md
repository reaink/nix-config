# Custom Overlays

This directory contains custom Nix overlays for packages that need special handling or the latest versions.

## VSCode Latest

The `vscode-latest.nix` overlay provides a `vscode-latest` package that always fetches the latest stable version directly from Microsoft's official download server.

### Why?

The VSCode package in nixpkgs (even on unstable channel) can lag behind official releases by days or weeks. This overlay ensures you always have access to the absolute latest version.

### How it works

The overlay fetches VSCode from:
```
https://update.code.visualstudio.com/latest/linux-x64/stable
```

This URL always redirects to the newest stable release tarball.

### Updating the hash

When Microsoft releases a new VSCode version, the content at the URL changes but the URL stays the same. This means you need to update the SHA256 hash in the overlay.

#### Method 1: Using the update script (Recommended)

Run the provided update script from the repository root:

```bash
./update-vscode-hash.sh
```

This will automatically fetch the latest version and update the hash in the overlay file.

#### Method 2: Manual update

1. Run `nix-prefetch-url` to get the current hash:
   ```bash
   nix-prefetch-url https://update.code.visualstudio.com/latest/linux-x64/stable
   ```

2. Update the `sha256` value in `vscode-latest.nix` with the output

3. Rebuild your system:
   ```bash
   # NixOS
   sudo nixos-rebuild switch --flake .#nixos
   
   # macOS
   darwin-rebuild switch --flake .#mac
   ```

### Usage

The `vscode-latest` package is already configured in `home/rea/common.nix`. It will be available on both NixOS and macOS systems.

### First-time setup

On first build, if the hash is set to `lib.fakeSha256`, Nix will fail with an error message showing the correct hash. This is intentional - simply run the update script or manually update the hash as described above, then rebuild.
