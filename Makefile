.PHONY: help nixos darwin update clean-nixos clean-darwin check

help:
	@echo "Available commands:"
	@echo "  make nixos         - Build and switch NixOS configuration"
	@echo "  make darwin        - Build and switch macOS configuration"
	@echo "  make update        - Update all flake inputs"
	@echo "  make check         - Check flake configuration"
	@echo "  make clean-nixos   - Garbage collect on NixOS"
	@echo "  make clean-darwin  - Garbage collect on macOS"

nixos:
	sudo nixos-rebuild switch --flake .#nixos

darwin:
	darwin-rebuild switch --flake .#mac

update:
	nix flake update

check:
	nix flake check

clean-nixos:
	sudo nix-collect-garbage -d
	sudo nix-store --optimize

clean-darwin:
	nix-collect-garbage -d
	nix-store --optimize
