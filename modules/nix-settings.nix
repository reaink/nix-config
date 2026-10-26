{
  config,
  pkgs,
  lib,
  options,
  ...
}:

let
  isDarwin = options ? launchd;
  isLinux = options ? systemd;
in
lib.mkMerge [
  {
    # Enable flakes and new nix command
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    nix.settings.substituters = lib.mkForce [
      # MirrorZ routes to a suitable China Education and Research Network mirror.
      "https://mirrors.cernet.edu.cn/nix-channels/store?priority=10"
      "https://mirrors.ustc.edu.cn/nix-channels/store?priority=20"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=30"
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
      if pkgs.stdenv.hostPlatform.isDarwin then
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
  (lib.optionalAttrs (isLinux && options.nix ? daemonCPUSchedPolicy) {
    # Lower nix-daemon scheduling priority for unprivileged builds
    nix.daemonCPUSchedPolicy = "idle";
    nix.daemonIOSchedClass = "idle";
  })
  (lib.optionalAttrs (isDarwin && options.nix ? daemonProcessType) {
    # Lower nix-daemon resource priority on launchd-based systems.
    nix.daemonProcessType = "Background";
  })
]
