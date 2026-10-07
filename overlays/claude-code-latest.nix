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

  version = "2.1.292"; # Updated by update-hashes.sh
  baseUrl = "https://downloads.claude.ai/claude-code-releases";

  # node-style platform key, matching nixpkgs (e.g. darwin-arm64, linux-x64).
  platformKey = "${super.stdenv.hostPlatform.node.platform}-${super.stdenv.hostPlatform.node.arch}";

  # Hex sha256 of each claude.zst, taken from the upstream manifest.zst.json.
  # Both hosts share home/rea/common.nix, so both platforms must be present:
  # this mac is darwin-arm64, the nixos host is linux-x64.
  checksums = {
    "darwin-arm64" = "dfabaa49a309abe3229719ecfaf41d557c831168b2b642cf2c24e7ab0fc40291"; # Updated by update-hashes.sh (darwin-arm64)
    "linux-x64" = "28509427a53a5c15bd94d022d39013cc4b867a8e6305497f48162dcf91576326"; # Updated by update-hashes.sh (linux-x64)
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
