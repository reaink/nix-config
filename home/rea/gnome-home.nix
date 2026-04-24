{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    gnomeExtensions.appindicator # system tray icon support for non-native apps
    gnomeExtensions.gsconnect # KDE Connect protocol for GNOME Shell
  ];

  # Qt theme for GNOME
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };

  # Cursor theme
  gtk.cursorTheme = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      cursor-theme = "Adwaita";
      cursor-size = 24;
      gtk-theme = "Arc-Dark";
      icon-theme = "Papirus-Dark";
      enable-animations = true;
    };

    "org/gnome/shell" = {
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "gsconnect@andyholmes.github.io"
      ];
    };

    "org/gnome/desktop/wm/preferences" = {
      num-workspaces = 4;
      focus-mode = "click";
    };

    "org/gnome/mutter" = {
      dynamic-workspaces = false;
      workspaces-only-on-primary = true;
    };

    "org/gnome/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 600;
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
      power-button-action = "interactive";
    };

    "org/gnome/desktop/wm/keybindings" = {
      switch-to-workspace-1 = [ "<Super>1" ];
      switch-to-workspace-2 = [ "<Super>2" ];
      switch-to-workspace-3 = [ "<Super>3" ];
      switch-to-workspace-4 = [ "<Super>4" ];
      move-to-workspace-1 = [ "<Super><Shift>1" ];
      move-to-workspace-2 = [ "<Super><Shift>2" ];
      move-to-workspace-3 = [ "<Super><Shift>3" ];
      move-to-workspace-4 = [ "<Super><Shift>4" ];
      close = [ "<Super>q" ];
      maximize = [ "<Super>Up" ];
      minimize = [ "<Super>m" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Launch Terminal";
      command = "kgx";
      binding = "<Super>Return";
    };
  };
}
