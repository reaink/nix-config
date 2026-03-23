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
    defaultSopsFile = ../../secrets/secrets.yaml;
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
    "mem_sleep_default=deep"
    "clearcpuid=rdrand" # Disable RDRAND to avoid broken RDSEED32 issue on AMD CPUs
    "random.trust_cpu=0" # Don't trust CPU random number generator
    # Prevent NVMe from entering deep power states during suspend.
    # Without this, the NVMe stalls on resume I/O which blocks journald,
    # triggering its watchdog, crashing it, and corrupting the journal —
    # which in turn disrupts the logind DRM device re-grant to KWin.
    "nvme_core.default_ps_max_latency_us=0"

    # Fix blank screen after S3 resume: disable scatter-gather display on AMD GPU.
    # amdgpu's SG display path fails to reinitialize after deep sleep on some hardware.
    "amdgpu.sg_display=0"
  ];
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
  boot.extraModulePackages = [ config.hardware.nvidia.package ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.blacklistedKernelModules = [ "nouveau" ];

  # Load Bluetooth ISO module for advanced audio profiles
  boot.kernelModules = [ "bluetooth_iso" ];

  # UVC webcam quirks for UGREEN Camera 2K (0c45:636f)
  # Fix slow initialization by skipping unsupported UVC control queries
  boot.extraModprobeConfig = ''
    # Quirks flags:
    # 0x80  = UVC_QUIRK_NO_RESET_RESUME - Skip bandwidth checks
    # 0x100 = UVC_QUIRK_IGNORE_SELECTOR_UNIT - Ignore processing units
    options uvcvideo quirks=0x80
  '';

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

    # forceFullCompositionPipeline is X11-only workaround for tearing,
    # on Wayland it only adds compositor latency - keep it off
    forceFullCompositionPipeline = false;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
    # PRIME sync mode: NVIDIA is primary GPU, handles all rendering.
    # AMD GPU outputs frames to the display (internal panel or connected monitors).
    prime = {
      sync.enable = true;

      offload = {
        enable = false;
        enableOffloadCmd = false;
      };

      nvidiaBusId = "PCI:1:0:0";
      amdgpuBusId = "PCI:13:0:0";
    };
  };

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    # PRIME sync mode: NVIDIA is primary, NixOS configures NVIDIA display device automatically
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
        KernelExperimental = true; # Enable ISO Socket for BAP support
      };
    };
  };

  # Xbox controller support
  hardware.xpadneo.enable = true; # Bluetooth Xbox controller driver
  hardware.xone.enable = true; # Xbox One wireless adapter support

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        qt6Packages.fcitx5-configtool
        fcitx5-mozc
        fcitx5-gtk
        libsForQt5.fcitx5-qt
        qt6Packages.fcitx5-qt
        fcitx5-nord
        fcitx5-rime
      ];
    };
  };

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager = {
    plasma-login-manager.enable = true;

    autoLogin = {
      enable = true;
      user = "rea";
    };
  };

  services.desktopManager.plasma6.enable = true;

  # KDE Plasma font configuration - optimized for readability
  environment.etc."xdg/kdeglobals".text = lib.generators.toINI { } {
    General = {
      font = "Noto Sans CJK SC,11,-1,5,50,0,0,0,0,0"; # General UI font - best for Chinese display
      fixed = "Maple Mono NF CN,10,-1,5,50,0,0,0,0,0"; # Fixed-width font (terminal, code)
      menuFont = "Noto Sans CJK SC,11,-1,5,50,0,0,0,0,0"; # Menu font
      smallestReadableFont = "Noto Sans CJK SC,9,-1,5,50,0,0,0,0,0"; # Smallest readable font
      toolBarFont = "Noto Sans CJK SC,10,-1,5,50,0,0,0,0,0"; # Toolbar font
    };
    WM = {
      activeFont = "Noto Sans CJK SC,11,-1,5,75,0,0,0,0,0"; # Window title font (bold)
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
      lxgw-wenkai
    ];
    fontconfig = {
      defaultFonts = {
        sansSerif = [
          "Noto Sans CJK SC"
          "Sarasa Gothic SC"
          "DejaVu Sans"
        ];
        serif = [
          "Noto Serif CJK SC"
          "LXGW WenKai"
        ];
        monospace = [
          "Maple Mono NF CN"
          "Sarasa Mono SC"
          "JetBrains Mono"
        ];
      };
    };
  };

  # Install firefox.
  programs.firefox.enable = true;

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
    xhost

    # Docker tools
    docker-compose
    docker-buildx

    # GPU info
    nvtopPackages.full
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

    # GStreamer plugins required by WebKitGTK and other media consumers
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi
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
    LD_LIBRARY_PATH = "${pkgs.gcc.cc.lib}/lib:$LD_LIBRARY_PATH";
    # Make GStreamer plugins discoverable by WebKitGTK subprocesses (WebKitWebProcess, etc.)
    # NixOS does not set this automatically; without it createAudioSink crashes with SIGABRT.
    GST_PLUGIN_SYSTEM_PATH_1_0 = lib.concatStringsSep ":" (
      map (p: "${p}/lib/gstreamer-1.0") (
        (with pkgs.gst_all_1; [
          gstreamer
          gst-plugins-base
          gst-plugins-good
          gst-plugins-bad
          gst-plugins-ugly
          gst-libav
          gst-vaapi
          # gtk4paintablesink (libgstgtk4.so) required by WebKitGTK 2.50+ for video rendering
          gst-plugins-rs
        ])
        # WebKitGTK 2.50+ prefers pipewiresink; without libgstpipewire.so
        # createAudioSink crashes with SIGABRT even when PulseAudio compat is enabled.
        ++ [ pkgs.pipewire ]
      )
    );
    # Fcitx5 input method environment variables.
    # With waylandFrontend = true, native Wayland apps (GTK4, Qt6) use the
    # text-input-v3 protocol directly — GTK_IM_MODULE / QT_IM_MODULE must NOT
    # be set or fcitx5 will warn and input may break.
    # XMODIFIERS is still required for XWayland apps.
    XMODIFIERS = "@im=fcitx";
    # Force Electron apps (VSCode, etc.) to use native Wayland backend so they
    # use text-input-v3 instead of XIM. Without this, WebView-based panels
    # (e.g. Copilot Chat) run in a separate Chromium process that bypasses XIM
    # entirely, making fcitx5 unreachable inside them.
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  };

  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };

  # NVIDIA GPUs are not supported by Waydroid natively; use swiftshader (software rendering).
  # sys.use_memfd=true is required on Linux 5.18+ (ashmem replaced by memfd).
  # https://wiki.nixos.org/wiki/Waydroid#GPU_Adjustments
  #
  # waydroid builds waydroid_base.prop from waydroid.prop (vendor image) at each startup.
  # The cfg [properties] section is the designed override mechanism — set values there.
  # waydroid.prop is also patched directly so the values survive base.prop regeneration.
  systemd.services.waydroid-container.preStart = lib.mkAfter ''
    cfg=/var/lib/waydroid/waydroid.cfg
    if [ -f "$cfg" ]; then
      ${pkgs.python3}/bin/python3 - "$cfg" <<'EOF'
    import configparser, sys
    cfg = configparser.ConfigParser()
    cfg.read(sys.argv[1])
    if "properties" not in cfg:
        cfg["properties"] = {}
    cfg["properties"]["ro.hardware.gralloc"] = "default"
    cfg["properties"]["ro.hardware.egl"] = "swiftshader"
    cfg["properties"]["sys.use_memfd"] = "true"
    cfg["properties"].pop("gralloc.gbm.device", None)
    # Spoof Pixel 5 (redfin) identity to pass emulator detection.
    # ref: https://wiki.archlinux.org/title/Waydroid#Application_need_unroot_device
    fp = "google/redfin/redfin:11/RQ3A.211001.001/eng.electr.20230318.111310:user/release-keys"
    cfg["properties"]["ro.product.brand"] = "google"
    cfg["properties"]["ro.product.manufacturer"] = "Google"
    cfg["properties"]["ro.product.name"] = "redfin"
    cfg["properties"]["ro.product.device"] = "redfin"
    cfg["properties"]["ro.product.model"] = "Pixel 5"
    cfg["properties"]["ro.system.build.product"] = "redfin"
    cfg["properties"]["ro.system.build.flavor"] = "redfin-user"
    cfg["properties"]["ro.build.fingerprint"] = fp
    cfg["properties"]["ro.system.build.description"] = "redfin-user 11 RQ3A.211001.001 eng.electr.20230318.111310 release-keys"
    cfg["properties"]["ro.bootimage.build.fingerprint"] = fp
    cfg["properties"]["ro.build.display.id"] = fp
    cfg["properties"]["ro.build.tags"] = "release-keys"
    cfg["properties"]["ro.build.description"] = "redfin-user 11 RQ3A.211001.001 eng.electr.20230318.111310 release-keys"
    cfg["properties"]["ro.vendor.build.fingerprint"] = fp
    cfg["properties"]["ro.vendor.build.id"] = "RQ3A.211001.001"
    cfg["properties"]["ro.vendor.build.tags"] = "release-keys"
    cfg["properties"]["ro.vendor.build.type"] = "user"
    cfg["properties"]["ro.odm.build.tags"] = "release-keys"
    with open(sys.argv[1], "w") as f:
        cfg.write(f)
    EOF
    fi

    for prop in /var/lib/waydroid/waydroid.prop /var/lib/waydroid/waydroid_base.prop; do
      if [ -f "$prop" ]; then
        ${pkgs.gnused}/bin/sed -i \
          -e '/^ro\.hardware\.egl=/d' \
          -e '/^ro\.hardware\.gralloc=/d' \
          -e '/^gralloc\.gbm\.device=/d' \
          -e '/^sys\.use_memfd=/d' \
          "$prop"
        printf 'ro.hardware.gralloc=default\nro.hardware.egl=swiftshader\nsys.use_memfd=true\n' >> "$prop"
      fi
    done
  '';

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };
  programs.virt-manager.enable = true;

  # Fix: libvirt upstream bug — virt-secret-init-encryption.service hardcodes
  # /usr/bin/sh which does not exist on NixOS.
  # systemd drop-in must emit "ExecStart=" (empty) first to clear the original
  # value before setting the replacement; passing a list achieves exactly that.
  systemd.services.virt-secret-init-encryption = {
    serviceConfig.ExecStart = [
      "" # clear the upstream ExecStart=/usr/bin/sh ... line
      (pkgs.writeShellScript "virt-secret-init-encryption" ''
        umask 0077
        dd if=/dev/random status=none bs=32 count=1 \
          | ${pkgs.systemd}/bin/systemd-creds encrypt \
              --name=secrets-encryption-key \
              - /var/lib/libvirt/secrets/secrets-encryption-key
      '')
    ];
  };

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
    openssl_3 # Add OpenSSL 3.x for newer binaries
    libgcc
    glibc
    gcc.cc.lib
    libx11
    libxext
    libxi
    libxrandr
    libxrender
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
      wineWow64Packages.full
    ];
  };
  programs.gamemode.enable = true;

  programs.kdeconnect.enable = true;

  services.hardware.openrgb.enable = true;

  # AppImage support
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  services.flatpak.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  services.openssh.enable = true;

  # Prevent journal from growing unbounded and causing NVMe I/O stalls during suspend.
  services.journald.extraConfig = ''
    SystemMaxUse=512M
    SystemKeepFree=256M
  '';

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

  # Fix: KWin loses DRM master permission after suspend/resume on NVIDIA PRIME offload.
  #
  # Root cause: post-resume.service has `After=sleep.target`, but sleep.target is
  # already active when suspend begins, so logind triggers post-resume immediately
  # upon wakeup — before nvidia-resume.service finishes restoring GPU state and before
  # logind re-grants DRM master to the user session. KWin then gets Permission denied
  # on all DRM/modeset calls, leaving the screen black or at minimum brightness.
  #
  # Fix (system level): ensure post-resume.service waits for nvidia-resume.service.
  systemd.services.post-resume = {
    after = lib.mkAfter [ "nvidia-resume.service" ];
    requires = lib.mkAfter [ "nvidia-resume.service" ];
  };

  # Lock the screen BEFORE entering sleep, so kscreenlocker_greet is already
  # running when the system resumes. This avoids the race condition where
  # lockOnResume=true tries to start a new greeter before KWin has DRM master,
  # which causes an error dialog instead of a lock screen.
  systemd.services.kscreenlocker-pre-sleep = {
    description = "Lock all sessions before sleep";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/loginctl lock-sessions";
    };
  };

  # Fix (system level, post-resume): after nvidia-resume and post-resume complete,
  # tell KWin to re-query DRM outputs and resume compositing.
  #
  # The previous approach used a user-level service with wantedBy=suspend.target,
  # but that service actually starts BEFORE suspend, and the `sleep 2` finishes
  # before the system even goes to sleep — leaving zero post-resume delay.
  # Running as a system service After=post-resume.service guarantees execution
  # strictly after GPU state is restored and logind has re-granted DRM master.
  systemd.services.kwin-resume-fix = {
    description = "Restore KWin display state after suspend/resume";
    after = [ "post-resume.service" ];
    wantedBy = [ "post-resume.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "rea";
      # Small delay to let logind finish re-granting DRM master to the session.
      ExecStart = pkgs.writeShellScript "kwin-resume-fix" ''
        sleep 3
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
        export DBUS_SESSION_BUS_ADDRESS
        ${pkgs.dbus}/bin/dbus-send \
          --session \
          --dest=org.kde.KWin \
          --print-reply \
          /KWin \
          org.kde.KWin.reconfigure 2>/dev/null || true
        ${pkgs.dbus}/bin/dbus-send \
          --session \
          --dest=org.kde.KWin \
          --print-reply \
          /Compositor \
          org.kde.kwin.Compositing.resume 2>/dev/null || true
      '';
    };
  };

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
