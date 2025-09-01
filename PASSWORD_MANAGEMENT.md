# 🔐 Sops Password Management Guide

This document explains how to manage PostgreSQL passwords using sops-nix in NixOS.

## 📁 File Structure

```
/home/rea/nix-config/
├── .sops.yaml                    # sops configuration
├── secrets/
│   └── secrets.yaml              # encrypted passwords file
├── configuration.nix             # NixOS configuration
└── flake.nix                     # Nix flake configuration

/home/rea/.config/sops/age/
└── keys.txt                      # Age private key (⚠️ Important! Backup this!)
```

## 🔑 Key Information

- **Age Public Key**: `age1hx85ryylzc7vdckfg452phfm4z4c57y69hthvpz2v0ydc3030qcqrxfftu`
- **Age Private Key Location**: `/home/rea/.config/sops/age/keys.txt`

> ⚠️ **Important Reminder**: Always securely backup the age private key file. Without it, you cannot decrypt any secrets!

## 🛠️ Password Modification Methods

### Method 1: Using sops editor (Recommended)

```bash
cd /home/rea/nix-config
EDITOR=nvim sops secrets/secrets.yaml
```

**Steps**:
1. File will automatically decrypt and open in editor
2. Directly modify password values
3. Save and exit editor (use `:wq` in nvim)
4. sops will automatically re-encrypt the file

### Method 2: Command line approach

```bash
cd /home/rea/nix-config

# 1. Decrypt to temporary file
sops -d secrets/secrets.yaml > secrets/secrets_temp.yaml

# 2. Edit temporary file
nvim secrets/secrets_temp.yaml

# 3. Re-encrypt
cp secrets/secrets_temp.yaml secrets/secrets.yaml
sops -e -i secrets/secrets.yaml

# 4. Clean up temporary file
rm secrets/secrets_temp.yaml
```

## 🔄 Applying Password Changes

Regardless of which method you use to modify passwords, you need to execute the following steps:

### 1. Rebuild system
```bash
cd /home/rea/nix-config
sudo nixos-rebuild switch --flake '.#nixos'
```

### 2. Restart password setup service (if needed)
```bash
sudo systemctl restart postgresql-setup-passwords
```

### 3. Commit changes to Git
```bash
git add secrets/secrets.yaml
git commit -m "Update PostgreSQL passwords"
```

## 🧪 Verify Password Update

### Check if secrets are correctly deployed
```bash
sudo ls -la /run/secrets/
sudo systemctl status postgresql-setup-passwords
```

### Test database connection
```bash
# Get current password (for testing only)
REA_PASSWORD=$(sudo cat /run/secrets/rea-password)

# Test connection
PGPASSWORD="$REA_PASSWORD" psql -h localhost -U rea -d postgres -c "SELECT current_user;"
```

## 📋 Currently Configured Secrets

- `postgres-password`: postgres user password
- `rea-password`: rea user password

## 🆕 Adding New Secret

### 1. Edit secrets file
```bash
EDITOR=nvim sops secrets/secrets.yaml
```

Add new password entry:
```yaml
postgres-password: existing-password
rea-password: existing-password
new-service-password: your-new-password-here
```

### 2. Update configuration.nix
Add new configuration in `sops.secrets` section:

```nix
sops.secrets = {
  postgres-password = {
    owner = "postgres";
    group = "postgres";
    mode = "0400";
  };
  rea-password = {
    owner = "postgres";
    group = "postgres";
    mode = "0400";
  };
  new-service-password = {
    owner = "your-service-user";
    group = "your-service-group";
    mode = "0400";
  };
};
```

### 3. Rebuild system
```bash
sudo nixos-rebuild switch --flake '.#nixos'
```

## 🔍 Common Commands

### View encrypted secrets (read-only)
```bash
sops -d secrets/secrets.yaml
```

### View decrypted secrets file locations
```bash
sudo ls -la /run/secrets/
```

### Check service status
```bash
sudo systemctl status postgresql-setup-passwords
sudo systemctl status postgresql
```

### Regenerate age key (Dangerous operation!)
```bash
# ⚠️ This will make all existing secrets undecryptable!
age-keygen -o /home/rea/.config/sops/age/keys.txt

# Get new public key
age-keygen -y /home/rea/.config/sops/age/keys.txt

# Need to update .sops.yaml and re-encrypt all secrets
```

## 🚨 Troubleshooting

### Issue 1: "no matching creation rules found"
**Solution**: Check if `.sops.yaml` file configuration is correct

### Issue 2: Database connection fails after password update
**Solution**: 
```bash
sudo systemctl restart postgresql-setup-passwords
sudo systemctl status postgresql-setup-passwords
```

### Issue 3: "path does not exist" error
**Solution**: Make sure secrets file is added to git
```bash
git add secrets/secrets.yaml
```

### Issue 4: Lost age private key
**Result**: Unrecoverable! This is why backup is important.

## 📚 Reference Resources

- [sops-nix Official Documentation](https://github.com/Mic92/sops-nix)
- [Age Encryption Tool](https://github.com/FiloSottile/age)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)

---
**Last Updated**: September 1, 2025  
**Maintainer**: rea  
**System**: NixOS with sops-nix
