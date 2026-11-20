# Custom Overlays

This directory contains custom Nix overlays for packages that need special handling or newer versions than the locked nixpkgs provides.

## Claude Code Latest

The `claude-code-latest.nix` overlay overrides nixpkgs' `claude-code` so it tracks the latest release from Anthropic instead of whatever version is pinned in the locked nixpkgs.

### Why?

The `claude-code` package in nixpkgs can lag behind the latest npm/Anthropic release by days. This overlay lets the config pick up new versions without waiting for a `nix flake update`.

### How it works

Since v2.1.113, `claude-code` ships as per-platform **native binaries** (no `cli.js`). nixpkgs packages this by fetching the raw `claude` binary from `downloads.claude.ai` and verifying it against the sha256 checksum recorded in the upstream `manifest.json`.

This overlay is a *minimal* override on top of that model: it only bumps the `version` and the per-platform binary checksums, inheriting `installPhase`, the wrapper, `meta`, and the install check from nixpkgs. Because `claude-code` lives in the shared `home/rea/common.nix` package list, the overlay carries a checksum for both hosts:

- **macOS (Apple Silicon)** — `darwin-arm64`
- **NixOS (x86_64)** — `linux-x64`

The overlay is wired into both `nixpkgs.overlays` lists in `flake.nix` (darwin and nixos).

### Updating

Run the update script from the repository root:

```bash
sh ~/nix-config/update-hashes.sh claude-code
```

The script:

1. Reads the latest version from the npm registry (`@anthropic-ai/claude-code`).
2. Fetches `manifest.json` for that version from `downloads.claude.ai`.
3. Writes the version and both platform checksums into `claude-code-latest.nix` via its sed-marker comments.

There is also a `update-claude` shell alias and a `update` alias (`nix flake update && update-hashes.sh`) defined in `home/rea/common.nix`.

Then rebuild:

```bash
# macOS
darwin-rebuild switch --flake ~/nix-config#mac

# NixOS
sudo nixos-rebuild switch --flake ~/nix-config#nixos
```

## Other overlays

- `vercel-cli.nix` — packages the `vercel` CLI (darwin only).
- `fix-openldap-tests.nix`, `fix-libkgapi-gcc15-ice.nix`, `onlyoffice-cjk-fonts.nix` — NixOS-side build fixes / tweaks.
