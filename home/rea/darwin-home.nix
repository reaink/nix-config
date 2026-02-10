{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./common.nix
    ./darwin.nix
  ];

  # Basic user configuration
  home.username = "rea";
  home.homeDirectory = "/Users/rea";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
