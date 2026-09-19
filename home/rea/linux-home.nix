{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./common.nix
    ./linux.nix
  ];

  # Basic user configuration
  home.username = "rea";
  home.homeDirectory = "/home/rea";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  # Set explicitly so the rime-keytao module's default (which reads the
  # deprecated stdenv.isDarwin) is never evaluated.
  programs.rime-keytao.rimeDataDir = ".local/share/fcitx5/rime";
}
