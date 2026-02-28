{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  config = lib.mkIf pkgs.stdenv.isLinux {
    # Linux-specific packages
    home.packages = with pkgs; [
      # Tauri/GTK development libraries
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
      dbus
      dbus.dev
      gdk-pixbuf

      # Media and productivity GUI apps
      vlc
      mpv
      spotify
      android-studio
      libreoffice-fresh
      shotcut
      steam
      todesk

      # KDE packages
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
      kdePackages.plasma-workspace
      kdePackages.kweather

      # Linux-specific GUI apps
      wechat-uos
      wpsoffice-cn

      # System tools
      gparted
      appimage-run
      # gearlever  # broken: dwarfs fails with boost 1.89 (upstream nixpkgs issue)

      # Gaming
      (lutris.override {
        extraPkgs = pkgs: [
          pkgs.wineWow64Packages.stable
        ];
      })
      prismlauncher

      # Media capture
      (wrapOBS {
        plugins = with obs-studio-plugins; [
          obs-vaapi
          obs-vkcapture
          obs-pipewire-audio-capture
        ];
      })
      splayer

      # Remote desktop
      todesk
      (writeShellScriptBin "todesk-gui" ''
        # Add X11 authorization
        ${xhost}/bin/xhost +local: >/dev/null 2>&1 || true

        # Force correct environment
        export DISPLAY=:0
        export QT_QPA_PLATFORM=xcb
        export GDK_BACKEND=x11
        export XAUTHORITY="$HOME/.Xauthority"

        # Kill existing GUI instances
        ${procps}/bin/pkill -f "ToDesk desktop" 2>/dev/null || true
        sleep 1

        # Launch with error filtering
        exec ${todesk}/bin/todesk desktop 2>&1 | grep -v "iCCP\|libpng warning" || true
      '')

      # Xbox controller tools
      antimicrox
      jstest-gtk
      linuxConsoleTools
      kitty

      winboat
    ];

    # Linux-specific environment variables
    home.sessionVariables = {
      # Fix dynamic linking for Rust binaries on Linux
      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
        pkgs.openssl
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
      ];

      # Tauri/GTK PKG_CONFIG
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

      # Disable NVIDIA driver's internal threaded GL optimizations.
      # This is the root fix for EGL mutex deadlocks in WebKit and Electron on NVIDIA.
      # Without this, libnvidia-glsi causes deadlocks when multiple threads call EGL simultaneously.
      __GL_THREADED_OPTIMIZATIONS = "0";

      # Disable WebKit DMA-BUF renderer (zero-copy path) which triggers EGL multi-thread issues.
      # Keeps hardware compositing active, only disables the problematic DMA-BUF sharing path.
      WEBKIT_DISABLE_DMABUF_RENDERER = "1";

      # Wayland & GTK settings
      GDK_BACKEND = "wayland,x11";
      GSK_RENDERER = "ngl";
      GTK_OVERLAY_SCROLLING = "0";
      WLR_NO_HARDWARE_CURSORS = "1";

      # Chromium hardware acceleration
      MOZ_DISABLE_RDD_SANDBOX = "1";
      NVD_BACKEND = "direct";
    };

    # Linux-specific Zsh aliases (override common.nix aliases)
    programs.zsh.shellAliases = lib.mkForce {
      # Inherit common aliases
      python = "uv run python";
      python3 = "uv run python";
      ls = "eza --icons";
      ll = "eza -l --icons";
      la = "eza -la --icons";
      lt = "eza --tree --icons";
      cat = "bat";
      flake-update = "nix flake update";
      flake-check = "nix flake check";
      update-vscode = "sh ~/nix-config/update-vscode-hash.sh";

      # Linux-specific (with sudo)
      rebuild = "sudo nixos-rebuild switch --flake ~/nix-config\\#nixos";
      test = "sudo nixos-rebuild test --flake ~/nix-config\\#nixos";
      gc = "sudo nix-collect-garbage";
      gcold = "sudo nix-collect-garbage --delete-older-than 30d";
      gcall = "sudo nix-collect-garbage -d";
      optimize = "sudo nix-store --optimize";
      clean = "sudo nix-collect-garbage -d && sudo nix-store --optimize";
      list-gens = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
    };

    # GTK theme configuration
    gtk = {
      enable = true;

      theme = {
        name = "Arc-Dark";
        package = pkgs.arc-theme;
      };

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
        gtk-application-prefer-dark-theme = true;
        gtk-icon-theme-name = "Papirus-Dark";
        gtk-button-images = true;
        gtk-menu-images = true;
        gtk-enable-animations = false;
        gtk-cursor-theme-size = 24;
      };

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-icon-theme-name = "Papirus-Dark";
        gtk-enable-animations = false;
      };

      gtk2 = {
        configLocation = "${config.xdg.stateHome}/gtk-2.0/gtkrc";
        force = true;
        extraConfig = "";
      };
    };

    # Qt/KDE configuration
    qt = {
      enable = true;
      platformTheme.name = "kde";
      style.name = "breeze";
    };

    # GTK settings files
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
      gtk-enable-animations=0
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

    # ToDesk desktop launcher
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

    # Steam font support
    home.file.".local/share/fonts/noto-cjk/NotoSansCJK-VF.otf.ttc".source =
      "${pkgs.noto-fonts-cjk-sans}/share/fonts/opentype/noto-cjk/NotoSansCJK-VF.otf.ttc";
    home.file.".local/share/fonts/source-han/SourceHanSans-VF.otf.ttc".source =
      "${pkgs.source-han-sans}/share/fonts/opentype/source-han-sans/SourceHanSans-VF.otf.ttc";

    # Fontconfig for Steam CJK support
    xdg.configFile."fontconfig/fonts.conf" = {
      force = true;
      text = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <!-- Direct Arial->CJK mapping (Steam's primary query font) -->
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

          <!-- Default font aliases -->
          <alias>
            <family>sans-serif</family>
            <prefer>
              <family>Noto Sans CJK SC</family>
              <family>Source Han Sans SC</family>
              <family>WenQuanYi Zen Hei</family>
            </prefer>
          </alias>

          <alias>
            <family>serif</family>
            <prefer>
              <family>Noto Serif CJK SC</family>
              <family>Source Han Serif SC</family>
            </prefer>
          </alias>

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

    # KDE Connect
    services.kdeconnect.enable = true;

    # Plasma Manager - declarative KDE configuration
    programs.plasma = {
      enable = true;

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

      hotkeys.commands = {
        "launch-yakuake" = {
          name = "Launch Yakuake";
          key = "Meta+`";
          command = "yakuake";
        };
      };

      shortcuts = {
        "kwin" = {
          "Switch to Desktop 1" = "Meta+1";
          "Switch to Desktop 2" = "Meta+2";
          "Switch to Desktop 3" = "Meta+3";
          "Switch to Desktop 4" = "Meta+4";
          "Switch to Next Desktop" = "Meta+Ctrl+Right";
          "Switch to Previous Desktop" = "Meta+Ctrl+Left";
          "Switch One Desktop Down" = "Meta+Ctrl+Down";
          "Switch One Desktop Up" = "Meta+Ctrl+Up";
          "Window Close" = "Meta+Q";
          "Window Maximize" = "Meta+Up";
          "Window Minimize" = "Meta+M";
          "Window Quick Tile Bottom" = "Meta+Down";
          "Window Quick Tile Left" = "Meta+Left";
          "Window Quick Tile Right" = "Meta+Right";
          "Window Quick Tile Top Left" = "Meta+U";
          "Window Quick Tile Top Right" = "Meta+I";
          "Window Quick Tile Bottom Left" = "Meta+N";
          "Window Quick Tile Bottom Right" = "Meta+.";
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

      kwin = {
        edgeBarrier = 0;
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
          names = [
            "Main"
            "Code"
            "Web"
            "Media"
          ];
        };
      };

      krunner = {
        position = "center";
        historyBehavior = "enableSuggestions";
      };

      kscreenlocker = {
        autoLock = true;
        timeout = 15;
        lockOnResume = true;
      };

      powerdevil = {
        AC = {
          autoSuspend = {
            action = "sleep";
            idleTimeout = 1800;
          };
          dimDisplay = {
            enable = true;
            idleTimeout = 600;
          };
          turnOffDisplay = {
            idleTimeout = 900;
            idleTimeoutWhenLocked = 180;
          };
          powerButtonAction = "showLogoutScreen";
        };

        battery = {
          autoSuspend = {
            action = "sleep";
            idleTimeout = 900;
          };
          dimDisplay = {
            enable = true;
            idleTimeout = 180;
          };
          turnOffDisplay = {
            idleTimeout = 300;
            idleTimeoutWhenLocked = 60;
          };
          powerButtonAction = "sleep";
        };

        lowBattery = {
          autoSuspend = {
            action = "sleep";
            idleTimeout = 300;
          };
          dimDisplay = {
            enable = true;
            idleTimeout = 120;
          };
          turnOffDisplay = {
            idleTimeout = 180;
            idleTimeoutWhenLocked = 30;
          };
          powerButtonAction = "sleep";
        };
      };

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
                    "holidaysevents"
                    "alternatecalendar"
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

      desktop.icons = {
        arrangement = "leftToRight";
        lockInPlace = false;
        size = 2;
        alignment = "left";
      };

      configFile = {
        "dolphinrc"."General"."ShowFullPath" = true;
        "dolphinrc"."General"."RememberOpenedTabs" = false;
        "konsolerc"."Desktop Entry"."DefaultProfile" = "Default.profile";
        "yakuakerc"."Animation"."Frames" = 20;
        "yakuakerc"."Window"."Height" = 50;
        "yakuakerc"."Window"."Width" = 100;
        "yakuakerc"."Window"."ShowTabBar" = "ShowTabBarWhenNeeded";
        "yakuakerc"."Dialogs"."FirstRun" = false;
      };
    };
  };
}
