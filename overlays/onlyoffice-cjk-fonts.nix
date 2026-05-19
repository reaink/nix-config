self: super: {
  # OnlyOffice 9.x only scans its own desktopeditors/fonts/ dir, not /usr/share/fonts.
  # We replace noto-fonts-cjk-sans (a targetPkgs entry) with a derivation whose
  # outputs live under share/desktopeditors/fonts/, so bwrap maps them into
  # /usr/share/desktopeditors/fonts/ — exactly where OnlyOffice looks.
  onlyoffice-desktopeditors = super.onlyoffice-desktopeditors.override {
    noto-fonts-cjk-sans = super.runCommand "onlyoffice-desktopeditors-cjk-fonts" { } ''
      mkdir -p $out/share/desktopeditors/fonts
      for pkg in \
        ${super.noto-fonts-cjk-sans} \
        ${super.noto-fonts-cjk-serif} \
        ${super.wqy_zenhei} \
        ${super.source-han-sans} \
        ${super.source-han-serif} \
        ${super.lxgw-wenkai}; do
        find "$pkg/share/fonts" \( -name "*.ttf" -o -name "*.otf" -o -name "*.ttc" \) \
          -exec ln -sf {} $out/share/desktopeditors/fonts/ \;
      done
    '';
  };
}
