self: super: {
  # Fix marktext build failure: ced native module runs `node-gyp rebuild`
  # but node-gyp isn't on PATH in the nix sandbox. Adding it to
  # nativeBuildInputs ensures it's available before yarn tries to install it.
  marktext = super.marktext.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ super.node-gyp ];
  });
}
