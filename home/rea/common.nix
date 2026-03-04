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
    redis
    rclone

    # Neovim dependencies (also available globally as CLI tools)
    lsof
    fd
    tree-sitter
    sqlite
    stylua
    shfmt
    shellcheck

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
    gh
    claude-code

    # Database tools (cross-platform)
    prisma-engines_7

    # Development tools (cross-platform)
    imagemagick
    ffmpeg
    mdbook

    # Cross-platform GUI applications
    dbeaver-bin
    postman
    google-chrome
    telegram-desktop
    discord
    vscode-latest
    obsidian
    cherry-studio
    qq
    firefox
    opencode
    opencode-desktop

    # Fonts
    pkgs.nerd-fonts.jetbrains-mono
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
    "$HOME/.local/bin"
    "$HOME/.local/share/pnpm"
    "$HOME/.cargo/bin"
  ];

  # Keep rustup directories from being affected by nix gc
  home.file.".cargo/.keep".text = "";
  home.file.".rustup/.keep".text = "";

  # Neovim — use programs.neovim so extraPackages are injected into the
  # wrapper's PATH, making them available regardless of how nvim is launched
  # (e.g. from a GUI or without a full shell session).
  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      lsof
      fd
      tree-sitter
      sqlite
      stylua
      shfmt
      shellcheck
    ];
  };

  # AstroNvim configuration — symlink the entire config directory from the
  # pinned GitHub source so `rebuild` always applies the latest locked version.
  xdg.configFile."nvim".source = inputs.astro-nvim-config;

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user.name = "Rea";
      user.email = "hi@rea.ink";
      init.defaultBranch = "main";
      pull.rebase = true;
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
      update-vscode = "sh update-vscode-hash.sh";

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
          zsh-users/zsh-history-substring-search
          ohmyzsh/ohmyzsh path:lib/git.zsh
          ohmyzsh/ohmyzsh path:plugins/git
          ohmyzsh/ohmyzsh path:plugins/colored-man-pages
        ''
      ];
    };
  };

  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 13;
    };
    settings = {
      confirm_os_window_close = 0;
      scrollback_lines = 10000;
      window_padding_width = 8;
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_bar_edge = "bottom";
      tab_title_template = "{index}: {title}";
    };
    keybindings = {
      # Tab management
      "ctrl+t" = "new_tab_with_cwd";
      "ctrl+w" = "close_tab";
      "ctrl+shift+h" = "previous_tab";
      "ctrl+shift+l" = "next_tab";
      "ctrl+1" = "goto_tab 1";
      "ctrl+2" = "goto_tab 2";
      "ctrl+3" = "goto_tab 3";
      "ctrl+4" = "goto_tab 4";
      "ctrl+5" = "goto_tab 5";
      # Window (pane) splitting
      "ctrl+shift+\\" = "launch --location=vsplit --cwd=current";
      "ctrl+shift+-" = "launch --location=hsplit --cwd=current";
      "ctrl+shift+q" = "close_window";
      # Window navigation
      "alt+h" = "neighboring_window left";
      "alt+j" = "neighboring_window down";
      "alt+k" = "neighboring_window up";
      "alt+l" = "neighboring_window right";
    };
  };

  catppuccin.kitty = {
    enable = true;
    flavor = "mocha";
  };

  # Tool integrations
  programs.fzf.enable = true;

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  catppuccin.starship = {
    enable = true;
    flavor = "mocha";
  };

  catppuccin.zsh-syntax-highlighting = {
    enable = true;
    flavor = "mocha";
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # Rime input method (cross-platform)
  programs.rime-keytao.enable = true;
}
