self: super: {
  # Claude Code Latest - Always tracks the latest version from npm registry
  #
  # Overrides the nixpkgs claude-code package with the latest version.
  # To update to the newest release, run:
  #   sh ~/nix-config/update-claude-code-hash.sh

  claude-code = super.claude-code.overrideAttrs (oldAttrs: rec {
    version = "2.1.85"; # Updated by update-claude-code-hash.sh

    src = super.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha512-3/q3xTpk9EnBfQ/XsHGkOZniOgQx4sqD95CDKw1mvN1Qw5+9IZTp6ILdds02d7vOM6YuLL0G0zhqsMSAFVse4w=="; # Updated by update-claude-code-hash.sh
    };

    npmDepsHash = "sha256-sha256-RBNvo1WzZ4oRRq0W9+hknpT7T8If536DEMBg9hyq/4o="; # Updated by update-claude-code-hash.sh
  });
}
