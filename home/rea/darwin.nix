{ config, pkgs, lib, inputs, ... }:

{
  # macOS-specific configuration
  # Currently minimal - can be expanded with macOS-specific packages and settings

  # macOS-specific environment variables (if needed)
  home.sessionVariables = {
    # Example: DYLD_LIBRARY_PATH if needed
  };

  # macOS-specific packages (can be added as needed)
  home.packages = with pkgs; [
    # Add macOS-specific packages here
  ];

  # Override Zsh aliases for macOS-specific commands
  programs.zsh.shellAliases = {
    rebuild = "darwin-rebuild switch --flake ~/nix-config#mac";
    test = "darwin-rebuild check --flake ~/nix-config#mac";
  };
}
