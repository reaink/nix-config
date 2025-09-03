{
  config,
  pkgs,
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

      rustup
      protobuf
      clang
      libclang.lib
      lld
      gnumake
      pkg-config

      uv
      fnm
      pnpm
      lazygit
      lazydocker
      google-cloud-sdk
      gparted

      # kdePackages
      kdePackages.kamoso

      warp-terminal
      google-chrome
      vscode
      wechat-uos
      qq
      cherry-studio
      telegram-desktop
      steam
      lutris
      postman
      dbeaver-bin
      splayer
      spotify
      discord
    ])
    ++ [
    ];

  home.sessionVariables = {
    LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
    BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.clang}/lib/clang/${pkgs.lib.getVersion pkgs.clang}/include";

    OPENSSL_DIR = "${pkgs.openssl.dev}";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
    OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
    PNPM_HOME = "$HOME/.local/share/pnpm";
  };

  home.sessionPath = [
    "$HOME/.local/share/pnpm"
  ];

  programs.zsh.initContent = ''
    eval "$(fnm env --use-on-cd --shell zsh)"
  '';

  programs.git = {
    enable = true;
    userName = "Rea";
    userEmail = "hi@rea.ink";
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
      update = "sudo nixos-rebuild switch";
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

  home.stateVersion = "25.05";
}
