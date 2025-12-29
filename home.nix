{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.noctalia.homeModules.default
    inputs.niri.homeModules.niri
  ];

  home.username = "rea";
  home.homeDirectory = "/home/rea";

  home.packages =
    (with pkgs; [
      neofetch
      alacritty
      kitty

      zip
      xz
      unzip
      p7zip

      ripgrep
      jq
      eza
      bat

      # Screenshot tools
      grim      # Wayland screenshot
      satty     # Screenshot annotation
      slurp     # Screen region selector

      # Clipboard tools
      wl-clipboard  # Wayland clipboard utilities (wl-copy, wl-paste)
      clipse        # Modern TUI clipboard manager

      # Xwayland support for X11 apps (WeChat, QQ, Steam, etc.)
      xwayland-satellite

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

      # kdePackages
      kdePackages.akonadi
      kdePackages.akonadi-import-wizard
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

      warp-terminal
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
      wpsoffice
      gdu
      ngrok
      shopify-cli
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

  services.kdeconnect.enable = true;

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

  programs.niri = {
    settings = {
      # Don't spawn noctalia-shell here - managed by systemd service in noctalia.nix
      spawn-at-startup = [
        # Start Clipse clipboard manager daemon
        {
          command = [
            "sh"
            "-c"
            "clipse -listen"
          ];
        }
        # Start Xwayland for X11 apps (WeChat, QQ, Steam, etc.)
        {
          command = [ "xwayland-satellite" ];
        }
      ];

      input = {
        keyboard.xkb = {
          layout = "us";
        };
        touchpad = {
          tap = true;
          natural-scroll = true;
        };
      };

      binds =
        with config.lib.niri.actions;
        let
          noctalia =
            cmd:
            [
              "noctalia-shell"
              "ipc"
              "call"
            ]
            ++ (pkgs.lib.splitString " " cmd);
        in
        {
          # Noctalia widgets
          "Mod+Space".action.spawn = noctalia "launcher toggle";
          "Mod+Shift+L".action.spawn = noctalia "lockScreen toggle";
          "Mod+Shift+E".action.spawn = noctalia "sessionMenu toggle";

          # Audio controls
          "XF86AudioLowerVolume".action.spawn = noctalia "volume decrease";
          "XF86AudioRaiseVolume".action.spawn = noctalia "volume increase";
          "XF86AudioMute".action.spawn = noctalia "volume muteOutput";

          # Brightness controls
          "XF86MonBrightnessDown".action.spawn = noctalia "brightness decrease";
          "XF86MonBrightnessUp".action.spawn = noctalia "brightness increase";

          # Window management
          "Mod+Return".action.spawn = "kitty";
          "Mod+Q".action.close-window = { };

          # Workspace navigation
          "Mod+1".action.focus-workspace = 1;
          "Mod+2".action.focus-workspace = 2;
          "Mod+3".action.focus-workspace = 3;
          "Mod+4".action.focus-workspace = 4;

          # Move window to workspace
          "Mod+Shift+1".action.move-window-to-workspace = 1;
          "Mod+Shift+2".action.move-window-to-workspace = 2;
          "Mod+Shift+3".action.move-window-to-workspace = 3;
          "Mod+Shift+4".action.move-window-to-workspace = 4;

          # Focus navigation
          "Mod+Left".action.focus-column-left = { };
          "Mod+Down".action.focus-window-down = { };
          "Mod+Up".action.focus-window-up = { };
          "Mod+Right".action.focus-column-right = { };
          "Mod+H".action.focus-column-left = { };
          "Mod+J".action.focus-window-down = { };
          "Mod+K".action.focus-window-up = { };
          "Mod+L".action.focus-column-right = { };

          # Screenshots
          "Print".action.spawn = [
            "sh"
            "-c"
            "grim -g \"$(slurp)\" - | satty --filename - --output-filename ~/Pictures/Screenshots/$(date '+%Y%m%d_%H%M%S').png"
          ];
          "Shift+Print".action.spawn = [
            "sh"
            "-c"
            "grim ~/Pictures/Screenshots/$(date '+%Y%m%d_%H%M%S').png"
          ];

          # Clipboard history
          "Mod+V".action.spawn = [ "kitty" "--class" "clipse" "-o" "initial_window_width=800" "-o" "initial_window_height=576" "clipse" ];
        };

      outputs."DP-1" = {
        mode = {
          width = 3840;
          height = 2160;
          refresh = 60.0;
        };
        scale = 1.5;
        variable-refresh-rate = false;
      };

      # Window rules
      window-rules = [
        {
          matches = [
            { app-id = "^clipse$"; }
          ];
          open-floating = true;
          default-column-width = { proportion = 0.3; };
          open-maximized = false;
          open-fullscreen = false;
        }
      ];

      # Layout configuration
      layout = {
        gaps = 8;
        center-focused-column = "never";
      };

      # Environment variables for Wayland
      environment = {
        NIXOS_OZONE_WL = "1";
        MOZ_ENABLE_WAYLAND = "1";
        # Xwayland display
        DISPLAY = ":0";
      };
    };
  };

  # Noctalia shell configuration
  programs.noctalia-shell = {
    enable = true;
    # Don't set package here since we're using NixOS module
    package = null;

    settings = {
      bar = {
        position = "top";
        density = "default";
        showCapsule = true;
        widgets = {
          left = [
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
            {
              id = "WiFi";
            }
            {
              id = "Bluetooth";
            }
            {
              id = "ActiveWindow";
            }
          ];
          center = [
            {
              id = "Workspace";
              hideUnoccupied = false;
              labelMode = "none";
            }
          ];
          right = [
            {
              id = "SystemMonitor";
            }
            {
              id = "Battery";
              alwaysShowPercentage = false;
              warningThreshold = 30;
            }
            {
              id = "Clock";
              formatHorizontal = "HH:mm";
              formatVertical = "HH mm";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
          ];
        };
      };
    };
  };

  home.stateVersion = "25.11";
}
