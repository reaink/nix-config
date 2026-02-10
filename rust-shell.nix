# Use this for Rust project development
# Run: nix-shell rust-shell.nix in your project directory
{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Rust toolchain from nixpkgs (more stable than rustup on NixOS)
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer

    # Build dependencies
    pkg-config
    openssl
    openssl_3
    zlib

    # Development tools
    cargo-watch
    cargo-edit
  ];

  # Environment variables for dynamic linking
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
    pkgs.openssl
    pkgs.openssl_3
    pkgs.stdenv.cc.cc.lib
    pkgs.zlib
  ];

  OPENSSL_DIR = "${pkgs.openssl.dev}";
  OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
  PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";

  shellHook = ''
    echo "Rust development environment loaded"
    echo "rustc version: $(rustc --version)"
    echo "cargo version: $(cargo --version)"
    echo ""
    echo "To fix existing binaries, run:"
    echo "  patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) --set-rpath ${
      pkgs.lib.makeLibraryPath [
        pkgs.openssl
        pkgs.openssl_3
        pkgs.stdenv.cc.cc.lib
      ]
    } ./your-binary"
  '';
}
