{
  config,
  pkgs,
  r3playx,
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
      uv
      fnm
      pnpm
      lazygit
      lazydocker

      # kdePackages
      kdePackages.kamoso

      warp-terminal
      google-chrome
      vscode
      # wechat
      wechat-uos
      qq
      cherry-studio
      telegram-desktop
      steam
      lutris
      postman
      dbeaver-bin
      xemu
    ])
    ++ [
      r3playx.packages."${pkgs.system}".r3playx
    ];

  programs.git = {
    enable = true;
    userName = "Rea";
    userEmail = "hi@rea.ink";
  };

  programs.fzf.enable = true;

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

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
          sindresorhus/pure
        ''
      ];
    };
  };

  home.stateVersion = "25.05";
}
