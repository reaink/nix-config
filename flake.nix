{
  description = "Rea's unified NixOS & nix-darwin configuration";

  nixConfig = {
    extra-substituters = [
      "https://noctalia.cachix.org"
      "https://niri.cachix.org"
    ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
    ];
  };

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

    # Rime input method configuration
    rime-keytao = {
      url = "github:xkinput/KeyTao";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Catppuccin theme
    catppuccin = {
      url = "github:catppuccin/nix";
    };

    # AstroNvim user configuration
    astro-nvim-config = {
      url = "github:reaink/astro-nvim-config";
      flake = false;
    };

    # niri Wayland compositor
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Noctalia desktop shell
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # KeyTao installer GUI
    keytao-installer = {
      url = "git+ssh://git@github.com/xkinput/keytao-installer.git?ref=refs/tags/v0.0.14-alpha&rev=6a2b65930c7d1662e6b3c9a29ed3d4d3d9b3423c";
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
                (import ./overlays/fix-openldap-tests.nix)
                (import ./overlays/fix-marktext-build.nix)
                (import ./overlays/fix-libkgapi-gcc15-ice.nix)
                (import ./overlays/fix-wechat-keytao-ime.nix)
                # sunshine/gearlever(dwarfs) are broken in unstable (boost 1.89 regression), use stable
                (_: _: { sunshine = (stablePkgsFor "x86_64-linux").sunshine; })
                (_: _: { gearlever = (stablePkgsFor "x86_64-linux").gearlever; })
              ];
            }

            # niri compositor module (replaces nixpkgs niri module)
            inputs.niri-flake.nixosModules.niri

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
                  inputs.keytao-installer.homeManagerModules.default
                  inputs.rime-keytao.homeManagerModules.default
                  inputs.catppuccin.homeModules.catppuccin
                  inputs.noctalia.homeModules.default
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
                  inputs.catppuccin.homeModules.catppuccin
                ];
              };
            }
          ];
        };
      };
    };
}
