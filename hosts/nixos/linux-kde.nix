{
  pkgs,
  ...
}:

{
  services.desktopManager.plasma6.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  services.displayManager.defaultSession = "plasma";

  services.displayManager.autoLogin = {
    enable = true;
    user = "rea";
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
      xdg-desktop-portal-gtk
    ];
    config.common.default = [
      "kde"
      "gtk"
    ];
  };

  programs.kdeconnect.enable = true;
  programs.dconf.enable = true;

  services.gvfs.enable = true;

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    XMODIFIERS = "@im=fcitx";
  };
}
