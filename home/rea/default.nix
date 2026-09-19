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
  ]
  ++ (if pkgs.stdenv.hostPlatform.isLinux then [ ./linux.nix ] else [ ])
  ++ (if pkgs.stdenv.hostPlatform.isDarwin then [ ./darwin.nix ] else [ ]);

  # Basic user configuration
  home.username = "rea";
  home.homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/rea" else "/home/rea";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
