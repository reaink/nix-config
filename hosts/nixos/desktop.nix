{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # niri Wayland compositor (module provided by niri-flake)
  # Using niri-unstable (niri git, Apr 2026) which includes the fix for issue #454:
  # "GTK popup grab + IME grab conflict causes Nautilus rename popover to not appear"
  # Fix was merged 2025-12-20 (commit d9ceff7), not yet in stable (v25.08), included in v26.04+.
  programs.niri.enable = true;
  programs.niri.package = inputs.niri-flake.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;

  # XDG Desktop Portal — required for file-chooser, screen capture, etc.
  # xdg-desktop-portal-gnome handles the GTK file picker used by browsers.
  # xdg-desktop-portal-gnome: provides Settings, Secret, Screenshot, ScreenCast (requires gnome-shell for FileChooser — NOT available without gnome-shell)
  # xdg-desktop-portal-gtk: provides FileChooser (GTK native picker, works without gnome-shell)
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
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
    };
  };

  programs.kdeconnect.enable = true;

  programs.dconf.enable = true;

  # gvfs: virtual filesystem daemon required by Nautilus for file operations (rename, trash, etc.)
  services.gvfs.enable = true;

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

  # NVIDIA VRAM leak fix: niri triggers rapid buffer pool growth on resizes.
  # Also applied to chrome GPU process to prevent tab-switch flicker from buffer pool churn.
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-niri-vram.json".text = builtins.toJSON {
    rules = [
      {
        pattern = {
          feature = "procname";
          matches = "niri";
        };
        profile = "Limit Free Buffer Pool On Wayland Compositors";
      }
      {
        pattern = {
          feature = "procname";
          matches = "chrome";
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
