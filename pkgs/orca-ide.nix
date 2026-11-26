{
  lib,
  stdenvNoCC,
  fetchurl,
  appimageTools,
  unzip,
}:

let
  pname = "orca-ide";
  version = "1.4.278"; # Updated by update-hashes.sh (orca-ide)
  assets = {
    x86_64-linux = {
      name = "orca-linux.AppImage";
      sha256 = "3e2d25bb9768398e54296b1b36134db3c96574a2d4831d50343d0b1e895d380d"; # Updated by update-hashes.sh (orca-ide x86_64-linux)
    };
    aarch64-darwin = {
      name = "Orca-${version}-arm64-mac.zip";
      sha256 = "d832885a97a7f58bf27917ca42404d0b98c835062f92d5502c94ab7278c7ba08"; # Updated by update-hashes.sh (orca-ide aarch64-darwin)
    };
  };
  asset = assets.${stdenvNoCC.hostPlatform.system};
  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/${asset.name}";
    inherit (asset) sha256;
  };
  meta = {
    description = "Desktop workspace for running coding agents in parallel";
    homepage = "https://github.com/stablyai/orca";
    license = lib.licenses.mit;
    mainProgram = pname;
    platforms = builtins.attrNames assets;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
in
if stdenvNoCC.hostPlatform.isDarwin then
  stdenvNoCC.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;
    nativeBuildInputs = [ unzip ];
    sourceRoot = ".";
    dontFixup = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications" "$out/bin"
      cp -R Orca.app "$out/Applications/"
      ln -s "$out/Applications/Orca.app/Contents/MacOS/Orca" "$out/bin/orca-ide"
      runHook postInstall
    '';
  }
else
  let
    appimageContents = appimageTools.extract { inherit pname version src; };
  in
  appimageTools.wrapType2 {
    inherit
      pname
      version
      src
      meta
      ;
    extraInstallCommands = ''
      install -Dm644 ${appimageContents}/orca-ide.desktop "$out/share/applications/orca-ide.desktop"
      substituteInPlace "$out/share/applications/orca-ide.desktop" \
        --replace-fail 'Exec=AppRun' 'Exec=orca-ide'
      cp -r ${appimageContents}/usr/share/icons "$out/share/"
    '';
  }
