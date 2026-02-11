{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    # Shared modules
    ../../modules/nix-settings.nix
    # SOPS secrets management
    inputs.sops-nix.darwinModules.sops
  ];

  # Set hostname
  networking.hostName = "mac";

  # sops secrets configuration
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/Users/rea/.config/sops/age/keys.txt";

    secrets = {
      postgres-password = {
        owner = "rea";
        mode = "0400";
      };
      rea-password = {
        owner = "rea";
        mode = "0400";
      };
    };
  };

  # Basic system packages for macOS
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    nixfmt
    postgresql_16
    sops
    age
  ];

  # Define user
  users.users.rea = {
    name = "rea";
    home = "/Users/rea";
  };

  # Primary user for system-wide activation (required by nix-darwin migration)
  system.primaryUser = "rea";

  # Enable alternative shell support
  programs.zsh.enable = true;

  # PostgreSQL service configuration
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;

    # Enable TCP/IP connections
    enableTCPIP = true;

    # Initialize with UTF8 encoding
    initdbArgs = [
      "--encoding=UTF8"
      "--locale=C"
    ];

    # PostgreSQL settings
    settings = {
      listen_addresses = lib.mkForce "127.0.0.1";
      port = 5432;
      max_connections = 100;
      shared_buffers = "128MB";
    };
  };

  # Setup PostgreSQL passwords and authentication using launchd
  launchd.daemons.postgresql-setup = {
    script = ''
            set -euo pipefail
            
            # Wait for PostgreSQL to be ready (max 30 seconds)
            RETRIES=15
            until ${pkgs.postgresql_16}/bin/pg_isready -h 127.0.0.1 -p 5432 2>/dev/null || [ $RETRIES -eq 0 ]; do
              echo "Waiting for PostgreSQL to start... ($RETRIES attempts left)"
              sleep 2
              RETRIES=$((RETRIES - 1))
            done
            
            if [ $RETRIES -eq 0 ]; then
              echo "PostgreSQL did not start in time"
              exit 1
            fi
            
            # Read passwords from sops secrets
            POSTGRES_PASS=$(cat ${config.sops.secrets.postgres-password.path})
            REA_PASS=$(cat ${config.sops.secrets.rea-password.path})
            
            # Get PostgreSQL data directory
            PG_DATA_DIR=$(${pkgs.postgresql_16}/bin/psql -h 127.0.0.1 -p 5432 postgres -t -c "SHOW data_directory;" 2>/dev/null | xargs || echo "")
            
            if [ -z "$PG_DATA_DIR" ]; then
              echo "Could not determine PostgreSQL data directory"
              exit 1
            fi
            
            echo "PostgreSQL data directory: $PG_DATA_DIR"
            
            # Configure pg_hba.conf for authentication (matching Linux config)
            cat > "$PG_DATA_DIR/pg_hba.conf" <<'EOF'
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             rea                                     scram-sha-256
      host    all             all             127.0.0.1/32            scram-sha-256
      host    all             all             ::1/128                 scram-sha-256
      EOF
            
            # Reload PostgreSQL configuration to apply pg_hba.conf changes
            ${pkgs.postgresql_16}/bin/pg_ctl -D "$PG_DATA_DIR" reload 2>/dev/null || true
            
            # Wait a moment for reload
            sleep 1
            
            # Create user if not exists
            ${pkgs.postgresql_16}/bin/psql -h 127.0.0.1 -p 5432 postgres -tc "SELECT 1 FROM pg_user WHERE usename = 'rea'" | grep -q 1 || \
              ${pkgs.postgresql_16}/bin/psql -h 127.0.0.1 -p 5432 postgres -c "CREATE USER rea WITH CREATEDB;" 2>/dev/null || true
            
            # Set password and grant privileges
            ${pkgs.postgresql_16}/bin/psql -h 127.0.0.1 -p 5432 postgres -c "ALTER USER rea PASSWORD '$REA_PASS';" 2>/dev/null || true
            ${pkgs.postgresql_16}/bin/psql -h 127.0.0.1 -p 5432 postgres -c "ALTER USER rea CREATEDB;" 2>/dev/null || true
            
            # Create databases if not exist
            ${pkgs.postgresql_16}/bin/psql -h 127.0.0.1 -p 5432 postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'rea'" | grep -q 1 || \
              ${pkgs.postgresql_16}/bin/psql -h 127.0.0.1 -p 5432 postgres -c "CREATE DATABASE rea OWNER rea;" 2>/dev/null || true
            
            echo "PostgreSQL setup completed: user and database created"
            echo "Connection string: postgresql://rea:[password]@localhost:5432/rea"
    '';

    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/tmp/postgresql-setup.log";
      StandardErrorPath = "/tmp/postgresql-setup.error.log";
    };
  };

  # Font configuration (matching Linux setup)
  fonts = {
    packages = with pkgs; [
      hack-font
      inter
      jetbrains-mono
      dejavu_fonts
      liberation_ttf
      monaspace
      maple-mono.truetype
      maple-mono.NF-unhinted
      maple-mono.NF-CN-unhinted
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      nerd-fonts.caskaydia-mono
      sarasa-gothic
      source-code-pro
      source-han-mono
      source-han-sans
      source-han-serif
      wqy_zenhei
      lxgw-wenkai
    ];
  };

  # Set Git commit hash for darwin-version
  system.configurationRevision = null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on
  nixpkgs.hostPlatform = "aarch64-darwin";
}
