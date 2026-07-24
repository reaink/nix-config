{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [ ];

  catppuccin = {
    enable = true;
    autoEnable = true;
  };

  # Cross-platform packages
  home.packages =
    with pkgs;
    [
      # System utilities
      fastfetch
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

      # Development tools - Rust (cross-platform)
      rustup
      protobuf
      libclang.lib
      gnumake
      pkg-config
      openssl
      openssl.dev
      android-tools

      uv
      python3
      python3Packages.huggingface-hub
      fnm
      pnpm
      bun
      mariadb
      google-cloud-sdk
      awscli2
      ngrok
      claude-code
      github-copilot-cli
      tmux

      # Database tools (cross-platform)
      # prisma-engines_7 # disabled: build fails with new rustc (metrics-0.23.0 lifetime bug, nixpkgs upstream issue)

      # Development tools (cross-platform)
      typescript-language-server
      imagemagick
      ffmpeg
      mdbook
      lsof
      fd
      tree-sitter
      sqlite
      stylua
      shfmt
      shellcheck
      prettier
      ruff

      # Cross-platform GUI applications
      dbeaver-bin
      postman
      google-chrome
      telegram-desktop
      discord
      vscode-latest
      obsidian
      firefox
      antigravity

      # Fonts
      pkgs.nerd-fonts.jetbrains-mono
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      clang
      lld
      marktext
    ];

  # GitHub CLI with gh-notify extension
  programs.gh = {
    enable = true;
    extensions = [ pkgs.gh-notify ];
  };

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
      export EZA_PARAMS=('--icons')
      if [ -f /run/secrets/github-token ]; then
        export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat /run/secrets/github-token)
      fi
    '';

    shellAliases = {
      cc = "claude --dangerously-skip-permissions";
      claudetg = "claude --channels plugin:telegram@claude-plugins-official";

      # Flake operations
      flake-update = "nix flake update";
      flake-check = "nix flake check";
      update = "nix flake update && sh ~/nix-config/update-hashes.sh";
      update-vscode = "sh ~/nix-config/update-hashes.sh vscode";
      update-claude = "sh ~/nix-config/update-hashes.sh claude-code";
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
          z-shell/zsh-eza
          fdellwing/zsh-bat
        ''
      ];
    };
  };

  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMonoNerdFontMono";
      size = 12;
    };
    settings = {
      confirm_os_window_close = 0;
      scrollback_lines = 10000;
      linux_display_server = "wayland"; # force Wayland backend so text-input-v3 works with fcitx5
      window_padding_width = 8;
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_bar_edge = "bottom";
      tab_title_template = "{index}: {title}";
      open_url_modifiers = "ctrl";
    };
    keybindings = {
      # Tab management
      "ctrl+shift+t" = "new_tab_with_cwd";
      "ctrl+shift+w" = "close_tab"; # was ctrl+w, conflicts with nvim <C-w> window prefix
      "ctrl+shift+h" = "previous_tab";
      "ctrl+shift+l" = "next_tab";
      "ctrl+shift+," = "move_tab_backward";
      "ctrl+shift+." = "move_tab_forward";
      "ctrl+1" = "goto_tab 1";
      "ctrl+2" = "goto_tab 2";
      "ctrl+3" = "goto_tab 3";
      "ctrl+4" = "goto_tab 4";
      "ctrl+5" = "goto_tab 5";
      "ctrl+6" = "goto_tab 6";
      "ctrl+7" = "goto_tab 7";
      "ctrl+8" = "goto_tab 8";
      "ctrl+9" = "goto_tab 9";
      # Tab jump by number (macOS cmd style)
      "cmd+1" = "goto_tab 1";
      "cmd+2" = "goto_tab 2";
      "cmd+3" = "goto_tab 3";
      "cmd+4" = "goto_tab 4";
      "cmd+5" = "goto_tab 5";
      "cmd+6" = "goto_tab 6";
      "cmd+7" = "goto_tab 7";
      "cmd+8" = "goto_tab 8";
      "cmd+9" = "goto_tab 9";
      # Bracket-based prev/next tab switching
      "cmd+[" = "previous_tab"; # macOS style
      "cmd+]" = "next_tab";
      # Do NOT bind plain ctrl+[ — it is the Escape byte in terminals and would break nvim
      "ctrl+shift+[" = "previous_tab";
      "ctrl+shift+]" = "next_tab";
      # Window (pane) splitting
      "ctrl+shift+\\" = "launch --location=vsplit --cwd=current";
      "ctrl+shift+-" = "launch --location=hsplit --cwd=current";
      "ctrl+shift+q" = "close_window";
      # Window navigation (ctrl+alt to avoid conflicts with nvim alt+hjkl in insert mode)
      "ctrl+alt+h" = "neighboring_window left";
      "ctrl+alt+j" = "neighboring_window down";
      "ctrl+alt+k" = "neighboring_window up";
      "ctrl+alt+l" = "neighboring_window right";
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
