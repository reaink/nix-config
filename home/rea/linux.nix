{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [ ./niri-home.nix ];

  config = lib.mkIf pkgs.stdenv.isLinux {
    # Linux-specific packages
    home.packages = with pkgs; [
      inputs.keytao-installer.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.keytao-installer.packages.${pkgs.stdenv.hostPlatform.system}.keytao-linux-ime
      # Tauri/GTK development libraries
      glib
      glib.dev
      gtk3
      gtk3.dev
      webkitgtk_4_1
      webkitgtk_4_1.dev
      pango
      pango.dev
      cairo
      cairo.dev
      atk
      atk.dev
      libsoup_3
      libsoup_3.dev
      dbus
      dbus.dev
      librsvg
      librsvg.dev
      libayatana-appindicator

      # Android / Tauri mobile development
      jdk17

      # Media and productivity GUI apps
      vlc
      mpv
      spotify
      kdePackages.kdenlive
      android-studio
      scrcpy
      waydroid-helper
      libreoffice-still
      todesk

      # Linux-specific GUI apps
      wechat
      qq

      # wechat-uos
      wpsoffice-cn

      # System tools
      adwaita-qt6
      kdePackages.qt6ct
      gparted
      # polkit strips display env; sudo SETENV preserves DISPLAY/WAYLAND_DISPLAY.
      (lib.hiPrio (
        writeShellScriptBin "gparted" ''
          exec sudo --preserve-env=DISPLAY,WAYLAND_DISPLAY,XDG_RUNTIME_DIR,XAUTHORITY \
            ${pkgs.gparted}/libexec/gpartedbin "$@"
        ''
      ))
      seahorse
      appimage-run
      gearlever

      # Fun / terminal eye candy
      pokemon-colorscripts

      # Gaming
      (lutris.override {
        extraPkgs = pkgs: [
          pkgs.wineWow64Packages.full
          pkgs.gamemode
        ];
        extraLibraries = pkgs: [
          pkgs.gamemode
        ];
      })
      prismlauncher

      winetricks
      wineWow64Packages.full

      # Media capture
      (wrapOBS {
        plugins = with obs-studio-plugins; [
          obs-vaapi
          obs-vkcapture
          obs-pipewire-audio-capture
        ];
      })
      splayer

      # Remote desktop
      todesk
      (writeShellScriptBin "todesk-gui" ''
        # Add X11 authorization
        ${xhost}/bin/xhost +local: >/dev/null 2>&1 || true

        # Force correct environment
        export DISPLAY=:0
        export QT_QPA_PLATFORM=xcb
        export GDK_BACKEND=x11
        export XAUTHORITY="$HOME/.Xauthority"

        # Kill existing GUI instances
        ${procps}/bin/pkill -f "ToDesk desktop" 2>/dev/null || true
        sleep 1

        # Launch with error filtering
        exec ${todesk}/bin/todesk desktop 2>&1 | grep -v "iCCP\|libpng warning" || true
      '')

      # OpenRGB - universal RGB lighting control GUI
      openrgb

      # Xbox controller tools
      antimicrox
      jstest-gtk
      linuxConsoleTools
      winboat
    ];

    # Linux-specific environment variables
    home.sessionVariables = {
      # Fix dynamic linking for Rust binaries on Linux
      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
        pkgs.openssl
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
        pkgs.gamemode
      ];

      # Tauri/GTK PKG_CONFIG
      PKG_CONFIG_PATH = "${pkgs.lib.makeSearchPath "lib/pkgconfig" [
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
      ]}";
      ANDROID_HOME = "$HOME/Android/Sdk";
      JAVA_HOME = "${pkgs.jdk17}";
    };

    systemd.user.sessionVariables = {
      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
        pkgs.openssl
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
        pkgs.gamemode
      ];
      PKG_CONFIG_ALLOW_SYSTEM_CFLAGS = "1";
      PKG_CONFIG_ALLOW_SYSTEM_LIBS = "1";

      # Disable NVIDIA driver's internal threaded GL optimizations.
      # This is the root fix for EGL mutex deadlocks in WebKit and Electron on NVIDIA.
      # Without this, libnvidia-glsi causes deadlocks when multiple threads call EGL simultaneously.
      __GL_THREADED_OPTIMIZATIONS = "0";

      # Disable WebKit DMA-BUF renderer (zero-copy path) which triggers EGL multi-thread issues.
      WEBKIT_DISABLE_DMABUF_RENDERER = "1";
      # WebKit 2.50.5 bug: createVideoSink() ScopeExit iterates the GL video sink bin to find leaf
      # sinks, but webkitglvideosink fails to initialize its internal GL context on NVIDIA/Wayland,
      # leaving the iterator returning an invalid element → gstObjectHasProperty(null) → SIGSEGV.
      # This disables only the GL video sink path, falling back to the software webkitVideoSinkNew().
      # Unlike WEBKIT_DISABLE_COMPOSITING_MODE, GPU compositing for web content remains active.
      WEBKIT_GST_DISABLE_GL_SINK = "1";

      # Wayland & GTK settings
      GDK_BACKEND = "wayland,x11";
      GSK_RENDERER = "ngl";
      GTK_OVERLAY_SCROLLING = "0";
      WLR_NO_HARDWARE_CURSORS = "1";

      # Flatpak app discovery — ensure flatpak .desktop files are visible
      XDG_DATA_DIRS = "$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share\${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}";

      # Chromium hardware acceleration
      MOZ_DISABLE_RDD_SANDBOX = "1";
      NVD_BACKEND = "direct";
    };

    # Linux-specific Zsh aliases (override common.nix aliases)
    programs.zsh.shellAliases = {
      # Linux-specific (with sudo)
      rebuild = "sudo nixos-rebuild switch --flake ~/nix-config\\#nixos";
      test = "sudo nixos-rebuild test --flake ~/nix-config\\#nixos";
      gc = "sudo nix-collect-garbage";
      gcold = "sudo nix-collect-garbage --delete-older-than 30d";
      gcall = "sudo nix-collect-garbage -d";
      optimize = "sudo nix-store --optimize";
      clean = "sudo nix-collect-garbage -d && sudo nix-store --optimize";
      list-gens = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
      phone = "scrcpy --turn-screen-off --stay-awake --max-size=3088 --video-bit-rate=16M --audio-bit-rate=256K";
    };

    programs.zsh.initContent = ''
      llama-start() {
        if [[ -f /tmp/llama-server.pid ]] && kill -0 "$(cat /tmp/llama-server.pid)" 2>/dev/null; then
          echo "llama-server already running (PID $(cat /tmp/llama-server.pid))"
          return
        fi
        llama-server --host 0.0.0.0 --port 11110 -ngl 99 --flash-attn on --no-webui \
          -c 32768 --parallel 1 --cache-type-k q4_0 --cache-type-v q4_0 \
          --models-dir ~/.llama-models --api-key "$(cat /run/secrets/llama-api-key)" "$@" &
        echo $! > /tmp/llama-server.pid
        disown
        echo "llama-server started in background (PID $!)"
      }
      llama-stop() {
        if [[ -f /tmp/llama-server.pid ]]; then
          kill "$(cat /tmp/llama-server.pid)" && rm /tmp/llama-server.pid && echo 'llama-server stopped'
        else
          pkill -f 'llama-server --port 11110' && echo 'llama-server stopped'
        fi
      }
      llama-status() {
        if [[ -f /tmp/llama-server.pid ]] && kill -0 "$(cat /tmp/llama-server.pid)" 2>/dev/null; then
          echo "llama-server running (PID $(cat /tmp/llama-server.pid))"
        else
          echo 'llama-server not running'
        fi
      }
      llama-ls() {
        ls -lh ~/.llama-models/*.gguf 2>/dev/null || echo 'No models found in ~/.llama-models'
      }
      llama-download-models() {
        mkdir -p ~/.llama-models
        echo "==> Qwen3-Coder-30B-A3B Q2_K (coder, ~11.3GB, full GPU)"
        hf download unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF Qwen3-Coder-30B-A3B-Instruct-Q2_K.gguf --local-dir ~/.llama-models
        echo "==> Qwen3-8B Q6_K (chat, ~6.7GB)"
        hf download Qwen/Qwen3-8B-GGUF Qwen3-8B-Q6_K.gguf --local-dir ~/.llama-models
        echo "Done. Models in ~/.llama-models"
      }
    '';

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        # File manager
        "inode/directory" = "org.gnome.Nautilus.desktop";
        "x-directory/normal" = "org.gnome.Nautilus.desktop";

        # Images
        "image/jpeg" = "org.gnome.Loupe.desktop";
        "image/png" = "org.gnome.Loupe.desktop";
        "image/gif" = "org.gnome.Loupe.desktop";
        "image/webp" = "org.gnome.Loupe.desktop";
        "image/avif" = "org.gnome.Loupe.desktop";
        "image/bmp" = "org.gnome.Loupe.desktop";
        "image/tiff" = "org.gnome.Loupe.desktop";
        "image/svg+xml" = "org.gnome.Loupe.desktop";

        # Video
        "video/mp4" = "mpv.desktop";
        "video/mkv" = "mpv.desktop";
        "video/x-matroska" = "mpv.desktop";
        "video/webm" = "mpv.desktop";
        "video/avi" = "mpv.desktop";
        "video/x-msvideo" = "mpv.desktop";
        "video/quicktime" = "mpv.desktop";
        "video/x-flv" = "mpv.desktop";
        "video/mpeg" = "mpv.desktop";

        # Audio
        "audio/mpeg" = "mpv.desktop";
        "audio/mp3" = "mpv.desktop";
        "audio/flac" = "mpv.desktop";
        "audio/ogg" = "mpv.desktop";
        "audio/wav" = "mpv.desktop";
        "audio/aac" = "mpv.desktop";
        "audio/x-m4a" = "mpv.desktop";

        # PDF
        "application/pdf" = "wps-office-pdf.desktop";

        # Documents (WPS Office)
        "application/msword" = "wps-office-wps.desktop";
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
          "wps-office-wps.desktop";
        "application/vnd.oasis.opendocument.text" = "wps-office-wps.desktop";

        # Spreadsheets (WPS ET)
        "application/vnd.ms-excel" = "wps-office-et.desktop";
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "wps-office-et.desktop";
        "application/vnd.oasis.opendocument.spreadsheet" = "wps-office-et.desktop";

        # Presentations (WPS Presentation)
        "application/vnd.ms-powerpoint" = "wps-office-wpp.desktop";
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" =
          "wps-office-wpp.desktop";
        "application/vnd.oasis.opendocument.presentation" = "wps-office-wpp.desktop";

        # Browser
        "text/html" = "google-chrome.desktop";
        "x-scheme-handler/http" = "google-chrome.desktop";
        "x-scheme-handler/https" = "google-chrome.desktop";
        "x-scheme-handler/ftp" = "google-chrome.desktop";
      };
    };

    # Qt icon theme - qt6ct reads from config file, no GSettings/gnome-settings-daemon needed
    qt = {
      enable = true;
      platformTheme.name = "qt6ct";
    };

    xdg.configFile."qt6ct/qt6ct.conf".text = ''
      [Appearance]
      icon_theme=Papirus-Dark
      style=adwaita-dark
      custom_palette=false
    '';

    # GTK theme configuration
    gtk = {
      enable = true;

      theme = {
        name = "Arc-Dark";
        package = pkgs.arc-theme;
      };

      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };

      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-icon-theme-name = "Papirus-Dark";
        gtk-button-images = true;
        gtk-menu-images = true;
        gtk-enable-animations = true;
        gtk-cursor-theme-size = 24;
        gtk-cursor-theme-name = "Adwaita";
        gtk-font-name = "Noto Sans 10";
        gtk-toolbar-style = "GTK_TOOLBAR_BOTH_HORIZ";
        gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
        gtk-enable-event-sounds = 0;
        gtk-enable-input-feedback-sounds = 0;
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintslight";
        gtk-xft-rgba = "rgb";
      };

      gtk4.theme = null; # noctalia GTK template manages gtk-4.0/gtk.css at runtime

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-icon-theme-name = "Papirus-Dark";
        gtk-enable-animations = true;
        gtk-cursor-theme-name = "Adwaita";
        gtk-cursor-theme-size = 24;
        gtk-font-name = "Noto Sans 10";
      };

      gtk2 = {
        configLocation = "${config.xdg.stateHome}/gtk-2.0/gtkrc";
        force = true;
        extraConfig = "";
      };
    };

    # ToDesk desktop launcher
    xdg.dataFile."applications/todesk.desktop".text = ''
      [Desktop Entry]
      Name=ToDesk
      Exec=/etc/profiles/per-user/rea/bin/todesk-gui
      Icon=todesk
      Type=Application
      Categories=Network;RemoteAccess;
      Comment=ToDesk Remote Desktop (Fixed for Wayland/XWayland)
      Terminal=false
      X-KDE-SubstituteUID=false
    '';

    # Chrome flags: force native Wayland and enable GPU zero-copy for NVIDIA
    # --ozone-platform=wayland: explicit (not hint=auto) avoids race condition edge cases
    # --enable-zero-copy: reduces GPU memory copies, alleviates tab-switch flicker on NVIDIA
    # --enable-features=WebUIDarkMode: read GSettings color-scheme (prefer-dark) on Wayland
    xdg.configFile."chrome-flags.conf".text = ''
      --ozone-platform=wayland
      --enable-zero-copy
      --enable-features=WebUIDarkMode
    '';

    # Steam font support
    home.file.".local/share/fonts/noto-cjk/NotoSansCJK-VF.otf.ttc".source =
      "${pkgs.noto-fonts-cjk-sans}/share/fonts/opentype/noto-cjk/NotoSansCJK-VF.otf.ttc";
    home.file.".local/share/fonts/source-han/SourceHanSans-VF.otf.ttc".source =
      "${pkgs.source-han-sans}/share/fonts/opentype/source-han-sans/SourceHanSans-VF.otf.ttc";

    # Fontconfig for Steam CJK support
    xdg.configFile."fontconfig/fonts.conf" = {
      force = true;
      text = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <!-- Direct Arial->CJK mapping (Steam's primary query font) -->
          <match target="pattern">
            <test qual="any" name="family">
              <string>Arial</string>
            </test>
            <edit name="family" mode="prepend" binding="strong">
              <string>Noto Sans CJK SC</string>
              <string>Source Han Sans SC</string>
              <string>WenQuanYi Zen Hei</string>
            </edit>
          </match>

          <!-- Direct Motiva Sans->CJK mapping (Steam UI font) -->
          <match target="pattern">
            <test qual="any" name="family">
              <string>Motiva Sans</string>
            </test>
            <edit name="family" mode="prepend" binding="strong">
              <string>Noto Sans CJK SC</string>
              <string>Source Han Sans SC</string>
              <string>WenQuanYi Zen Hei</string>
            </edit>
          </match>

          <!-- Direct Helvetica->CJK mapping -->
          <match target="pattern">
            <test qual="any" name="family">
              <string>Helvetica</string>
            </test>
            <edit name="family" mode="prepend" binding="strong">
              <string>Noto Sans CJK SC</string>
              <string>Source Han Sans SC</string>
            </edit>
          </match>

          <!-- Direct Times New Roman->CJK mapping -->
          <match target="pattern">
            <test qual="any" name="family">
              <string>Times New Roman</string>
            </test>
            <edit name="family" mode="prepend" binding="strong">
              <string>Noto Serif CJK SC</string>
              <string>Source Han Serif SC</string>
            </edit>
          </match>

          <!-- Default font aliases -->
          <alias>
            <family>sans-serif</family>
            <prefer>
              <family>Noto Sans CJK SC</family>
              <family>Source Han Sans SC</family>
              <family>WenQuanYi Zen Hei</family>
            </prefer>
          </alias>

          <alias>
            <family>serif</family>
            <prefer>
              <family>Noto Serif CJK SC</family>
              <family>Source Han Serif SC</family>
            </prefer>
          </alias>

          <alias>
            <family>monospace</family>
            <prefer>
              <family>Sarasa Mono SC</family>
              <family>Noto Sans Mono CJK SC</family>
            </prefer>
          </alias>
        </fontconfig>
      '';
    };

    # VSCode marketplace extensions ship native binaries without execute permissions.
    # This activation script fixes them after every home-manager switch.
    home.activation.fixVSCodeExtensionBinPerms = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      find "$HOME/.vscode/extensions" \
        -path "*/dist/bundled/bin/linux-x64/*" \
        -type f \
        -not -perm -u+x \
        -exec chmod +x {} \;
    '';

    # Override GParted desktop entry: call the sudo wrapper instead of pkexec.
    xdg.desktopEntries.gparted = {
      name = "GParted";
      exec = "gparted %f";
      icon = "gparted";
      terminal = false;
      categories = [ "System" ];
      comment = "Create, reorganize, and delete disk partitions";
    };
  };
}
