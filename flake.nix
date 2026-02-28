{
  description = "Rea's unified NixOS & nix-darwin configuration";

  inputs = {
    # Unified nixpkgs for both NixOS and macOS
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    # nix-darwin for macOS system configuration
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager for user environment (cross-platform)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SOPS for secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Plasma Manager for KDE configuration (Linux only)
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Rime input method configuration
    rime-keytao = {
      url = "github:xkinput/KeyTao";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      stablePkgsFor =
        system:
        import inputs.nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
        };
    in
    {
      # NixOS configuration
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            # Apply custom overlays
            {
              nixpkgs.overlays = [
                (import ./overlays/vscode-latest.nix)
                (import ./overlays/fix-picosvg-tests.nix)
                # sunshine/gearlever(dwarfs) are broken in unstable (boost 1.89 regression), use stable
                (_: _: { sunshine = (stablePkgsFor "x86_64-linux").sunshine; })
                (_: _: { gearlever = (stablePkgsFor "x86_64-linux").gearlever; })
              ];
            }

            # Host-specific configuration
            ./hosts/nixos

            # Home Manager integration
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.rea = {
                imports = [
                  ./home/rea/linux-home.nix
                  inputs.plasma-manager.homeModules.plasma-manager
                  inputs.rime-keytao.homeManagerModules.default
                ];
              };
            }
          ];
        };
      };

      # macOS configuration
      darwinConfigurations = {
        mac = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs self; };
          modules = [
            # Apply custom overlays
            {
              nixpkgs.overlays = [
                (import ./overlays/vscode-latest.nix)
              ];
            }

            # Host-specific configuration
            ./hosts/mac

            # Home Manager integration
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.rea = {
                imports = [
                  ./home/rea/darwin-home.nix
                  inputs.rime-keytao.homeManagerModules.default
                ];
              };
            }
          ];
        };
      };
    };
}
