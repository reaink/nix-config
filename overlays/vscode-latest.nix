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
            hash = "sha256-bhbMscqsOU2ux4i2XShdMKgJPN8tuWVSxTzJ0CUvJNM="; # Update with: nix-prefetch-url https://update.code.visualstudio.com/latest/darwin-arm64/stable
          }
        else
          {
            platform = "linux-x64";
            hash = "sha256-fWrT06eKxFUcFGMfeNfgPIUoKrUFw86LG8BOAfr+iOo="; # Update with: nix-prefetch-url https://update.code.visualstudio.com/latest/linux-x64/stable
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

      postPatch =
        if super.stdenv.isLinux then
          super.lib.replaceStrings
            [
              ''
                rm resources/app/node_modules/@vscode/ripgrep/bin/rg
                ln -s ${super.ripgrep}/bin/rg resources/app/node_modules/@vscode/ripgrep/bin/rg
              ''
            ]
            [
              ''
                for rgPath in \
                  resources/app/node_modules/@vscode/ripgrep/bin/rg \
                  resources/app/node_modules/@vscode/ripgrep-universal/bin/linux-x64/rg
                do
                  if [ -e "$rgPath" ] || [ -d "$(dirname "$rgPath")" ]; then
                    rm -f "$rgPath"
                    ln -s ${super.ripgrep}/bin/rg "$rgPath"
                    break
                  fi
                done
              ''
            ]
            (oldAttrs.postPatch or "")
        else if super.stdenv.isDarwin then
          # The Microsoft "latest" zip ships ripgrep under node_modules.asar.unpacked,
          # but nixpkgs' base postPatch targets plain node_modules (and its exact path
          # shifts across releases: @vscode/ripgrep/bin/rg -> @vscode/ripgrep-universal/
          # bin/darwin-arm64/rg). Match only the version-stable fragment and inject the
          # .asar.unpacked segment so this keeps working across nixpkgs bumps.
          super.lib.replaceStrings
            [ "app/node_modules/@vscode/ripgrep" ]
            [ "app/node_modules.asar.unpacked/@vscode/ripgrep" ]
            (oldAttrs.postPatch or "")
        else
          oldAttrs.postPatch or "";

      autoPatchelfIgnoreMissingDeps = (oldAttrs.autoPatchelfIgnoreMissingDeps or [ ]) ++ [
        "libc.musl-x86_64.so.1"
      ];
    }
  );
}
