self: super: {
  # Claude Code Latest - Always tracks the latest version from npm registry
  #
  # Overrides the nixpkgs claude-code package with the latest version.
  # To update to the newest release, run:
  #   sh ~/nix-config/update-claude-code-hash.sh

  claude-code = super.claude-code.overrideAttrs (oldAttrs: rec {
    version = "2.1.87"; # Updated by update-claude-code-hash.sh

    src = super.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha512-R40p85lv270MsOmuP0VrgZlsBnq6HIoW/aIrPwny6AfhPUmsChPNLkxv/F8Mf6g9iYpGNEfICt5CDw++tKZD0g=="; # Updated by update-claude-code-hash.sh
    };

    npmDepsHash = "sha256-sha256-RBNvo1WzZ4oRRq0W9+hknpT7T8If536DEMBg9hyq/4o="; # Updated by update-claude-code-hash.sh
  });
}
