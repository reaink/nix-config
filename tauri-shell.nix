# Tauri 2.0 development shell (desktop + Android)
# Usage: nix-shell ~/nix-config/tauri-shell.nix
#
# After entering the shell:
#   npm install && npm run tauri dev          # desktop
#   npm run tauri android init               # first-time Android setup
#   npm run tauri android dev                # Android (emulator/device)
{
  pkgs ? import <nixpkgs> { },
}:

let
  androidHome = builtins.getEnv "HOME" + "/Android/Sdk";
  # NDK_HOME must point to a specific NDK version directory.
  # After running `npm run tauri android init`, Tauri installs the NDK via
  # Android Studio / sdkmanager. Then set NDK_HOME manually or update below.
  ndkVersion = "27.0.12077973";
  ndkHome = androidHome + "/ndk/" + ndkVersion;
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # Tauri CLI
    cargo-tauri

    # Rust (assumes rustup is installed globally via common.nix)
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

    # Android
    jdk17
    android-tools
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
    echo "  cargo tauri --version: $(cargo tauri --version 2>/dev/null || echo 'not found — run: cargo install tauri-cli')"
    echo "  JAVA_HOME:             $JAVA_HOME"
    echo "  ANDROID_HOME:          $ANDROID_HOME"
    echo "  NDK_HOME:              $NDK_HOME"
    echo ""
    if [ ! -d "$ANDROID_HOME" ]; then
      echo "  ⚠  ANDROID_HOME does not exist yet."
      echo "     Open Android Studio → SDK Manager and install SDK + NDK ${ndkVersion}"
    fi
    if [ ! -d "$NDK_HOME" ]; then
      echo "  ⚠  NDK ${ndkVersion} not found at $NDK_HOME"
      echo "     In Android Studio: SDK Manager → SDK Tools → NDK (Side by side)"
    fi
  '';
}
