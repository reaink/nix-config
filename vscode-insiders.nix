{
  pkgs,
  lib,
  ...
}:
let
  # Auto-detect OS and architecture
  platformMap = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
    "x86_64-darwin" = "darwin";
    "aarch64-darwin" = "darwin-arm64";
  };
  
  platform = platformMap.${pkgs.stdenv.hostPlatform.system} or (throw "Unsupported platform: ${pkgs.stdenv.hostPlatform.system}");
  
  # Read sha256 from external file
  vscodeInsidersSha256 = lib.strings.removeSuffix "\n" (
    builtins.readFile ./vscode-insiders-sha256.nix
  );
in
(pkgs.vscode.override { isInsiders = true; }).overrideAttrs (oldAttrs: rec {
  src = builtins.fetchTarball {
    url = "https://code.visualstudio.com/sha/download?build=insider&os=${platform}";
    sha256 = vscodeInsidersSha256;
  };
  version = "latest";
  buildInputs = oldAttrs.buildInputs ++ [
    pkgs.krb5
    pkgs.libsoup_3
    pkgs.webkitgtk_4_1
  ];
})
