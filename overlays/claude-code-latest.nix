self: super:
let
  # Claude Code Latest — always tracks the latest release from Anthropic.
  #
  # Since v2.1.113 claude-code ships as per-platform native binaries (no cli.js).
  # nixpkgs packages this by fetching the raw `claude` binary from
  # downloads.claude.ai and verifying it against the sha256 checksum recorded in
  # its manifest.json. This overlay is a minimal override on top of that model:
  # it only bumps the version and the per-platform binary checksums, inheriting
  # installPhase, wrapper, meta, install-check, etc. from nixpkgs.
  #
  # To update to the newest release, run:
  #   sh ~/nix-config/update-hashes.sh claude-code

  version = "2.1.220"; # Updated by update-hashes.sh
  baseUrl = "https://downloads.claude.ai/claude-code-releases";

  # node-style platform key, matching nixpkgs (e.g. darwin-arm64, linux-x64).
  platformKey = "${super.stdenv.hostPlatform.node.platform}-${super.stdenv.hostPlatform.node.arch}";

  # Hex sha256 of each raw native binary, taken from the upstream manifest.json.
  # Both hosts share home/rea/common.nix, so both platforms must be present:
  # this mac is darwin-arm64, the nixos host is linux-x64.
  checksums = {
    "darwin-arm64" = "8addc857f3fe64d5a0368af9ee50321b50afb4a6918ba3ef018ab84f5dbbe081"; # Updated by update-hashes.sh (darwin-arm64)
    "linux-x64" = "674f61f20ff306f3100cf9200e4c36c4b70278b5bef2884549819b942a89c863"; # Updated by update-hashes.sh (linux-x64)
  };
in
{
  claude-code = super.claude-code.overrideAttrs (oldAttrs: {
    inherit version;

    src = super.fetchurl {
      url = "${baseUrl}/${version}/${platformKey}/claude";
      sha256 = checksums.${platformKey};
    };
  });
}
