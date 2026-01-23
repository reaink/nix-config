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
      kdePackages.kdenlive
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
      inputs.vscode-insiders.packages.${pkgs.stdenv.hostPlatform.system}.vscode-insider
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
      gdu
      ngrok
      # shopify-cli  # build broken: pnpm ENOTDIR error
      winboat
    ])
    ++ [
    ];

  home.sessionVariables = {
    LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
    BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.clang}/lib/clang/${pkgs.lib.getVersion pkgs.clang}/include";

    OPENSSL_DIR = "${pkgs.openssl.dev}";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
    OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
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
  };

  home.sessionPath = [
    "$HOME/.local/share/pnpm"
    "$HOME/.cargo/bin"
  ];

  programs.zsh.initContent = ''
    eval "$(fnm env --use-on-cd --shell zsh)"
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
    
    theme = {
      name = "Breeze";
      package = pkgs.kdePackages.breeze-gtk;
    };
    
    iconTheme = {
      name = "breeze";
      package = pkgs.kdePackages.breeze-icons;
    };
    
    cursorTheme = {
      name = "breeze_cursors";
      package = pkgs.kdePackages.breeze;
      size = 24;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    gtk2 = {
      configLocation = "${config.xdg.stateHome}/gtk-2.0/gtkrc";
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
          action = "nothing";
        };
        dimDisplay = {
          enable = true;
          idleTimeout = 600;  # 10 minutes
        };
        turnOffDisplay = {
          idleTimeout = 900;  # 15 minutes
          idleTimeoutWhenLocked = 120;  # 2 minutes when locked
        };
        powerButtonAction = "showLogoutScreen";
      };
      
      battery = {
        autoSuspend = {
          action = "sleep";
          idleTimeout = 1800;  # 30 minutes
        };
        dimDisplay = {
          enable = true;
          idleTimeout = 300;  # 5 minutes
        };
        turnOffDisplay = {
          idleTimeout = 600;  # 10 minutes
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
        floating = false;
        hiding = "none";
        
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
