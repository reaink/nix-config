{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

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

  # Font configuration (matching Linux setup)
  fonts = {
    packages = with pkgs; [
      hack-font
      inter
      jetbrains-mono
      dejavu_fonts
      liberation_ttf
      monaspace
      maple-mono.truetype
      maple-mono.NF-unhinted
      maple-mono.NF-CN-unhinted
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      nerd-fonts.caskaydia-mono
      sarasa-gothic
      source-code-pro
      source-han-mono
      source-han-sans
      source-han-serif
      wqy_zenhei
      lxgw-wenkai
    ];
  };

  # Set Git commit hash for darwin-version
  system.configurationRevision = null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on
  nixpkgs.hostPlatform = "aarch64-darwin";
}
