{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    # macOS-specific configuration
    # Currently minimal - can be expanded with macOS-specific packages and settings

    # macOS-specific environment variables (if needed)
    home.sessionVariables = {
      # Example: DYLD_LIBRARY_PATH if needed
    };

    # macOS-specific packages (can be added as needed)
    home.packages = with pkgs; [
      wechat
      kitty
      vlc-bin
      # Docker via Colima (open-source Docker Desktop alternative)
      colima
      docker
      docker-compose
      docker-credential-helpers
    ];

    home.file.".docker/config.json".text = builtins.toJSON {
      auths = { };
      credsStore = "osxkeychain";
      currentContext = "colima";
    };

    # Auto-start Colima as a launchd user agent
    launchd.agents.colima = {
      enable = true;
      config = {
        ProgramArguments = [
          "${pkgs.colima}/bin/colima"
          "start"
          "--foreground"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/colima.log";
        StandardErrorPath = "/tmp/colima.error.log";
      };
    };

    # macOS-specific Zsh aliases (override common.nix aliases)
    programs.zsh.shellAliases = lib.mkForce {
      # Inherit common aliases
      python = "uv run python";
      python3 = "uv run python";
      ls = "eza --icons";
      ll = "eza -l --icons";
      la = "eza -la --icons";
      lt = "eza --tree --icons";
      cat = "bat";
      flake-update = "nix flake update";
      flake-check = "nix flake check";
      update-vscode = "sh ~/nix-config/update-vscode-hash.sh";

      # macOS-specific (no sudo)
      rebuild = "sudo darwin-rebuild switch --flake ~/nix-config\\#mac";
      test = "sudo darwin-rebuild check --flake ~/nix-config\\#mac";
      gc = "nix-collect-garbage";
      gcold = "nix-collect-garbage --delete-older-than 30d";
      gcall = "nix-collect-garbage -d";
      optimize = "nix-store --optimize";
      clean = "nix-collect-garbage -d && nix-store --optimize";
      list-gens = "nix-env --list-generations --profile /nix/var/nix/profiles/system";
    };
  };
}
