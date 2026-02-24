self: super: {
  python3 = super.python3.override {
    packageOverrides = pyself: pysuper: {
      picosvg = pysuper.picosvg.overridePythonAttrs (_: {
        doCheck = false;
      });
    };
  };
  python313 = super.python313.override {
    packageOverrides = pyself: pysuper: {
      picosvg = pysuper.picosvg.overridePythonAttrs (_: {
        doCheck = false;
      });
    };
  };
}
