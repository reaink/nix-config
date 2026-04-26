self: super: {
  openldap = super.openldap.overrideAttrs (_: {
    doCheck = false;
  });
}
