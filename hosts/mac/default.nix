{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Shared modules
    ../../modules/nix-settings.nix
    ../../modules/locale.nix
  ];

  # Set hostname
  networking.hostName = "mac";

  # Enable nix-daemon
  services.nix-daemon.enable = true;

  # Basic system packages for macOS
  environment.systemPackages = with pkgs; [
    vim
    git
    neovim
    wget
    nixfmt-rfc-style
  ];

  # Enable alternative shell support
  programs.zsh.enable = true;

  # Set Git commit hash for darwin-version
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on
  nixpkgs.hostPlatform = "aarch64-darwin";
}
