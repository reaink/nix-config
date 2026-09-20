{
  description = "Rea's unified NixOS & nix-darwin configuration";

  nixConfig = {
    extra-substituters = [
      "https://noctalia.cachix.org"
      "https://niri.cachix.org"
      "https://nixarchy.cachix.org"
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "nixarchy.cachix.org-1:05JOuIlsQOWY2/5DQMq7JEA1hwlhgvmMWowMfka8mMM="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIITemDosxrE9/Kb+PfYvE="
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
      url = "github:nix-community/home-manager/master";
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

    # TODO: revert to github:xkinput/keytao-app once the stale pnpmDeps.hash fix is merged upstream
    keytao-app = {
      url = "github:reaink/keytao-app/fix/pnpm-deps-hash";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Catppuccin theme
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
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

    # Omarchy desktop vendored for NixOS (Hyprland + QuickShell)
    nixarchy = {
      url = "github:olafkfreund/nixarchy/v4.0.4-1";
      inputs.nixpkgs.follows = "nixpkgs";
      # nixarchy imports sops-nix's module itself; following our input keeps a
      # single module source (two different sops-nix revisions = duplicate
      # option declarations and a failed evaluation).
      inputs.sops-nix.follows = "sops-nix";
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
                (import ./overlays/claude-code-latest.nix)
                (import ./overlays/fix-openldap-tests.nix)
                (import ./overlays/fix-libkgapi-gcc15-ice.nix)
                (import ./overlays/onlyoffice-cjk-fonts.nix)
                # sunshine/gearlever(dwarfs) are broken in unstable (boost 1.89 regression), use stable
                (_: _: { sunshine = (stablePkgsFor "x86_64-linux").sunshine; })
                (_: _: { gearlever = (stablePkgsFor "x86_64-linux").gearlever; })
              ];
            }

            # niri compositor module (replaces nixpkgs niri module)
            inputs.niri-flake.nixosModules.niri
            inputs.keytao-app.nixosModules.default

            # Nixarchy desktop (Omarchy vendored for NixOS)
            inputs.nixarchy.nixosModules.nixarchy

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
                  inputs.rime-keytao.homeManagerModules.default
                  inputs.catppuccin.homeModules.catppuccin
                  inputs.noctalia.homeModules.default
                  inputs.nixarchy.homeManagerModules.nixarchy
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
                (import ./overlays/claude-code-latest.nix)
                (import ./overlays/vercel-cli.nix)
                (import ./overlays/zennotes-desktop-darwin-app.nix)
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
