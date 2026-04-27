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
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirror.nju.edu.cn/nix-channels/store"
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
    "https://noctalia.cachix.org"
    "https://niri.cachix.org"
  ];

  nix.settings.trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
  ];

  nix.settings.trusted-users = [
    "root"
    "rea"
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
}
