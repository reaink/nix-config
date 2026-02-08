{
  config,
  pkgs,
  inputs,
  ...
}:

{
  home.username = "rea";
  home.homeDirectory = "/home/rea";

  home.packages =
    (with pkgs; [
      neofetch

      zip
      xz
      unzip
      p7zip

      ripgrep
      jq
      eza
      bat
      bottom
      zoxide

      rustup
      protobuf
      clang
      libclang.lib
      lld
      gnumake
      pkg-config
      glib
      glib.dev
      gtk3
      gtk3.dev
      webkitgtk_4_1
      webkitgtk_4_1.dev
      pango
      pango.dev
      cairo
      cairo.dev
      atk
      atk.dev
      libsoup_3
      libsoup_3.dev
      openssl
      openssl.dev
      dbus
      dbus.dev
      gdk-pixbuf

      uv
      fnm
      pnpm
      lazygit
      lazydocker
      google-cloud-sdk
      gparted
      appimage-run
      gearlever
      android-tools
      imagemagick

      # Database for Akonadi
      mariadb

      # kdePackages
      kdePackages.breeze
      kdePackages.breeze-gtk
      kdePackages.breeze-icons
      kdePackages.akonadi
      kdePackages.akonadi-import-wizard
      kdePackages.akonadi-calendar
      kdePackages.akonadi-contacts
      kdePackages.akonadi-mime
      kdePackages.akonadi-search
      kdePackages.kdepim-runtime
      kdePackages.dragon
      kdePackages.kcalc
      kdePackages.kamoso
      kdePackages.kdepim-addons
      # kdePackages.kdenlive # video editor, ffmpeg-full shaderc dependency issues
      kdePackages.sddm-kcm
      kdePackages.ksystemlog
      kdePackages.kontact
      kdePackages.kmail
      kdePackages.kmail-account-wizard
      kdePackages.libkdepim
      kdePackages.pimcommon
      kdePackages.pim-data-exporter
      kdePackages.korganizer
      kdePackages.kaccounts-integration
      kdePackages.kaccounts-providers
      kdePackages.kio-gdrive
      kdePackages.yakuake
      kdePackages.filelight
      kdePackages.partitionmanager
      kdePackages.kio-admin
      kdePackages.kio-extras
      kdePackages.kio-fuse
      kdePackages.plasma-workspace  # calendar plugins support
      kdePackages.kweather  # weather widget

      google-chrome
      (import ./vscode-insiders.nix { inherit pkgs lib; })
      wechat-uos
      qq
      cherry-studio
      telegram-desktop
      steam
      (lutris.override {
        extraPkgs = pkgs: [
          pkgs.wineWowPackages.stable
        ];
      })
      postman
      dbeaver-bin
      splayer
      spotify
      discord
      libreoffice-fresh
      shotcut
      android-studio
      prismlauncher
      vlc
      mpv
      obsidian
      # OBS Studio with NVIDIA support and plugins
      (wrapOBS {
        plugins = with obs-studio-plugins; [
          obs-vaapi  # VAAPI support (works via nvidia-vaapi-driver)
          obs-vkcapture  # Vulkan/OpenGL capture
          obs-pipewire-audio-capture  # PipeWire audio capture
        ];
      })
      gdu
      ngrok
      winboat
      todesk  # Keep original for service
      
      # Xbox controller tools
      antimicrox  # Gamepad to keyboard/mouse mapping tool
      jstest-gtk  # Gamepad testing utility
      linuxConsoleTools  # Input device testing (jstest, jscal)
      
      # GUI wrapper with DISPLAY fix
      (pkgs.writeShellScriptBin "todesk-gui" ''
        # Add X11 authorization
        ${pkgs.xorg.xhost}/bin/xhost +local: >/dev/null 2>&1 || true
        
        # Force correct environment
        export DISPLAY=:0
        export QT_QPA_PLATFORM=xcb
        export GDK_BACKEND=x11
        export XAUTHORITY="$HOME/.Xauthority"
        
        # Kill existing GUI instances
        ${pkgs.procps}/bin/pkill -f "ToDesk desktop" 2>/dev/null || true
        sleep 1
        
        # Launch with error filtering
        exec ${pkgs.todesk}/bin/todesk desktop 2>&1 | grep -v "iCCP\|libpng warning" || true
      '')
      prisma-engines_7
      wpsoffice-cn
    ])
    ++ [
    ];

  programs.rime-keytao.enable = true;

  home.sessionVariables = {
    LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
    BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.clang}/lib/clang/${pkgs.lib.getVersion pkgs.clang}/include";

    OPENSSL_DIR = "${pkgs.openssl.dev}";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
    OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
    
    # Fix dynamic linking for Rust binaries
    LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [
      pkgs.openssl
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
    ]}:$LD_LIBRARY_PATH";
    PKG_CONFIG_PATH = "${pkgs.lib.makeSearchPath "lib/pkgconfig" [
      pkgs.glib.dev
      pkgs.gtk3.dev
      pkgs.webkitgtk_4_1.dev
      pkgs.pango.dev
      pkgs.cairo.dev
      pkgs.atk.dev
      pkgs.libsoup_3.dev
      pkgs.openssl.dev
      pkgs.dbus.dev
    ]}";
    PKG_CONFIG_ALLOW_SYSTEM_CFLAGS = "1";
    PKG_CONFIG_ALLOW_SYSTEM_LIBS = "1";
    PNPM_HOME = "$HOME/.local/share/pnpm";
    
    # Chromium hardware acceleration with NVIDIA
    # Note: Removed LIBVA_DRIVER_NAME to allow Sunshine to use NVENC properly
    MOZ_DISABLE_RDD_SANDBOX = "1";
    NVD_BACKEND = "direct";
    
    GDK_BACKEND = "wayland,x11";
    # Force GTK4 to use NGL renderer instead of Vulkan (fixes icon hover issues)
    GSK_RENDERER = "ngl";
    # Disable GTK3 overlay scrollbars which can cause rendering glitches
    GTK_OVERLAY_SCROLLING = "0";
    # Fix hardware cursor issues on NVIDIA Wayland
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  home.sessionPath = [
    "$HOME/.local/share/pnpm"
    "$HOME/.cargo/bin"
  ];

  # Keep rustup directories from being affected by nix gc
  home.file.".cargo/.keep".text = "";
  home.file.".rustup/.keep".text = "";

  programs.zsh.initContent = ''
    eval "$(fnm env --use-on-cd --shell zsh)"
    eval "$(zoxide init zsh)"
  '';

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Rea";
        email = "hi@rea.ink";
      };
    };
  };

  programs.fzf.enable = true;

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # GTK theme configuration for KDE integration
  gtk = {
    enable = true;
    
    # Arc theme: Modern flat design that auto-follows dark mode
    # Arc-Dark will be used when dark mode is enabled
    theme = {
      name = "Arc-Dark";
      package = pkgs.arc-theme;
    };
    
    # Papirus-Dark: Modern, complete icon set with excellent GTK compatibility
    # Alternative options:
    # - Adwaita (minimalist): name="Adwaita", package=pkgs.adwaita-icon-theme
    # - Tela-dark (colorful): name="Tela-dark", package=pkgs.tela-icon-theme
    # - Numix-Circle (rounded): name="Numix-Circle", package=pkgs.numix-icon-theme-circle
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    
    cursorTheme = {
      name = "breeze_cursors";
      package = pkgs.kdePackages.breeze;
      size = 24;
    };

    gtk3.extraConfig = {
      # Auto-follow system dark mode (managed by KDE)
      gtk-application-prefer-dark-theme = true;
      gtk-icon-theme-name = "Papirus-Dark";
      gtk-button-images = true;
      gtk-menu-images = true;
      # Disable animations that may cause rendering issues
      gtk-enable-animations = false;
    };

    gtk4.extraConfig = {
      # Auto-follow system dark mode (managed by KDE)
      gtk-application-prefer-dark-theme = true;
      gtk-icon-theme-name = "Papirus-Dark";
      gtk-enable-animations = false;
    };

    gtk2 = {
      configLocation = "${config.xdg.stateHome}/gtk-2.0/gtkrc";
      force = true;
      extraConfig = ''
        # Force GTK2 theme
      '';
    };
  };

  # Qt/KDE configuration
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
  };

  # GTK settings.ini to fix icon rendering issues
  xdg.configFile."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Arc-Dark
    gtk-icon-theme-name=Papirus-Dark
    gtk-font-name=Noto Sans 10
    gtk-cursor-theme-name=breeze_cursors
    gtk-cursor-theme-size=24
    gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
    gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
    gtk-button-images=1
    gtk-menu-images=1
    gtk-enable-event-sounds=0
    gtk-enable-input-feedback-sounds=0
    gtk-xft-antialias=1
    gtk-xft-hinting=1
    gtk-xft-hintstyle=hintslight
    gtk-xft-rgba=rgb
    gtk-application-prefer-dark-theme=1
    # Disable animations to fix rendering glitches
    gtk-enable-animations=0
    # Force proper icon loading
    gtk-icon-sizes=panel-menu=24,24:panel=24,24:gtk-button=16,16:gtk-large-toolbar=24,24
  '';

  xdg.configFile."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Arc-Dark
    gtk-icon-theme-name=Papirus-Dark
    gtk-font-name=Noto Sans 10
    gtk-cursor-theme-name=breeze_cursors
    gtk-cursor-theme-size=24
    gtk-application-prefer-dark-theme=1
    gtk-enable-animations=0
  '';

  # ToDesk desktop launcher with wrapper script
  xdg.dataFile."applications/todesk.desktop".text = ''
    [Desktop Entry]
    Name=ToDesk
    Exec=todesk-gui
    Icon=todesk
    Type=Application
    Categories=Network;RemoteAccess;
    Comment=ToDesk Remote Desktop (Fixed for Wayland/XWayland)
    Terminal=false
    X-KDE-SubstituteUID=false
  '';

  # Steam pressure-vessel container font support
  # Link CJK fonts to ~/.local/share/fonts/ where pressure-vessel can access them
  # Note: Home Manager automatically creates parent directories, so no mkdir needed
  home.file.".local/share/fonts/noto-cjk/NotoSansCJK-VF.otf.ttc".source = "${pkgs.noto-fonts-cjk-sans}/share/fonts/opentype/noto-cjk/NotoSansCJK-VF.otf.ttc";
  home.file.".local/share/fonts/source-han/SourceHanSans-VF.otf.ttc".source = "${pkgs.source-han-sans}/share/fonts/opentype/source-han-sans/SourceHanSans-VF.otf.ttc";

  # Fontconfig for Steam CJK font support
  # Steam container only reads user-level fontconfig, not system-level /etc/fonts/
  # CRITICAL: Direct font mapping (NOT via sans-serif) - Steam containers don't follow indirect aliases
  xdg.configFile."fontconfig/fonts.conf" = {
    force = true;
    text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <!-- CRITICAL: Direct Arial->CJK mapping (Steam's primary query font) -->
        <match target="pattern">
          <test qual="any" name="family">
            <string>Arial</string>
          </test>
          <edit name="family" mode="prepend" binding="strong">
            <string>Noto Sans CJK SC</string>
            <string>Source Han Sans SC</string>
            <string>WenQuanYi Zen Hei</string>
          </edit>
        </match>

        <!-- Direct Motiva Sans->CJK mapping (Steam UI font) -->
        <match target="pattern">
          <test qual="any" name="family">
            <string>Motiva Sans</string>
          </test>
          <edit name="family" mode="prepend" binding="strong">
            <string>Noto Sans CJK SC</string>
            <string>Source Han Sans SC</string>
            <string>WenQuanYi Zen Hei</string>
          </edit>
        </match>

        <!-- Direct Helvetica->CJK mapping -->
        <match target="pattern">
          <test qual="any" name="family">
            <string>Helvetica</string>
          </test>
          <edit name="family" mode="prepend" binding="strong">
            <string>Noto Sans CJK SC</string>
            <string>Source Han Sans SC</string>
          </edit>
        </match>

        <!-- Direct Times New Roman->CJK mapping -->
        <match target="pattern">
          <test qual="any" name="family">
            <string>Times New Roman</string>
          </test>
          <edit name="family" mode="prepend" binding="strong">
            <string>Noto Serif CJK SC</string>
            <string>Source Han Serif SC</string>
          </edit>
        </match>

        <!-- Default sans-serif font family with CJK priority -->
        <alias>
          <family>sans-serif</family>
          <prefer>
            <family>Noto Sans CJK SC</family>
            <family>Source Han Sans SC</family>
            <family>WenQuanYi Zen Hei</family>
          </prefer>
        </alias>

        <!-- Default serif font family -->
        <alias>
          <family>serif</family>
          <prefer>
            <family>Noto Serif CJK SC</family>
            <family>Source Han Serif SC</family>
          </prefer>
        </alias>

        <!-- Default monospace font family -->
        <alias>
          <family>monospace</family>
          <prefer>
            <family>Sarasa Mono SC</family>
            <family>Noto Sans Mono CJK SC</family>
          </prefer>
        </alias>
      </fontconfig>
    '';
  };

  services.kdeconnect.enable = true;

  # Plasma Manager - declarative KDE configuration
  programs.plasma = {
    enable = true;

    # Workspace settings
    workspace = {
      clickItemTo = "open";
      lookAndFeel = "org.kde.breezedark.desktop";
      cursor = {
        theme = "breeze_cursors";
        size = 24;
      };
      theme = "breeze-dark";
      colorScheme = "BreezeDark";
    };

    # Hotkeys configuration
    hotkeys.commands = {
      "launch-yakuake" = {
        name = "Launch Yakuake";
        key = "Meta+`";
        command = "yakuake";
      };
    };

    # Shortcuts
    shortcuts = {
      "kwin" = {
        # Desktop switching
        "Switch to Desktop 1" = "Meta+1";
        "Switch to Desktop 2" = "Meta+2";
        "Switch to Desktop 3" = "Meta+3";
        "Switch to Desktop 4" = "Meta+4";
        
        # Desktop navigation (scrolling workspaces)
        "Switch to Next Desktop" = "Meta+Ctrl+Right";
        "Switch to Previous Desktop" = "Meta+Ctrl+Left";
        "Switch One Desktop Down" = "Meta+Ctrl+Down";
        "Switch One Desktop Up" = "Meta+Ctrl+Up";
        
        # Window management
        "Window Close" = "Meta+Q";
        "Window Maximize" = "Meta+Up";
        "Window Minimize" = "Meta+M";
        
        # Window tiling (KDE native)
        "Window Quick Tile Bottom" = "Meta+Down";
        "Window Quick Tile Left" = "Meta+Left";
        "Window Quick Tile Right" = "Meta+Right";
        "Window Quick Tile Top Left" = "Meta+U";
        "Window Quick Tile Top Right" = "Meta+I";
        "Window Quick Tile Bottom Left" = "Meta+N";
        "Window Quick Tile Bottom Right" = "Meta+.";
        
        # Move window to other desktop
        "Window to Desktop 1" = "Meta+Shift+1";
        "Window to Desktop 2" = "Meta+Shift+2";
        "Window to Desktop 3" = "Meta+Shift+3";
        "Window to Desktop 4" = "Meta+Shift+4";
        "Window to Next Desktop" = "Meta+Shift+Right";
        "Window to Previous Desktop" = "Meta+Shift+Left";
      };
      "org.kde.konsole.desktop" = {
        "_launch" = "Meta+Return";
      };
    };

    # KWin configuration
    kwin = {
      edgeBarrier = 0;  # disable edge barriers
      cornerBarrier = false;
      
      effects = {
        blur.enable = true;
        desktopSwitching.animation = "slide";
        dimInactive.enable = false;
        translucency.enable = true;
      };
      
      virtualDesktops = {
        rows = 2;
        number = 4;
        names = [ "Main" "Code" "Web" "Media" ];
      };
    };

    # KRunner settings
    krunner = {
      position = "center";
      historyBehavior = "enableSuggestions";
    };

    # Screen locker
    kscreenlocker = {
      autoLock = true;
      timeout = 15;  # minutes
      lockOnResume = true;
    };

    # Power management
    powerdevil = {
      AC = {
        autoSuspend = {
          action = "sleep";  # Enable auto-sleep on AC power
          idleTimeout = 1800;  # 30 minutes
        };
        dimDisplay = {
          enable = true;
          idleTimeout = 600;  # 10 minutes
        };
        turnOffDisplay = {
          idleTimeout = 900;  # 15 minutes
          idleTimeoutWhenLocked = 180;  # 3 minutes when locked
        };
        powerButtonAction = "showLogoutScreen";
      };
      
      battery = {
        autoSuspend = {
          action = "sleep";
          idleTimeout = 900;  # 15 minutes
        };
        dimDisplay = {
          enable = true;
          idleTimeout = 180;  # 3 minutes
        };
        turnOffDisplay = {
          idleTimeout = 300;  # 5 minutes
          idleTimeoutWhenLocked = 60;  # 1 minute when locked
        };
        powerButtonAction = "sleep";
      };
      
      lowBattery = {
        autoSuspend = {
          action = "sleep";
          idleTimeout = 300;  # 5 minutes
        };
        dimDisplay = {
          enable = true;
          idleTimeout = 120;  # 2 minutes
        };
        turnOffDisplay = {
          idleTimeout = 180;  # 3 minutes
          idleTimeoutWhenLocked = 30;  # 30 seconds when locked
        };
        powerButtonAction = "sleep";
      };
    };

    # Panel configuration
    panels = [
      {
        location = "bottom";
        height = 44;
        floating = true;
        hiding = "none";
        alignment = "center";
        
        widgets = [
          {
            name = "org.kde.plasma.kickoff";
            config = {
              General = {
                icon = "start-here-kde";
              };
            };
          }
          {
            name = "org.kde.plasma.icontasks";
            config = {
              General = {
                launchers = [
                  "applications:org.kde.konsole.desktop"
                  "applications:google-chrome.desktop"
                  "applications:code-insiders.desktop"
                  "applications:org.kde.dolphin.desktop"
                ];
              };
            };
          }
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.pager"
          {
            systemTray.items = {
              shown = [
                "org.kde.plasma.networkmanagement"
                "org.kde.plasma.bluetooth"
                "org.kde.plasma.volume"
              ];
              hidden = [
                "org.kde.plasma.brightness"
              ];
            };
          }
          {
            name = "org.kde.plasma.weather";
            config = {
              General = {
                source = "bbcukmet|weather|Xi'an, Shaanxi, CN|2657896";
              };
            };
          }
          {
            digitalClock = {
              calendar = {
                firstDayOfWeek = "monday";
                plugins = [
                  "holidaysevents"  # korganizer calendar events
                  "alternatecalendar"  # lunar calendar support
                ];
              };
              time.format = "24h";
              date = {
                enable = true;
                format = "isoDate";
              };
            };
          }
          "org.kde.plasma.showdesktop"
        ];
      }
    ];

    # Desktop configuration
    desktop.icons = {
      arrangement = "leftToRight";
      lockInPlace = false;
      size = 2;  # 0=small, 1=medium, 2=large, 3=huge
      alignment = "left";
    };

    # File manager (Dolphin) settings
    configFile = {
      "dolphinrc"."General"."ShowFullPath" = true;
      "dolphinrc"."General"."RememberOpenedTabs" = false;
      
      # Konsole settings
      "konsolerc"."Desktop Entry"."DefaultProfile" = "Default.profile";
      
      # Yakuake settings
      "yakuakerc"."Animation"."Frames" = 20;
      "yakuakerc"."Window"."Height" = 50;
      "yakuakerc"."Window"."Width" = 100;
      "yakuakerc"."Window"."ShowTabBar" = "ShowTabBarWhenNeeded";
      "yakuakerc"."Dialogs"."FirstRun" = false;
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      # System management
      rebuild = "sudo nixos-rebuild switch";
      test = "sudo nixos-rebuild test";
      update-vscode = "~/nix-config/update-vscode-insiders.sh && rebuild";  # Update vscode insiders and rebuild
      
      # Nix maintenance
      gc = "sudo nix-collect-garbage";
      gcold = "sudo nix-collect-garbage --delete-older-than 30d";
      gcall = "sudo nix-collect-garbage -d";
      optimize = "sudo nix-store --optimize";
      clean = "sudo nix-collect-garbage -d && sudo nix-store --optimize";
      
      # Flake operations
      flake-update = "nix flake update";
      flake-check = "nix flake check";
      
      # System info
      list-gens = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
      
      # Python via uv
      python = "uv run python";
      python3 = "uv run python";
      
      # Common shortcuts
      ls = "eza --icons";
      ll = "eza -l --icons";
      la = "eza -la --icons";
      lt = "eza --tree --icons";
      cat = "bat";
    };

    history.size = 10000;
    history.ignoreAllDups = true;
    history.path = "$HOME/.zsh_history";
    history.ignorePatterns = [
      "rm *"
      "pkill *"
      "cp *"
    ];

    antidote = {
      enable = true;
      plugins = [
        ''
          mattmc3/zfunctions
          zsh-users/zsh-autosuggestions
          zdharma-continuum/fast-syntax-highlighting kind:defer
          zsh-users/zsh-history-substring-search
          ohmyzsh/ohmyzsh path:lib/git.zsh
          ohmyzsh/ohmyzsh path:plugins/git
          ohmyzsh/ohmyzsh path:plugins/colored-man-pages
          sindresorhus/pure
        ''
      ];
    };
  };

  home.stateVersion = "25.11";
}
