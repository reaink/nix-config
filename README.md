# NixOS Configuration

Personal NixOS configuration with sops-nix for secret management.

## Features

- **Desktop Environment**: KDE Plasma 6 with Wayland
- **Secret Management**: sops-nix with age encryption
- **Database**: PostgreSQL 16 with secure password management
- **Development**: Neovim, Git, various fonts
- **Virtualization**: libvirt and virt-manager
- **Input Method**: fcitx5 with multiple IMEs

## Quick Start

1. **Clone and build**:
   ```bash
   sudo nixos-rebuild switch --flake '.#nixos'
   ```

2. **Manage secrets**:
   ```bash
   # Edit secrets (auto decrypt/encrypt)
   EDITOR=nvim sops secrets/secrets.yaml
   
   # Apply changes
   sudo nixos-rebuild switch --flake '.#nixos'
   ```

## Secret Management

This configuration uses [sops-nix](https://github.com/Mic92/sops-nix) with age encryption for secure secret management.

### Key Files
- `secrets/secrets.yaml` - Encrypted secrets
- `.sops.yaml` - Sops configuration
- `/home/rea/.config/sops/age/keys.txt` - Age private key ⚠️ **Backup this file!**

### PostgreSQL Passwords
PostgreSQL user passwords are automatically managed through sops:
- `postgres-password` - postgres user password
- `rea-password` - rea user password

See `PASSWORD_MANAGEMENT.md` for detailed instructions.

## System Info

- **User**: rea
- **Hostname**: nixos
- **Architecture**: x86_64-linux
- **Kernel**: Latest Linux kernel
- **Graphics**: NVIDIA with open drivers

## Structure

```
├── configuration.nix      # Main NixOS configuration
├── flake.nix             # Nix flake definition
├── home.nix              # Home Manager configuration
├── hardware-configuration.nix  # Hardware-specific config
├── secrets/
│   └── secrets.yaml      # Encrypted secrets
└── .sops.yaml           # Sops configuration
```

## Maintenance

```bash
# Update system
sudo nixos-rebuild switch --flake '.#nixos'

# Update flake inputs
nix flake update

# Garbage collection
sudo nix-collect-garbage -d
```
