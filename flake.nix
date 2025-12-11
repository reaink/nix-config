{
  description = "Rea NixOS flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs.url = "git+file:///home/rea/nixpkgs-fork?ref=fcitx5-qt-fix";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";

    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-insiders = {
      url = "github:iosmanthus/code-insiders-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      winapps,
      vscode-insiders,
      ...
    }:
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs system;
          };
          modules = [
            ./configuration.nix
            inputs.sops-nix.nixosModules.sops

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";

              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.rea = {
                imports = [ ./home.nix ];
              };
            }

            (
              {
                pkgs,
                system ? pkgs.system,
                ...
              }:
              {
                environment.systemPackages = [
                  winapps.packages."${system}".winapps
                  winapps.packages."${system}".winapps-launcher # optional
                ];
              }
            )
          ];
        };
      };
    };
}
