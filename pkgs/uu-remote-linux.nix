{
  lib,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  wayland-scanner,
  gtk3,
  glib,
  pipewire,
  libei,
  libx11,
  libxext,
  libxtst,
  libxfixes,
  wayland,
  libxkbcommon,
}:

rustPlatform.buildRustPackage rec {
  pname = "uu-remote-linux";
  version = "0.2.31";

  src = fetchFromGitHub {
    owner = "VallierDev";
    repo = "uu-remote-linux";
    rev = "v${version}";
    hash = "sha256-DI+hfFlwkVrg2HejusYny17nuzxn88bfFBRGI+hJ4gM=";
  };

  cargoHash = "sha256-X6bsqL53kkXYcgkcDStEvHmJAeupXeCC/DoVWxb4Fas=";
  buildFeatures = [ "wayland" "portal" "engine-plugins" ];
  doCheck = false;
  nativeBuildInputs = [ pkg-config wayland-scanner ];
  buildInputs = [
    gtk3
    glib
    pipewire
    libei
    libx11
    libxext
    libxtst
    libxfixes
    wayland
    libxkbcommon
  ];

  postInstall = ''
    install -Dm644 contrib/desktop/uu-remote-linux.desktop \
      "$out/share/applications/uu-remote-linux.desktop"
    install -Dm644 contrib/desktop/uu-remote-linux.svg \
      "$out/share/icons/hicolor/scalable/apps/uu-remote-linux.svg"
  '';

  meta = {
    description = "Unofficial UU Remote host for Linux";
    homepage = "https://github.com/VallierDev/uu-remote-linux";
    license = lib.licenses.gpl3Plus;
    mainProgram = "uuremote-server";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
