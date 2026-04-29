self: super: {
  # Claude Code Latest - Always tracks the latest version from npm registry
  #
  # Uses buildNpmPackage directly (not overrideAttrs) to avoid lib.extendMkDerivation
  # timing issues where npmDeps can't be updated via overrideAttrs.
  #
  # Only version + src hash need updating here. Everything else (npmDepsHash,
  # postPatch with vendored package-lock.json, postInstall, meta, etc.)
  # is inherited from nixpkgs and maintained by nixpkgs maintainers.
  #
  # To update to the newest release, run:
  #   sh ~/nix-config/update-hashes.sh claude-code

  claude-code = super.buildNpmPackage (finalAttrs: {
    pname = "claude-code";
    # Pinned to 2.1.112 — last version with cli.js.
    # v2.1.113+ switched to native platform binaries (cli-wrapper.cjs) which
    # requires nixpkgs to update its postPatch. Unpin once nixpkgs handles it.
    version = "2.1.112"; # Updated by update-hashes.sh

    src = super.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${finalAttrs.version}.tgz";
      hash = "sha256-SJJqU7XHbu9IRGPMJNUg6oaMZiQUKqJhI2wm7BnR1gs="; # Updated by update-hashes.sh (src)
    };

    inherit (super.claude-code)
      npmDepsHash
      strictDeps
      postPatch
      postInstall
      meta
      ;

    dontNpmBuild = true;

    # nativeInstallCheckInputs is not exposed on the derivation attrs
    doInstallCheck = false;

    env.AUTHORIZED = "1";
  });
}
