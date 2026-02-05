# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./sunshine.nix
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

  boot.loader.timeout = 5;

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
    "clearcpuid=rdrand"  # Disable RDRAND to avoid broken RDSEED32 issue on AMD CPUs
    "random.trust_cpu=0"  # Don't trust CPU random number generator
  ];
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
  boot.extraModulePackages = [ config.hardware.nvidia.package ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.blacklistedKernelModules = ["nouveau"];

  # Load Bluetooth ISO module for advanced audio profiles
  boot.kernelModules = ["bluetooth_iso"];

  # UVC webcam quirks for UGREEN Camera 2K (0c45:636f)
  # Fix slow initialization by skipping unsupported UVC control queries
  boot.extraModprobeConfig = ''
    # Quirks flags:
    # 0x80  = UVC_QUIRK_NO_RESET_RESUME - Skip bandwidth checks
    # 0x100 = UVC_QUIRK_IGNORE_SELECTOR_UNIT - Ignore processing units
    options uvcvideo quirks=0x80
  '';

  nix.optimise.automatic = true;

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
      # AMD (RADV is included in Mesa by default)
      mesa

      # NVIDIA
      nvidia-vaapi-driver

      # Vulkan
      vulkan-validation-layers
      vulkan-tools
    ];

    extraPackages32 = with pkgs.pkgsi686Linux; [
      mesa
      nvidia-vaapi-driver
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

    forceFullCompositionPipeline = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
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

  # Enable bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
        KernelExperimental = true;  # Enable ISO Socket for BAP support
      };
    };
  };

  # Xbox controller support
  hardware.xpadneo.enable = true;  # Bluetooth Xbox controller driver
  hardware.xone.enable = true;  # Xbox One wireless adapter support

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
        qt6Packages.fcitx5-configtool
        fcitx5-mozc
        fcitx5-gtk
        fcitx5-nord
        fcitx5-rime
      ];
    };
  };

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      
      settings = {
        General = {
          DisplayStopTime = 300; # 5 minutes
        };
      };
    };
    
    autoLogin = {
      enable = true;
      user = "rea";
    };
  };
  
  services.desktopManager.plasma6.enable = true;

  # KDE Plasma font configuration - use Maple Mono NF CN for full Nerd Font icon support
  environment.etc."xdg/kdeglobals".text = lib.generators.toINI {} {
    General = {
      font = "Maple Mono NF CN,11,-1,5,50,0,0,0,0,0";  # General UI font with Nerd Font support
      fixed = "Maple Mono NF CN,10,-1,5,50,0,0,0,0,0";  # Fixed-width font (terminal, code)
      menuFont = "Maple Mono NF CN,11,-1,5,50,0,0,0,0,0";  # Menu font
      smallestReadableFont = "Maple Mono NF CN,9,-1,5,50,0,0,0,0,0";  # Smallest readable font
      toolBarFont = "Maple Mono NF CN,10,-1,5,50,0,0,0,0,0";  # Toolbar font
    };
    WM = {
      activeFont = "Maple Mono NF CN,11,-1,5,75,0,0,0,0,0";  # Window title font (bold)
    };
  };

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
      "kvm"
      "adbusers"
      "docker"
      "libvirtd"
      "input"
      "video"
      "render"
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
    ];
    fontconfig = {
      defaultFonts = {
        sansSerif = [ "Maple Mono NF CN" "Noto Sans CJK SC" ];
        serif = [ "Noto Serif CJK SC" ];
        monospace = [ "Maple Mono NF CN" "JetBrains Mono" ];
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
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
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
    nixfmt
    openssl
    sops
    age
    inetutils
    dnsutils
    hardinfo2
    wayland-utils
    wl-clipboard
    xclip
    xorg.xhost

    # Docker tools
    docker-compose
    docker-buildx

    # GPU info
    # nvtopPackages.full  # temporarily disabled due to broken CUDA dependency
    nvidia-system-monitor-qt
    mesa-demos
    vulkan-tools
    glmark2

    # Performance testing
    mangohud
    gamemode

    # Libraries for Electron apps
    stdenv.cc.cc.lib
    libgcc
    glibc
  ];

  # Sunshine game streaming - configured via sunshine.nix module
  services.sunshineStreaming = {
    enable = true;
    hostName = "nixos";
    user = "rea";
    autoStart = true;
    cudaSupport = true;
    openFirewall = true;
  };

  environment.variables = {
    EDITOR = "nvim";
    "__GL_SHADER_DISK_CACHE" = "1";
    "__GL_THREADED_OPTIMIZATION" = "1";
    LD_LIBRARY_PATH = "${pkgs.gcc.cc.lib}/lib:$LD_LIBRARY_PATH";
    # KDE Plasma compositor optimization for NVIDIA
    # https://bugs.kde.org/show_bug.cgi?id=495073
    KWIN_COMPOSE = "O2";
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };
  programs.virt-manager.enable = true;

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      dns = [
        "1.1.1.1"
        "8.8.8.8"
      ];
      log-driver = "journald";
      registry-mirrors = [ "https://mirror.gcr.io" ];
      storage-driver = "overlay2";
    };
    rootless = {
      enable = false;
      setSocketVariable = true;
    };
  };

  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    stdenv.cc.libc
    zlib
    openssl
    openssl_3  # Add OpenSSL 3.x for newer binaries
    libgcc
    glibc
    gcc.cc.lib
    xorg.libX11
    xorg.libXext
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    libGL
    freetype
    fontconfig
    dbus
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    gdk-pixbuf
    gtk3
    pango
    freerdp
  ];

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraPackages = with pkgs; [
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      source-han-sans
      source-han-serif
      wqy_zenhei
    ];
  };
  programs.gamemode.enable = true;

  programs.kdeconnect.enable = true;

  # AppImage support
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

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

  # https://github.com/NixOS/nixpkgs/issues/462935
  # nixos/orca: Screen reader on by default on non-GNOME desktops, cannot be disabled
  systemd.user.services.orca.wantedBy = lib.mkForce [ ];

  # XDG Desktop Portal configuration for GTK apps in KDE
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
    ];
    config.common.default = "*";
  };

  programs.dconf.enable = true;

  services.redis.servers.my-redis = {
    enable = true;
    port = 6379;
    bind = "0.0.0.0";
    # For example, to set a password:
    # passwordFile = "/path/to/your/redis_password_file";
  };

  # ToDesk remote desktop support
  systemd.tmpfiles.rules = [
    "d /var/lib/todesk 0755 root root -"
    "d /var/log/todesk 0755 root root -"
    "d /opt/todesk 0755 root root -"
  ];

  systemd.services.todeskd = {
    description = "ToDesk Remote Desktop Service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.todesk}/bin/todesk service";
      Restart = "on-failure";
      RestartSec = 10;
      
      # Security settings
      PrivateTmp = false;
      
      # Network access
      PrivateNetwork = false;
    };
  };

  networking.firewall = {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
      {
        from = 8000;
        to = 9000;
      }
    ];
    allowedTCPPorts = [
      3000
      3389
      5000
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
  system.stateVersion = "25.11";

}
