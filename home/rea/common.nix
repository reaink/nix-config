{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # Cross-platform packages
  home.packages = with pkgs; [
    # System utilities
    neofetch
    zip
    xz
    unzip
    p7zip

    # Modern CLI tools
    ripgrep
    jq
    eza
    bat
    bottom
    zoxide
    lazygit
    lazydocker
    gdu
    neovim
    redis
    rclone

    # Development tools - Rust (cross-platform)
    rustup
    protobuf
    clang
    libclang.lib
    lld
    gnumake
    pkg-config
    openssl
    openssl.dev
    android-tools

    uv
    fnm
    pnpm
    bun
    mariadb

    # Cloud & DevOps
    google-cloud-sdk
    ngrok

    # Database tools (cross-platform)
    prisma-engines_7

    # Development tools (cross-platform)
    imagemagick

    # Cross-platform GUI applications
    dbeaver-bin
    postman
    google-chrome
    telegram-desktop
    discord
    vscode
    obsidian
    cherry-studio
    qq
    firefox
  ];

  # Session variables - cross-platform
  home.sessionVariables = {
    # Rust development
    LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
    BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.clang}/lib/clang/${pkgs.lib.getVersion pkgs.clang}/include";
    OPENSSL_DIR = "${pkgs.openssl.dev}";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
    OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";

    # Node.js
    PNPM_HOME = "$HOME/.local/share/pnpm";
  };

  home.sessionPath = [
    "$HOME/.local/share/pnpm"
    "$HOME/.cargo/bin"
  ];

  # Keep rustup directories from being affected by nix gc
  home.file.".cargo/.keep".text = "";
  home.file.".rustup/.keep".text = "";

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user.name = "Rea";
      user.email = "hi@rea.ink";
    };
  };

  # Zsh configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      eval "$(fnm env --use-on-cd --shell zsh)"
      eval "$(zoxide init zsh)"
    '';

    shellAliases = {
      # Nix maintenance
      gc = "nix-collect-garbage";
      gcold = "nix-collect-garbage --delete-older-than 30d";
      gcall = "nix-collect-garbage -d";
      optimize = "nix-store --optimize";
      clean = "nix-collect-garbage -d && nix-store --optimize";

      # Flake operations
      flake-update = "nix flake update";
      flake-check = "nix flake check";

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

  # Tool integrations
  programs.fzf.enable = true;

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # Rime input method (cross-platform)
  programs.rime-keytao.enable = true;
}
