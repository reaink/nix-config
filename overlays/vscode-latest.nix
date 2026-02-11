self: super: {
  # VSCode Latest - Always fetches the latest stable version from Microsoft
  # 
  # This overlay creates a custom vscode-latest package that uses the official
  # Microsoft download URL which always redirects to the newest stable release.
  #
  # To update the hash when a new version is released:
  #   nix-prefetch-url https://update.code.visualstudio.com/latest/linux-x64/stable
  # Then update the sha256 value below with the output.
  #
  # The hash will need to be updated whenever Microsoft releases a new version,
  # as the content at the URL changes but the URL stays the same.
  
  vscode-latest = super.vscode.overrideAttrs (oldAttrs: rec {
    version = "latest";
    
    src = super.fetchurl {
      name = "vscode-latest.tar.gz";
      url = "https://update.code.visualstudio.com/latest/linux-x64/stable";
      # Hash must be updated when VSCode releases a new version
      # Get current hash with: nix-prefetch-url <url>
      # Setting to lib.fakeSha256 will cause build to fail with correct hash
      sha256 = super.lib.fakeSha256;
    };
  });
}
