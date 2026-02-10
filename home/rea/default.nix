{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./common.nix
    ./linux.nix
    ./darwin.nix
  ];

  # Basic user configuration
  home.username = "rea";
  home.homeDirectory = if pkgs.stdenv.isDarwin 
    then "/Users/rea" 
    else "/home/rea";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
