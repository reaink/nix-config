{ config, pkgs, lib, ... }:

{
  # Enable flakes and new nix command
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Use Chinese mirrors for faster downloads
  nix.settings.substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirror.nju.edu.cn/nix-channels/store"
    "https://nix-community.cachix.org"
  ];

  nix.settings.trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  # Auto-optimize store to save space
  nix.settings.auto-optimise-store = true;
  nix.optimise.automatic = true;

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
