{
  description = "Rea NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    r3playx.url = "github:EndCredits/R3PLAYX-nix/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, ...}: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
	specialArgs = inputs;
        modules = [
          ./configuration.nix

	  home-manager.nixosModules.home-manager
	  {
            home-manager.useGlobalPkgs = true;
	    home-manager.useUserPackages = true;

	    home-manager.extraSpecialArgs = inputs;
	    home-manager.users.rea = {
	      imports = [ ./home.nix ];
	    };
	  }
        ];
      };
    };
  };
}
