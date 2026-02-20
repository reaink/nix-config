self: super: {
  # VSCode Latest - Always fetches the latest stable version from Microsoft
  #
  # This overlay creates a custom vscode-latest package that uses the official
  # Microsoft download URL which always redirects to the newest stable release.
  #
  # Supports both Linux (x86_64) and macOS (Apple Silicon).
  #
  # To update the hash when a new version is released:
  #   Linux:  nix-prefetch-url https://update.code.visualstudio.com/latest/linux-x64/stable
  #   macOS:  nix-prefetch-url https://update.code.visualstudio.com/latest/darwin-arm64/stable
  # Then update the corresponding sha256 value below with the output.
  #
  # The hash will need to be updated whenever Microsoft releases a new version,
  # as the content at the URL changes but the URL stays the same.

  vscode-latest = super.vscode.overrideAttrs (
    oldAttrs:
    let
      # Platform-specific configurations
      platformConfig =
        if super.stdenv.isDarwin then
          {
            platform = "darwin-arm64";
            hash = "016cv2v8480rnv01kqb44z9p99rmjjbzl4im9nxjr17nhckhak3j"; # Update with: nix-prefetch-url https://update.code.visualstudio.com/latest/darwin-arm64/stable
          }
        else
          {
            platform = "linux-x64";
            hash = "19xipl93dn29rl5imkrlhy9scr4sbak2gvip39jhz9fxq01h25kh"; # Update with: nix-prefetch-url https://update.code.visualstudio.com/latest/linux-x64/stable
          };
    in
    rec {
      version = "latest";

      src = super.fetchurl {
        name = "vscode-latest-${platformConfig.platform}.${
          if super.stdenv.isDarwin then "zip" else "tar.gz"
        }";
        url = "https://update.code.visualstudio.com/latest/${platformConfig.platform}/stable";
        sha256 = platformConfig.hash;
      };
    }
  );
}
