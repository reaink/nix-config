---
name: nix-home-manager
description: NixOS + Home Manager declarative config patterns for this machine (flake at ~/nix-config)
license: MIT
compatibility: opencode
---

## Machine Context
- Flake: `~/nix-config`, target `nixos` (x86_64-linux), unstable channel
- Rebuild: `sudo nixos-rebuild switch --flake ~/nix-config#nixos`
- Check: `nix flake check --no-build`

## File Layout
```
home/rea/common.nix       # cross-platform packages & programs
home/rea/linux.nix        # Linux-only packages, GTK, KDE Plasma
home/rea/opencode.nix     # opencode config (xdg.configFile)
hosts/nixos/              # system-level NixOS config
modules/                  # shared modules
overlays/                 # package overrides
```

## Rules
- User packages: add to `home.packages` in `common.nix` (cross-platform) or `linux.nix` (Linux-only).
- System services: edit `hosts/nixos/configuration.nix`.
- All user files go via `xdg.configFile` or `home.file`, never written imperatively.
- New nix files must be `git add`-ed before `nix flake check` can see them.
- Prefer `lib.mkIf`, `lib.mkMerge`, `let … in` over deeply nested attrsets.
- After any nix change: run `nix flake check --no-build` first, then rebuild.
