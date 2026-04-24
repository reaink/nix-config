{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  programs.kdeconnect.enable = true;

  programs.dconf.enable = true;

  # SDDM — GDM crashes Hyprland on first launch
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  services.displayManager.defaultSession = "hyprland-uwsm";

  services.displayManager.autoLogin = {
    enable = true;
    user = "rea";
  };

  # XDG portal for Hyprland (screen sharing, file pickers)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    config.common.default = "*";
  };

  # NVIDIA-specific env vars needed at session level
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };
}
