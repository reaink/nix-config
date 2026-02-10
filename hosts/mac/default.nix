{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Shared modules
    ../../modules/nix-settings.nix
  ];

  # Set hostname
  networking.hostName = "mac";

  # Basic system packages for macOS
  environment.systemPackages = with pkgs; [
    vim
    git
    neovim
    wget
    nixfmt
  ];

  # Define user
  users.users.rea = {
    name = "rea";
    home = "/Users/rea";
  };

  # Enable alternative shell support
  programs.zsh.enable = true;

  # Set Git commit hash for darwin-version
  system.configurationRevision = null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on
  nixpkgs.hostPlatform = "aarch64-darwin";
}
