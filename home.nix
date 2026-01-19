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

  home.stateVersion = "25.11";
}
