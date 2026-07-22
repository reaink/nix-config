self: super: {
  vercel = super.buildNpmPackage rec {
    pname = "vercel";
    version = "54.20.1";

    src = ../pkgs/vercel-cli;
    npmDepsHash = "sha256-iQ4B0hptequVwwmI438frTKGPY2TG21C4P3QT9kqHLw=";

    nativeBuildInputs = [ super.makeWrapper ];

    dontNpmBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/vercel" "$out/bin"
      cp -R package.json package-lock.json node_modules "$out/lib/vercel"
      makeWrapper "${super.nodejs}/bin/node" "$out/bin/vercel" \
        --add-flags "$out/lib/vercel/node_modules/vercel/dist/vc.js"
      makeWrapper "${super.nodejs}/bin/node" "$out/bin/vc" \
        --add-flags "$out/lib/vercel/node_modules/vercel/dist/vc.js"
      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      "$out/bin/vercel" --version | grep -q "${version}"
      "$out/bin/vc" --version | grep -q "${version}"
    '';

    meta = with super.lib; {
      description = "Command-line interface for Vercel";
      homepage = "https://vercel.com";
      license = licenses.asl20;
      mainProgram = "vercel";
      platforms = platforms.unix;
    };
  };
}
