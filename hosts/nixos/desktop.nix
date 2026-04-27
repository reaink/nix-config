{
  config,
  pkgs,
  lib,
  ...
}:

{
  # niri Wayland compositor (module provided by niri-flake)
  programs.niri.enable = true;

  # XDG Desktop Portal — required for file-chooser, screen capture, etc.
  # xdg-desktop-portal-gnome handles the GTK file picker used by browsers.
  # xdg-desktop-portal-gtk is the fallback for anything not handled by gnome portal.
  # Without explicit portal config niri falls back to no implementation → silent failure.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config.niri = {
      default = [
        "gnome"
        "gtk"
      ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gnome" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
    };
  };

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
