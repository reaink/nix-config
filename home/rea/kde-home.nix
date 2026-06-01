{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  keytaoPackage = inputs.keytao-app.packages.${system}.default;
  kdeVirtualKeyboardDesktop = "keytao-wayland-launcher.desktop";
in
{
  home.packages = with pkgs; [
    keytaoPackage
    kdePackages.kconfig
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.kio-extras
    kdePackages.ark
    kdePackages.gwenview
    kdePackages.okular
    haruna
    kdePackages.kate
    kdePackages.kcalc
    kdePackages.spectacle
    kdePackages.plasma-systemmonitor
    kdePackages.kwalletmanager
    pavucontrol
  ];

  home.sessionVariables = {
    XMODIFIERS = "@im=keytao";
  };

  systemd.user.sessionVariables = {
    XMODIFIERS = "@im=keytao";
  };

  xdg.configFile."autostart/keytao-ime.desktop".text = ''
    [Desktop Entry]
    Name=KeyTao IME Daemon
    Exec=${keytaoPackage}/bin/keytao-ime --backend=xim,ibus
    Icon=keytao-app
    Type=Application
    NoDisplay=true
    X-KDE-autostart-phase=1
  '';

  xdg.dataFile."applications/${kdeVirtualKeyboardDesktop}".text = ''
    [Desktop Entry]
    Name=KeyTao Input Method (Wayland)
    Name[zh_CN]=键道输入法 (Wayland)
    Name[zh_TW]=鍵道輸入法 (Wayland)
    GenericName=Input Method
    GenericName[zh_CN]=输入法
    GenericName[zh_TW]=輸入法
    Comment=KeyTao Chinese Input Method Engine (KDE Virtual Keyboard)
    Comment[zh_CN]=键道中文输入法引擎（KDE 虚拟键盘）
    Comment[zh_TW]=鍵道中文輸入法引擎（KDE 虛擬鍵盤）
    Exec=${keytaoPackage}/bin/keytao-ime
    Icon=input-keyboard
    Terminal=false
    Type=Application
    Categories=System;Utility;
    StartupNotify=false
    NoDisplay=true
    OnlyShowIn=KDE;
    X-KDE-StartupNotify=false
    X-KDE-Wayland-VirtualKeyboard=true
  '';

  home.activation.configureKeytaoKdeVirtualKeyboard =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rm -f "$HOME/.config/plasma-workspace/env/keytao.sh"

      if [ -x "${pkgs.kdePackages.kconfig}/bin/kreadconfig6" ]; then
        current_im="$("${pkgs.kdePackages.kconfig}/bin/kreadconfig6" \
          --file "$HOME/.config/kwinrc" \
          --group Wayland \
          --key InputMethod || true)"

        if [ "$current_im" != "${kdeVirtualKeyboardDesktop}" ]; then
          "${pkgs.kdePackages.kconfig}/bin/kwriteconfig6" \
            --file "$HOME/.config/kwinrc" \
            --group Wayland \
            --key InputMethod \
            "${kdeVirtualKeyboardDesktop}"
        fi

        current_exclude="$("${pkgs.kdePackages.kconfig}/bin/kreadconfig6" \
          --file "$HOME/.config/ksmserverrc" \
          --group General \
          --key excludeApps || true)"

        # Exclude both keytao-app and keytao-ime from session restore
        new_exclude="$current_exclude"
        for app in keytao-app keytao-ime; do
          if [[ ! ",$new_exclude," == *",$app,"* ]]; then
            if [ -z "$new_exclude" ]; then
              new_exclude="$app"
            else
              new_exclude="$new_exclude,$app"
            fi
          fi
        done
        if [ "$new_exclude" != "$current_exclude" ]; then
          "${pkgs.kdePackages.kconfig}/bin/kwriteconfig6" \
            --file "$HOME/.config/ksmserverrc" \
            --group General \
            --key excludeApps \
            "$new_exclude"
        fi
      fi
    '';

  qt = {
    enable = true;
    platformTheme.name = lib.mkForce "kde";
  };

  gtk.cursorTheme = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = lib.mkForce {
      "inode/directory" = "org.kde.dolphin.desktop";
      "x-directory/normal" = "org.kde.dolphin.desktop";

      "image/jpeg" = "org.kde.gwenview.desktop";
      "image/png" = "org.kde.gwenview.desktop";
      "image/gif" = "org.kde.gwenview.desktop";
      "image/webp" = "org.kde.gwenview.desktop";
      "image/avif" = "org.kde.gwenview.desktop";
      "image/bmp" = "org.kde.gwenview.desktop";
      "image/tiff" = "org.kde.gwenview.desktop";
      "image/svg+xml" = "org.kde.gwenview.desktop";

      "video/mp4" = "org.kde.haruna.desktop";
      "video/mkv" = "org.kde.haruna.desktop";
      "video/x-matroska" = "org.kde.haruna.desktop";
      "video/webm" = "org.kde.haruna.desktop";
      "video/avi" = "org.kde.haruna.desktop";
      "video/x-msvideo" = "org.kde.haruna.desktop";
      "video/quicktime" = "org.kde.haruna.desktop";
      "video/x-flv" = "org.kde.haruna.desktop";
      "video/mpeg" = "org.kde.haruna.desktop";

      "audio/mpeg" = "org.kde.haruna.desktop";
      "audio/mp3" = "org.kde.haruna.desktop";
      "audio/flac" = "org.kde.haruna.desktop";
      "audio/ogg" = "org.kde.haruna.desktop";
      "audio/wav" = "org.kde.haruna.desktop";
      "audio/aac" = "org.kde.haruna.desktop";
      "audio/x-m4a" = "org.kde.haruna.desktop";

      "application/pdf" = "org.kde.okular.desktop";

      "application/msword" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
        "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.text" = "onlyoffice-desktopeditors.desktop";

      "application/vnd.ms-excel" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" =
        "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.spreadsheet" = "onlyoffice-desktopeditors.desktop";

      "application/vnd.ms-powerpoint" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" =
        "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.presentation" = "onlyoffice-desktopeditors.desktop";

      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/ftp" = "google-chrome.desktop";
    };
  };

  xdg.configFile."mimeapps.list".force = lib.mkForce true;

  xdg.desktopEntries.wechat.settings.StartupWMClass = lib.mkForce "wechat";

  home.activation.killStaleDolphin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.procps}/bin/pkill -x dolphin 2>/dev/null || true
  '';
}
