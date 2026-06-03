{
  config,
  pkgs,
  lib,
  options,
  ...
}:

lib.mkMerge [
  {
    # Enable flakes and new nix command
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Use Chinese mirrors for faster downloads
    nix.settings.substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://noctalia.cachix.org"
      "https://niri.cachix.org"
    ];

    nix.settings.trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
    ];

    nix.settings.trusted-users = [
      "root"
      "rea"
    ];

    # Auto-optimize store to save space (nix-darwin uses optimise.automatic)
    nix.optimise.automatic = true;

    # Automatic garbage collection
    nix.gc = {
      automatic = true;
      options = "--delete-older-than 1w";
    }
    // (
      if pkgs.stdenv.isDarwin then
        {
          interval = {
            Weekday = 0;
            Hour = 0;
            Minute = 0;
          }; # Weekly on Sunday at midnight (nix-darwin)
        }
      else
        {
          dates = "weekly"; # Weekly (NixOS)
        }
    );

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-39.8.10"
      ];
    };

    # Limit parallel jobs to prevent I/O saturation and system freeze
    # 32 concurrent idle-priority jobs still saturate a single NVMe and trigger
    # Linux dirty-page writeback throttling, which stalls the Wayland compositor.
    nix.settings.max-jobs = 6;

  }
  (lib.optionalAttrs (options.nix ? daemonCPUSchedPolicy) {
    # Lower nix-daemon scheduling priority for unprivileged builds
    nix.daemonCPUSchedPolicy = "idle";
    nix.daemonIOSchedClass = "idle";
  })
  (lib.optionalAttrs (options.nix ? daemonProcessType) {
    # Lower nix-daemon resource priority on launchd-based systems.
    nix.daemonProcessType = "Background";
  })
]
