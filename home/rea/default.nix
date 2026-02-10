{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./common.nix
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    ./linux.nix
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
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
