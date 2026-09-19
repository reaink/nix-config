self: super:

# nixpkgs' `zennotes-desktop` has a Linux-only install layout: a makeWrapper
# launcher in `$out/bin`, a `share/applications/*.desktop` entry and hicolor
# PNG icons. On Linux that is everything a launcher needs; on macOS it means
# the app never shows up in Launchpad or Spotlight, because those only index
# `.app` bundles under /Applications and ~/Applications.
#
# `desktopToDarwinBundle` is nixpkgs' own setup hook for exactly this case: at
# fixup time it reads the installed .desktop entry, composes the hicolor PNGs
# into a real multi-resolution `.icns`, and emits
# `$out/Applications/ZenNotes.app` whose `Contents/MacOS/ZenNotes` points at
# `$out/bin/zennotes-desktop`.
#
# home-manager's `targets.darwin.copyApps` (enabled by default since state
# version 25.11, see home/rea/darwin.nix) collects `/Applications` from every
# entry in `home.packages` and rsyncs it into
# `~/Applications/Home Manager Apps`, so the bundle lands where Launchpad and
# Spotlight look.
#
# The `postFixup` below replaces the hook's generic Info.plist (which hardcodes
# `org.nixos.<name>` and carries no version) with a proper one, and swaps in the
# Retina .icns that upstream already ships for its own macOS build.
#
# The whole overlay is a no-op off darwin: on Linux it returns `{}`, leaving
# the upstream derivation byte-for-byte identical.

super.lib.optionalAttrs super.stdenv.hostPlatform.isDarwin {
  zennotes-desktop = super.zennotes-desktop.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ super.desktopToDarwinBundle ];

    postFixup =
      let
        appName = "ZenNotes";
        # Matches `Icon=` in the package's desktop item, which is also the
        # basename desktopToDarwinBundle gives the generated .icns.
        iconName = "zennotes-desktop";
        infoPlist = super.writeText "zennotes-desktop-Info.plist" (
          super.lib.generators.toPlist { escape = true; } {
            CFBundleDevelopmentRegion = "English";
            CFBundleDisplayName = appName;
            CFBundleExecutable = appName;
            CFBundleIconFile = iconName;
            # Deliberately no CFBundleIconFiles: that key makes macOS 26 apply
            # its own squircle mask, and ZenNotes' artwork is already a padded
            # squircle. Upstream's own macOS build omits it too.
            CFBundleIdentifier = "org.zennotes.desktop";
            CFBundleInfoDictionaryVersion = "6.0";
            CFBundleName = appName;
            CFBundlePackageType = "APPL";
            CFBundleShortVersionString = old.version;
            CFBundleSignature = "????";
            CFBundleVersion = old.version;
            LSApplicationCategoryType = "public.app-category.productivity";
            NSHighResolutionCapable = true;
          }
        );
      in
      (old.postFixup or "")
      + ''
        appBundle="$out/Applications/${appName}.app"

        # Fail loudly rather than silently shipping a broken/absent bundle if a
        # nixpkgs bump changes the desktop entry name or drops the hook.
        [ -x "$appBundle/Contents/MacOS/${appName}" ] \
          || { echo "expected $appBundle/Contents/MacOS/${appName} to exist" >&2; exit 1; }
        [ -s "$appBundle/Contents/Resources/${iconName}.icns" ] \
          || { echo "expected a non-empty $appBundle/Contents/Resources/${iconName}.icns" >&2; exit 1; }

        install -Dm644 ${infoPlist} "$appBundle/Contents/Info.plist"
        printf 'APPL????' > "$appBundle/Contents/PkgInfo"

        # The tarball ships the icon electron-builder uses for the official
        # macOS build: same artwork as the hicolor PNGs, but with the @2x
        # variants (up to 1024px) that the hook cannot synthesise from them.
        upstreamIcns="$out/lib/node_modules/zennotes-monorepo/apps/desktop/build/icon.icns"
        if [ -s "$upstreamIcns" ]; then
          install -Dm644 "$upstreamIcns" "$appBundle/Contents/Resources/${iconName}.icns"
        fi
      '';
  });
}
