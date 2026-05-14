{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
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
    kdePackages.filelight
    kdePackages.kwalletmanager
    pavucontrol
  ];

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

  xdg.desktopEntries.wechat.settings.StartupWMClass = lib.mkForce "wechat";

  home.activation.killStaleDolphin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.procps}/bin/pkill -x dolphin 2>/dev/null || true
  '';
}
