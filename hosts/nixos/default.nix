{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    # Host-specific configuration
    ./configuration.nix
    ./hardware-configuration.nix
    ./sunshine.nix

    # Shared modules
    ../../modules/nix-settings.nix
    ../../modules/locale.nix

    # External inputs
    inputs.sops-nix.nixosModules.sops
  ];
}
