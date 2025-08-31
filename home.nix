{ config, pkgs, r3playx, ...}:

{
  home.username = "rea";
  home.homeDirectory = "/home/rea";

  home.packages = (with pkgs; [
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
  ]) ++ [
    r3playx.packages."${pkgs.system}".r3playx
  ];


  programs.git = {
    enable = true;
    userName = "Rea";
    userEmail = "hi@rea.ink";
  };
  programs.fzf.enable = true;

  programs.starship = {
    enable = true;
    settings = {
      add_newLine = false;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
    };
  };

  home.stateVersion = "25.05";
}
