{
  lib,
  stdenvNoCC,
  fetchurl,
  glibc,
  patchelf,
}:

let
  version = "17.2.4";
  assets = {
    aarch64-darwin = {
      name = "omp-darwin-arm64";
      hash = "sha256-850lbGsuzn8uuFwk/Ef/vjmheW6m7qJgWtVk/OQsQI4=";
    };
    x86_64-linux = {
      name = "omp-linux-x64";
      hash = "sha256-pucIbzuAf2ilsItJWX9DSeXONzZWObevXpyP41mYmEA=";
    };
  };
  asset =
    assets.${stdenvNoCC.hostPlatform.system}
      or (throw "oh-my-pi: unsupported platform ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "oh-my-pi";
  inherit version;

  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/${asset.name}";
    inherit (asset) hash;
  };

  dontUnpack = true;
  dontStrip = true;

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ patchelf ];

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/bin/omp"

    runHook postInstall
  '';

  postFixup = lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
    patchelf \
      --set-interpreter "${glibc}/lib/ld-linux-x86-64.so.2" \
      --set-rpath "${glibc}/lib" \
      "$out/bin/omp"
  '';

  meta = {
    description = "AI coding agent with an integrated IDE tool harness";
    homepage = "https://omp.sh";
    license = lib.licenses.mit;
    mainProgram = "omp";
    platforms = builtins.attrNames assets;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
