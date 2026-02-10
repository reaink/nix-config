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
}
