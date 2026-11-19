{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  autoPatchelfHook,
  wrapGAppsHook3,
  webkitgtk_4_1,
  gtk3,
  libsoup_3,
  glib,
  gdk-pixbuf,
  fontconfig,
  wayland,
  gst_all_1,
}:

let
  version = "0.1.4525";
  assets = {
    aarch64-darwin = {
      name = "magpie-darwin-arm64.zip";
      hash = "sha256-tY3qIDoESwdkCr+KLZOJGbJPjm9nTcn6qsQB/n47eVs=";
    };
    x86_64-linux = {
      name = "magpie-linux-amd64";
      hash = "sha256-j1tkZXvo8s5M7o82anO85l5sj8+5d297yJksDvCEgAU=";
    };
  };
  asset =
    assets.${stdenvNoCC.hostPlatform.system}
      or (throw "magpie: unsupported platform ${stdenvNoCC.hostPlatform.system}");
  inherit (stdenvNoCC.hostPlatform) isDarwin isLinux;
in
stdenvNoCC.mkDerivation {
  pname = "magpie";
  inherit version;

  src = fetchurl {
    url = "https://github.com/yetone/magpie/releases/download/v${version}/${asset.name}";
    inherit (asset) hash;
  };

  sourceRoot = lib.optionalString isDarwin ".";
  dontUnpack = isLinux;
  dontFixup = isDarwin;

  nativeBuildInputs =
    lib.optionals isDarwin [ unzip ]
    ++ lib.optionals isLinux [
      autoPatchelfHook
      wrapGAppsHook3
    ];

  buildInputs = lib.optionals isLinux [
    webkitgtk_4_1
    gtk3
    libsoup_3
    glib
    gdk-pixbuf
    fontconfig
    wayland
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
  ];

  installPhase = ''
    runHook preInstall

  ''
  + (
    if isDarwin then
      ''
        mkdir -p "$out/Applications" "$out/bin"
        cp -R magpie.app "$out/Applications/"
        ln -s "$out/Applications/magpie.app/Contents/MacOS/magpie" "$out/bin/magpie"
      ''
    else
      ''
        install -Dm755 "$src" "$out/bin/magpie"
      ''
  )
  + ''

    runHook postInstall
  '';

  meta = {
    description = "Every agent's model in one place, from the menu bar";
    homepage = "https://usemagpie.ai";
    license = lib.licenses.mit;
    mainProgram = "magpie";
    platforms = builtins.attrNames assets;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
