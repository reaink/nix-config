# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # sops secrets configuration
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/rea/.config/sops/age/keys.txt";

    secrets = {
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
    };
  };

  # Bootloader.
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 5;

    extraEntries = {
      "windows.conf" = ''
        title Windows 11
        efi /EFI/Microsoft/Boot/bootmgfw.efi
      '';
    };
  };
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
  ];
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
  boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

  nix.settings.auto-optimise-store = true;

  nixpkgs.config.allowUnfree = true;

  # Graphics configuration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      # NVIDIA
      nvidia-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl

      # Vulkan
      vulkan-validation-layers
      vulkan-tools

      # AMD
      amdvlk
    ];

    extraPackages32 = with pkgs.pkgsi686Linux; [
      nvidia-vaapi-driver
      amdvlk
    ];
  };

  # Nvidia Driver
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;

    powerManagement = {
      enable = true;
      finegrained = false;
    };

    package = config.boot.kernelPackages.nvidiaPackages.latest;
    # PRIME
    prime = {
      sync.enable = true;

      offload.enable = false;

      nvidiaBusId = "PCI:1:0:0";
      amdgpuBusId = "PCI:13:0:0";
    };
  };

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    deviceSection = ''
      Option "PrimaryGPU" "yes"
    '';
  };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-configtool
        fcitx5-mozc
        fcitx5-gtk
        fcitx5-nord
        fcitx5-rime
      ];
    };
  };

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  programs.bash.enable = true;
  programs.zsh.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.rea = {
    isNormalUser = true;
    description = "Rea";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      kdePackages.kate
    ];
    shell = pkgs.zsh;
  };

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    packages = with pkgs; [
      hack-font
      inter
      jetbrains-mono
      source-code-pro
      dejavu_fonts
      liberation_ttf
      monaspace
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      sarasa-gothic
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      nerd-fonts.caskaydia-mono
    ];
    fontconfig = {
      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        monospace = [
          "Noto Sans Mono CJK SC"
          "Sarasa Mono SC"
          "DejaVu Sans Mono"
        ];
        sansSerif = [
          "Noto Sans CJK SC"
          "Source Han Sans SC"
          "DejaVu Sans"
        ];
        serif = [
          "Noto Serif CJK SC"
          "Source Han Serif SC"
          "DejaVu Serif"
        ];
      };
    };
  };

  # Install firefox.
  programs.firefox.enable = true;

  # enable flakes and nix command
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.substituters = [
    "https://mirror.nju.edu.cn/nix-channels/store"
    "https://nix-community.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    efibootmgr
    ntfs3g
    git
    neovim
    wget
    nixfmt-rfc-style
    openssl
    sops
    age

    # CUDA
    cudatoolkit

    # GPU info
    nvtopPackages.full
    nvidia-system-monitor-qt
    glxinfo
    vulkan-tools
    glmark2

    # Performance testing
    mangohud
    gamemode
  ];

  environment.variables = {
    EDITOR = "nvim";
    "__GL_SHADER_DISK_CACHE" = "1";
    "__GL_THREADED_OPTIMIZATION" = "1";
  };

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    stdenv.cc.libc
    zlib
    openssl
    libgcc
    glibc
  ];

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gamemode.enable = true;

  programs.kdeconnect.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  services.openssh.enable = true;

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    package = pkgs.postgresql_16;
    authentication = pkgs.lib.mkOverride 10 ''
      local   postgres    postgres             peer
      local   all         rea                  scram-sha-256
      host    all         all     127.0.0.1/32 scram-sha-256
      host    all         all     ::1/128      scram-sha-256
    '';

    ensureDatabases = [
      "postgres"
      "rea"
    ];
    ensureUsers = [
      {
        name = "rea";
        ensureDBOwnership = true;
      }
    ];

  };

  systemd.services.postgresql-setup-passwords = {
    description = "Setup PostgreSQL user passwords";
    wantedBy = [ "multi-user.target" ];
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      Group = "postgres";
      RemainAfterExit = true;

      ExecStart = pkgs.writeShellScript "setup-postgres-passwords" ''
        set -euo pipefail

        # Wait for PostgreSQL to start
        ${pkgs.postgresql}/bin/pg_isready -q

        # Read passwords from sops secrets files
        POSTGRES_PASS=$(cat ${config.sops.secrets.postgres-password.path})
        REA_PASS=$(cat ${config.sops.secrets.rea-password.path})

        ${pkgs.postgresql}/bin/psql -c "ALTER USER postgres PASSWORD '$POSTGRES_PASS';" 2>/dev/null || true
        ${pkgs.postgresql}/bin/psql -c "ALTER USER rea PASSWORD '$REA_PASS';" 2>/dev/null || true
        ${pkgs.postgresql}/bin/psql -c "ALTER USER rea CREATEDB;" 2>/dev/null || true

        echo "PostgreSQL passwords setup completed"
      '';
    };
  };

  services.redis.servers.my-redis = {
    enable = true;
    port = 6379;
    bind = "0.0.0.0";
    # For example, to set a password:
    # passwordFile = "/path/to/your/redis_password_file";
  };

  networking.firewall = {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
