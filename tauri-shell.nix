# Tauri 2.0 development shell (desktop + Android)
# Usage: nix-shell ~/nix-config/tauri-shell.nix
#
# After entering the shell:
#   npm install && npm run tauri dev          # desktop
#   npm run tauri android init               # first-time Android setup
#   npm run tauri android dev                # Android (emulator/device)
{
  pkgs ? import <nixpkgs> {
    config.allowUnfree = true;
    config.android_sdk.accept_license = true;
  },
}:

let
  androidSdk = (pkgs.androidenv.composeAndroidPackages {
    cmdLineToolsVersion = "13.0";
    platformToolsVersion = "35.0.2";
    buildToolsVersions = [ "34.0.0" ];
    platformVersions = [ "34" ];
    includeNDK = true;
    ndkVersions = [ "27.0.12077973" ];
    includeEmulator = false;
    includeSources = false;
  }).androidsdk;

  androidHome = "${androidSdk}/libexec/android-sdk";
  ndkHome = "${androidHome}/ndk/27.0.12077973";
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # Tauri CLI
    cargo-tauri

    # Android SDK (declarative, no manual download needed)
    androidSdk
    jdk17

    # Build tools
    pkg-config
    openssl
    openssl.dev

    # Tauri Linux (GTK/WebKit) dependencies
    glib
    glib.dev
    gtk3
    gtk3.dev
    webkitgtk_4_1
    webkitgtk_4_1.dev
    librsvg
    librsvg.dev
    libayatana-appindicator
    xdotool
    pango
    pango.dev
    cairo
    cairo.dev
    atk
    atk.dev
    dbus
    dbus.dev
    gdk-pixbuf
    libsoup_3
    libsoup_3.dev
  ];

  PKG_CONFIG_PATH = pkgs.lib.makeSearchPath "lib/pkgconfig" [
    pkgs.glib.dev
    pkgs.gtk3.dev
    pkgs.webkitgtk_4_1.dev
    pkgs.pango.dev
    pkgs.cairo.dev
    pkgs.atk.dev
    pkgs.libsoup_3.dev
    pkgs.openssl.dev
    pkgs.dbus.dev
    pkgs.librsvg.dev
  ];

  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
    pkgs.openssl
    pkgs.stdenv.cc.cc.lib
    pkgs.zlib
    pkgs.glib
    pkgs.gtk3
    pkgs.webkitgtk_4_1
  ];

  OPENSSL_DIR = "${pkgs.openssl.dev}";
  OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";

  JAVA_HOME = "${pkgs.jdk17}";
  ANDROID_HOME = androidHome;
  NDK_HOME = ndkHome;

  shellHook = ''
    echo "Tauri 2.0 development environment"
    echo "  cargo tauri: $(cargo tauri --version 2>/dev/null || echo 'not found')"
    echo "  JAVA_HOME:   $JAVA_HOME"
    echo "  ANDROID_HOME: $ANDROID_HOME"
    echo "  NDK_HOME:    $NDK_HOME"
  '';
}
