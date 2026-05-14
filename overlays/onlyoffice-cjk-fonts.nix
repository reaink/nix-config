self: super: {
  # OnlyOffice discovers fonts by scanning /usr/share/fonts inside its bwrap FHS env.
  # The package.nix uses noto-fonts-cjk-sans as a named argument in targetPkgs,
  # so we replace it with a symlinkJoin of all needed CJK fonts via callPackage override.
  onlyoffice-desktopeditors = super.onlyoffice-desktopeditors.override {
    noto-fonts-cjk-sans = super.symlinkJoin {
      name = "onlyoffice-cjk-fonts";
      paths = with super; [
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        wqy_zenhei
        source-han-sans
        source-han-serif
        lxgw-wenkai
      ];
    };
  };
}
