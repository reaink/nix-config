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
      pokemon-colorscripts-mac
      coreutils
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
    programs.zsh.shellAliases = {
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

    programs.zsh.initContent = ''
      llama-start() {
        llama-server --port 11110 -ngl 99 -fa --models-dir ~/.llama-models "$@"
      }
      llama-stop() {
        pkill -f 'llama-server' && echo 'llama-server stopped'
      }
      llama-ls() {
        ls -lh ~/.llama-models/*.gguf 2>/dev/null || echo 'No models found in ~/.llama-models'
      }
      llama-download-models() {
        mkdir -p ~/.llama-models
        echo "==> Qwen3-Coder-30B-A3B Q4_K_M (coder, ~18.6GB)"
        hf download unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf --local-dir ~/.llama-models
        echo "==> Qwen3-8B Q8_0 (chat, ~8.7GB)"
        hf download Qwen/Qwen3-8B-GGUF Qwen3-8B-Q8_0.gguf --local-dir ~/.llama-models
        echo "Done. Models in ~/.llama-models"
      }
    '';
  };
}
