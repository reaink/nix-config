{
  config,
  pkgs,
  lib,
  ...
}:

{
  # niri Wayland compositor (module provided by niri-flake)
  programs.niri.enable = true;

  programs.kdeconnect.enable = true;

  programs.dconf.enable = true;

  # Unlock gnome-keyring via PAM on SDDM autologin so secrets component is available
  security.pam.services.sddm-autologin.enableGnomeKeyring = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  services.displayManager.defaultSession = "niri";

  services.displayManager.autoLogin = {
    enable = true;
    user = "rea";
  };

  # Required for Noctalia power profile and battery widgets
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # NVIDIA-specific env vars needed at session level
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };

  # NVIDIA VRAM leak fix: niri triggers rapid buffer pool growth on resizes
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-niri-vram.json".text = builtins.toJSON {
    rules = [
      {
        pattern = {
          feature = "procname";
          matches = "niri";
        };
        profile = "Limit Free Buffer Pool On Wayland Compositors";
      }
    ];
    profiles = [
      {
        name = "Limit Free Buffer Pool On Wayland Compositors";
        settings = [
          {
            key = "GLVidHeapReuseRatio";
            value = 0;
          }
        ];
      }
    ];
  };
}
