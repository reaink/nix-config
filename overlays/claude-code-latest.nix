self: super:
let
  # Claude Code Latest — always tracks the latest release from Anthropic.
  #
  # Since v2.1.113 claude-code ships as per-platform native binaries (no cli.js).
  # nixpkgs packages this by fetching the zstd-compressed `claude.zst` binary
  # from downloads.claude.ai (unzstd'd in installPhase) and verifying it against
  # the sha256 recorded in manifest.zst.json. This overlay is a minimal override:
  # it only bumps the version and the per-platform binary checksums, inheriting
  # installPhase, wrapper, meta, install-check, etc. from nixpkgs.
  #
  # To update to the newest release, run:
  #   sh ~/nix-config/update-hashes.sh claude-code

  version = "2.1.328"; # Updated by update-hashes.sh
  baseUrl = "https://downloads.claude.ai/claude-code-releases";

  # node-style platform key, matching nixpkgs (e.g. darwin-arm64, linux-x64).
  platformKey = "${super.stdenv.hostPlatform.node.platform}-${super.stdenv.hostPlatform.node.arch}";

  # Hex sha256 of each claude.zst, taken from the upstream manifest.zst.json.
  # Both hosts share home/rea/common.nix, so both platforms must be present:
  # this mac is darwin-arm64, the nixos host is linux-x64.
  checksums = {
    "darwin-arm64" = "5c1e357bada5a66373e0705cb0e1213d3e49d086de0dcc11892e3063bc9da5dc"; # Updated by update-hashes.sh (darwin-arm64)
    "linux-x64" = "10f24c9cfcbf3c586e6d281815dce9b561eb8acc6b8c0f26b8f0af5e56fa7605"; # Updated by update-hashes.sh (linux-x64)
  };
in
{
  claude-code = super.claude-code.overrideAttrs (oldAttrs: {
    inherit version;

    src = super.fetchurl {
      url = "${baseUrl}/${version}/${platformKey}/claude.zst";
      sha256 = checksums.${platformKey};
    };
  });
}
