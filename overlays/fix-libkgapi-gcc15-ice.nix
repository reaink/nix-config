self: super: {
  kdePackages = super.kdePackages.overrideScope (
    _: kdeSuper: {
      libkgapi = kdeSuper.libkgapi.overrideAttrs (_: {
        cmakeBuildType = "RelWithDebInfo";
      });
    }
  );
}
