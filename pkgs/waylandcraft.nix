{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  fetchurl,
  pkg-config,
  jdk25,
  libxkbcommon,
  libdrm,
  mesa,
  wayland,
  udev,
  libinput,
  unzip,
  zip,
}:

let
  version = "1.0.0";

  # Step 1: fetch the source (need to fill hash after first failed build)
  src = fetchFromGitHub {
    owner = "EVV1E";
    repo = "waylandcraft";
    rev = "61c4929814671693ff3ea1ba83a0f16bf13a3dc2";
    hash = "sha256-IAqJgccw0wgmr/FdFwjGQSl+u7PiX48wANDAgIAc5jw=";
  };

  # Step 2: compile the Rust native library against the local glibc
  nativeLib = rustPlatform.buildRustPackage {
    pname = "waylandcraft-native";
    inherit version;
    src = "${src}/native";

    cargoHash = "sha256-R1ZUE1w5q2DDqeJtcdY/SArIX8As6KEZ/JKrWbXFxE8=";

    JAVA_HOME = jdk25;

    nativeBuildInputs = [ pkg-config ];
    buildInputs = [
      libxkbcommon
      libdrm
      mesa # provides gbm
      wayland
      udev # provides libudev for smithay
      libinput
    ];
  };

  # Step 3: fetch the release jar (has the correct Java bytecode, wrong glibc .so)
  releaseJar = fetchurl {
    url = "https://github.com/EVV1E/waylandcraft/releases/download/v${version}/waylandcraft-${version}.jar";
    # SHA256 from GitHub release API
    sha256 = "d23ae2fbbebc7ef8f29eec6795c088d14aa5d07232f44e083940c336328ec653";
  };

in
stdenv.mkDerivation {
  pname = "waylandcraft";
  inherit version;

  dontUnpack = true;
  nativeBuildInputs = [
    unzip
    zip
  ];

  buildPhase = ''
    cp ${releaseJar} waylandcraft.jar
    chmod +w waylandcraft.jar
    # replace the bundled .so (compiled against glibc 2.43) with our local build
    zip -j waylandcraft.jar ${nativeLib}/lib/libwaylandcraft.so
  '';

  installPhase = ''
    install -Dm644 waylandcraft.jar $out/share/mods/waylandcraft-${version}.jar
  '';

  meta = {
    description = "WaylandCraft Fabric mod - Wayland compositor inside Minecraft";
    homepage = "https://github.com/EVV1E/waylandcraft";
    license = lib.licenses.gpl3;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
