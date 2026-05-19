self: super: {
  # OnlyOffice resolves /proc/self/exe to its real nix store path and looks for fonts
  # at ../fonts/ relative to its binary — meaning the inner stdenv.mkDerivation output.
  # Injecting fonts into targetPkgs (FHS /usr/share/fonts or /usr/share/desktopeditors/fonts)
  # has no effect. We must add fonts into the inner derivation itself via postInstall.
  onlyoffice-desktopeditors = super.onlyoffice-desktopeditors.override {
    stdenv = super.stdenv // {
      mkDerivation = args:
        let
          drv = super.stdenv.mkDerivation args;
          cjkFontPkgs = with super; [
            noto-fonts-cjk-sans
            noto-fonts-cjk-serif
            wqy_zenhei
            source-han-sans
            source-han-serif
            lxgw-wenkai
          ];
        in
          if (args.pname or "") == "onlyoffice-desktopeditors" then
            drv.overrideAttrs (_: {
              postInstall = super.lib.concatMapStringsSep "\n" (pkg: ''
                find ${pkg}/share/fonts \( -name "*.ttf" -o -name "*.otf" -o -name "*.ttc" \) \
                  -exec cp {} "$out/share/desktopeditors/fonts/" \;
              '') cjkFontPkgs;
            })
          else drv;
    };
  };
}
