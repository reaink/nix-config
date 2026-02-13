{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Enable flakes and new nix command
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Use Chinese mirrors for faster downloads
  nix.settings.substituters = [
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirror.sjtu.edu.cn/nix-channels/store"
    "https://mirror.nju.edu.cn/nix-channels/store"
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
  ];

  nix.settings.trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  # Auto-optimize store to save space (nix-darwin uses optimise.automatic)
  nix.optimise.automatic = true;

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 1w";
  }
  // (
    if pkgs.stdenv.isDarwin then
      {
        interval = {
          Weekday = 0;
          Hour = 0;
          Minute = 0;
        }; # Weekly on Sunday at midnight (nix-darwin)
      }
    else
      {
        dates = "weekly"; # Weekly (NixOS)
      }
  );

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Allow insecure packages
  nixpkgs.config.permittedInsecurePackages = [
    "google-chrome-144.0.7559.97"
  ];
}
