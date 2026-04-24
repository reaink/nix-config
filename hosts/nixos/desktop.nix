{
  config,
  pkgs,
  lib,
  ...
}:

{
  # GNOME display manager
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "rea";
  };

  # GNOME desktop environment
  services.desktopManager.gnome.enable = true;

  programs.dconf.enable = true;

  # XDG desktop portal for GNOME (file pickers, screen sharing, etc.)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = "*";
  };

  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnome-extension-manager
  ];
}
