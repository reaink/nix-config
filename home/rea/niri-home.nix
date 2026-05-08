{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  noctalia =
    cmd:
    [
      "noctalia-shell"
      "ipc"
      "call"
    ]
    ++ (lib.splitString " " cmd);
in
{
  programs.niri.settings = {
    spawn-at-startup = [
      { command = [ "noctalia-shell" ]; }
      { command = [ "keytao-installer" ]; }
      {
        command = [
          "wl-clip-persist"
          "--clipboard"
          "both"
        ];
      }
      {
        # --disable xcb: prevents the xcb addon from connecting to XWayland,
        # which causes a 100% CPU busy loop (xcb_poll_for_event tight loop).
        command = [
          "fcitx5"
          "--replace"
          "--disable"
          "xcb"
        ];
      }
    ];

    environment = {
      "NIXOS_OZONE_WL" = "1";
      "ELECTRON_OZONE_PLATFORM_HINT" = "wayland";
      "GDK_BACKEND" = "wayland,x11";
      "QT_QPA_PLATFORM" = "wayland;xcb";
      "QT_QPA_PLATFORMTHEME" = "qt6ct"; # lets qt6ct apply noctalia colors to Qt apps
      "XDG_CURRENT_DESKTOP" = "niri:GNOME";
    };

    input = {
      keyboard = {
        xkb = {
          layout = "us";
          options = "compose:ralt";
        };
        repeat-delay = 400;
        repeat-rate = 30;
      };
      focus-follows-mouse.enable = true;
      warp-mouse-to-focus.enable = true;
    };

    layout = {
      gaps = 8; # match noctalia bar frameThickness
      center-focused-column = "on-overflow";
      preset-column-widths = [
        { proportion = 0.333; }
        { proportion = 0.5; }
        { proportion = 0.667; }
        { proportion = 1.0; }
      ];
      border = {
        enable = true;
        width = 2;
        active.color = "#b4befe"; # Catppuccin Mocha lavender
        inactive.color = "#313244"; # Catppuccin Mocha surface1
      };
      focus-ring.enable = false;
      # shadow disabled: causes flickering on NVIDIA due to extra render pass buffer sync
      shadow.enable = false;
    };

    cursor = {
      theme = "Adwaita";
      size = 24;
      hide-when-typing = true;
    };

    prefer-no-csd = true;

    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

    hotkey-overlay.skip-at-startup = true;

    animations.slowdown = 0.6;

    debug = {
      "honor-xdg-activation-with-invalid-serial" = [ ];
      # Force niri to render on the NVIDIA GPU (card1/renderD128).
      # Without this, niri picks card0 (AMD iGPU, renderD129), causing cross-GPU buffer copies
      # and exposes niri to AMD iGPU page faults triggered by other processes (e.g. Chrome).
      render-drm-device = "/dev/dri/renderD128";
      # Workaround for NVIDIA open driver fence sync bug: the driver does not properly honor
      # IN_FENCE_FD, causing frames to be scanned out before rendering completes, resulting
      # in single-frame flickers (wallpaper/previous frame) when switching windows.
      # See: https://github.com/niri-wm/niri/issues/2030 and #2477
      "wait-for-frame-completion-before-queueing" = [ ];
    };

    outputs."DP-1" = {
      variable-refresh-rate = "on-demand";
    };

    overview.backdrop-color = "#1e1e2e"; # Catppuccin Mocha base

    window-rules = [
      {
        geometry-corner-radius = {
          top-left = 14.0;
          top-right = 14.0;
          bottom-left = 14.0;
          bottom-right = 14.0;
        };
        clip-to-geometry = true;
      }
      {
        matches = [
          {
            app-id = "^org.gnome.Nautilus$";
            title = "Properties$";
          }
        ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "^nm-connection-editor$"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "^pavucontrol$"; } ];
        open-floating = true;
      }
    ];

    layer-rules = [
      {
        matches = [ { namespace = "^noctalia-overview.*"; } ];
        place-within-backdrop = true;
      }
    ];

    binds = {
      # --- Apps ---
      "Mod+Return".action.spawn = [ "kitty" ];
      "Mod+E".action.spawn = [ "nautilus" ];

      # --- Shell (noctalia) ---
      "Mod+Space".action.spawn = noctalia "launcher toggle";
      "Mod+Alt+R".action.spawn = [
        "sh"
        "-c"
        "noctalia-shell kill; exec noctalia-shell"
      ];
      "Mod+V".action.spawn = noctalia "launcher clipboard"; # clipboard history (supports images)
      "Mod+Period".action.spawn = noctalia "launcher emoji";
      "Mod+S".action.spawn = noctalia "controlCenter toggle";
      "Mod+Comma".action.spawn = noctalia "settings toggle";
      "Mod+N".action.spawn = noctalia "notifications toggleHistory";
      "Mod+Shift+N".action.spawn = noctalia "notifications toggleDND";
      "Mod+Shift+E".action.spawn = noctalia "sessionMenu toggle";
      "Mod+Alt+L".action.spawn = noctalia "lockScreen lock";

      # --- Window management ---
      "Mod+Q".action.close-window = { };
      "Mod+F".action.fullscreen-window = { };
      "Mod+Shift+V".action.toggle-window-floating = { };
      "Mod+C".action.center-column = { };

      # column management: merge window below into current column / split out
      "Mod+I".action.consume-window-into-column = { };
      "Mod+O".action.expel-window-from-column = { };

      # --- Focus ---
      "Mod+Left".action.focus-column-left = { };
      "Mod+Right".action.focus-column-right = { };
      "Mod+Up".action.focus-window-up = { };
      "Mod+Down".action.focus-window-down = { };
      "Mod+H".action.focus-column-left = { };
      "Mod+L".action.focus-column-right = { };
      "Mod+K".action.focus-window-up = { };
      "Mod+J".action.focus-window-down = { };

      # --- Move ---
      "Mod+Shift+Left".action.move-column-left = { };
      "Mod+Shift+Right".action.move-column-right = { };
      "Mod+Shift+Up".action.move-window-up = { };
      "Mod+Shift+Down".action.move-window-down = { };
      "Mod+Shift+H".action.move-column-left = { };
      "Mod+Shift+L".action.move-column-right = { };
      "Mod+Shift+K".action.move-window-up = { };
      "Mod+Shift+J".action.move-window-down = { };

      # --- Resize ---
      "Mod+R".action.switch-preset-column-width = { };
      "Mod+Shift+R".action.reset-window-height = { };
      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";
      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";

      # --- Workspaces ---
      "Mod+Tab".action.focus-workspace-previous = { };
      "Mod+BracketLeft".action.focus-workspace-up = { };
      "Mod+BracketRight".action.focus-workspace-down = { };
      "Mod+Shift+BracketLeft".action.move-column-to-workspace-up = { };
      "Mod+Shift+BracketRight".action.move-column-to-workspace-down = { };

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;

      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;
      "Mod+Shift+4".action.move-column-to-workspace = 4;
      "Mod+Shift+5".action.move-column-to-workspace = 5;
      "Mod+Shift+6".action.move-column-to-workspace = 6;

      # --- Screenshots ---
      "Print".action.screenshot = { };
      "Mod+Print".action.screenshot-window = { };
      "Shift+Print".action.screenshot-screen = { };

      # --- Media ---
      "XF86AudioPlay".action.spawn = noctalia "media playPause";
      "XF86AudioNext".action.spawn = noctalia "media next";
      "XF86AudioPrev".action.spawn = noctalia "media previous";
      "XF86AudioRaiseVolume".action.spawn = noctalia "volume increase";
      "XF86AudioLowerVolume".action.spawn = noctalia "volume decrease";
      "XF86AudioMute".action.spawn = noctalia "volume muteOutput";
      "XF86AudioMicMute".action.spawn = noctalia "volume muteInput";
      "XF86MonBrightnessUp".action.spawn = noctalia "brightness increase";
      "XF86MonBrightnessDown".action.spawn = noctalia "brightness decrease";

      # --- Session ---
      "Mod+Shift+Q".action.quit = { };
      "Mod+Shift+Slash".action.show-hotkey-overlay = { };
    };
  };

  programs.noctalia-shell = {
    enable = true;

    settings = {
      settingsVersion = 59;

      bar = {
        barType = "simple";
        position = "top";
        density = "default";
        showOutline = true;
        showCapsule = true;
        capsuleOpacity = 0.85;
        widgetSpacing = 6;
        contentPadding = 2;
        enableExclusionZoneInset = true;
        backgroundOpacity = 1;
        marginVertical = 4;
        marginHorizontal = 4;
        frameThickness = 8;
        frameRadius = 12;
        outerCorners = true;
        displayMode = "always_visible";
        rightClickAction = "controlCenter";
        widgets = {
          left = [
            { id = "Launcher"; }
            {
              id = "Workspace";
              hideUnoccupied = false;
              labelMode = "index";
              fontWeight = "bold";
              showBadge = true;
              showLabelsOnlyWhenOccupied = true;
              focusedColor = "primary";
              occupiedColor = "secondary";
              enableScrollWheel = true;
              pillSize = 0.6;
              iconScale = 0.8;
              groupedBorderOpacity = 1;
              unfocusedIconsOpacity = 1;
              colorizeIcons = false;
            }
            {
              id = "SystemMonitor";
              compactMode = true;
              diskPath = "/";
              showCpuUsage = true;
              showCpuTemp = true;
              showMemoryUsage = true;
              useMonospaceFont = true;
              usePadding = false;
            }
            {
              id = "ActiveWindow";
              maxWidth = 145;
              showIcon = true;
              showText = true;
              scrollingMode = "hover";
              hideMode = "hidden";
              colorizeIcons = false;
            }
            {
              id = "MediaMini";
              hideMode = "hidden";
              hideWhenIdle = false;
              maxWidth = 145;
              showAlbumArt = true;
              showArtistFirst = true;
              showProgressRing = true;
              scrollingMode = "hover";
              showVisualizer = false;
              visualizerType = "linear";
            }
          ];
          center = [
            {
              id = "Clock";
              formatHorizontal = "HH:mm ddd, MMM dd";
              formatVertical = "HH mm - dd MM";
              tooltipFormat = "HH:mm ddd, MMM dd";
            }
            {
              id = "NotificationHistory";
              showUnreadBadge = true;
              unreadBadgeColor = "primary";
            }
          ];
          right = [
            {
              id = "Tray";
              drawerEnabled = false;
              hidePassive = false;
              colorizeIcons = false;
            }
            {
              id = "Battery";
              displayMode = "graphic-clean";
              hideIfNotDetected = true;
              showPowerProfiles = false;
            }
            {
              id = "Volume";
              displayMode = "onhover";
              middleClickCommand = "pwvucontrol || pavucontrol";
            }
            {
              id = "Brightness";
              displayMode = "onhover";
            }
            {
              id = "ControlCenter";
              icon = "noctalia";
              useDistroLogo = false;
            }
          ];
        };
      };

      general = {
        avatarImage = "/home/rea/.face";
        enableShadows = false;
        enableBlurBehind = false;
        lockOnSuspend = true;
        showSessionButtonsOnLockScreen = true;
        clockStyle = "custom";
        clockFormat = "hh\\nmm";
        telemetryEnabled = false;
        showChangelogOnStartup = true;
        smoothScrollEnabled = true;
        autoStartAuth = true;
      };

      ui = {
        fontDefault = "Noto Sans";
        fontFixed = "Maple Mono";
        tooltipsEnabled = true;
        panelBackgroundOpacity = 0.7;
        panelsAttachedToBar = true;
        scrollbarAlwaysVisible = true;
        boxBorderEnabled = true;
        settingsPanelMode = "attached";
        settingsPanelSideBarCardStyle = true;
      };

      location = {
        name = "Xi'an, Shaanxi";
        weatherEnabled = true;
        weatherShowEffects = true;
        autoLocate = false;
        useFahrenheit = false;
        use12hourFormat = false;
        showWeekNumberInCalendar = true;
        showCalendarEvents = true;
        showCalendarWeather = true;
        analogClockInCalendar = true;
        firstDayOfWeek = -1;
      };

      wallpaper = {
        enabled = true;
        directory = "/home/rea/Pictures/Wallpapers";
        fillMode = "stretch";
        automationEnabled = true;
        wallpaperChangeMode = "random";
        randomIntervalSec = 3600;
        transitionDuration = 1500;
        transitionEdgeSmoothness = 0.05;
        skipStartupTransition = false;
        overviewBlur = 0.4;
        overviewTint = 0.6;
        useWallhaven = false;
        wallhavenSorting = "relevance";
        wallhavenOrder = "desc";
        wallhavenCategories = "111";
        wallhavenPurity = "100";
        wallhavenResolutionMode = "atleast";
        panelPosition = "follow_bar";
        sortOrder = "name";
      };

      appLauncher = {
        enableClipboardHistory = true;
        autoPasteClipboard = false;
        enableClipPreview = true;
        clipboardWrapText = true;
        enableClipboardSmartIcons = true;
        enableClipboardChips = true;
        clipboardWatchTextCommand = "wl-paste --type text --watch cliphist store";
        clipboardWatchImageCommand = "wl-paste --type image --watch cliphist store";
        sortByMostUsed = true;
        terminalCommand = "kitty";
        viewMode = "grid";
        showCategories = true;
        iconMode = "tabler";
        showIconBackground = true;
        enableSettingsSearch = true;
        enableWindowsSearch = true;
        enableSessionSearch = true;
        density = "default";
      };

      sessionMenu = {
        viewMode = "grid";
      };

      dock = {
        enabled = false;
        position = "bottom";
        displayMode = "always_visible";
        dockType = "floating";
        backgroundOpacity = 0.8;
        floatingRatio = 1;
        size = 0.7;
        onlySameOutput = true;
        pinnedApps = [
          "code"
          "google-chrome"
          "wechat"
        ];
        colorizeIcons = false;
        showLauncherIcon = true;
        launcherPosition = "start";
        launcherUseDistroLogo = false;
        pinnedStatic = false;
        inactiveIndicators = true;
        groupApps = true;
        groupContextMenuMode = "extended";
        groupClickAction = "cycle";
        groupIndicatorStyle = "dots";
        deadOpacity = 0.6;
        animationSpeed = 1;
        sitOnFrame = false;
        indicatorThickness = 6;
        indicatorColor = "primary";
        indicatorOpacity = 0.6;
      };

      controlCenter = {
        position = "close_to_bar_button";
        diskPath = "/";
        shortcuts = {
          left = [
            { id = "Network"; }
            { id = "Bluetooth"; }
            { id = "WallpaperSelector"; }
            { id = "NoctaliaPerformance"; }
          ];
          right = [
            { id = "Notifications"; }
            { id = "PowerProfile"; }
            { id = "KeepAwake"; }
            { id = "NightLight"; }
          ];
        };
        cards = [
          {
            id = "profile-card";
            enabled = true;
          }
          {
            id = "shortcuts-card";
            enabled = true;
          }
          {
            id = "audio-card";
            enabled = true;
          }
          {
            id = "brightness-card";
            enabled = false;
          }
          {
            id = "weather-card";
            enabled = true;
          }
          {
            id = "media-sysmon-card";
            enabled = true;
          }
        ];
      };

      systemMonitor = {
        cpuWarningThreshold = 80;
        cpuCriticalThreshold = 90;
        tempWarningThreshold = 80;
        tempCriticalThreshold = 90;
        memWarningThreshold = 80;
        memCriticalThreshold = 90;
        diskWarningThreshold = 80;
        diskCriticalThreshold = 90;
        batteryWarningThreshold = 20;
        batteryCriticalThreshold = 5;
        enableDgpuMonitoring = true;
      };

      network = {
        networkPanelView = "wifi";
        wifiDetailsViewMode = "list";
        bluetoothDetailsViewMode = "grid";
        bluetoothAutoConnect = true;
      };

      notifications = {
        enabled = true;
        density = "default";
        location = "top_center";
        overlayLayer = true;
        backgroundOpacity = 1;
        lowUrgencyDuration = 3;
        normalUrgencyDuration = 8;
        criticalUrgencyDuration = 15;
        clearDismissed = true;
        enableKeyboardLayoutToast = true;
        enableBatteryToast = true;
        enableMarkdown = false;
        sounds.enabled = false;
      };

      osd = {
        enabled = true;
        location = "top_right";
        autoHideMs = 2000;
        overlayLayer = true;
        backgroundOpacity = 1;
      };

      audio = {
        volumeStep = 5;
        volumeOverdrive = false;
        spectrumFrameRate = 30;
        visualizerType = "linear";
        spectrumMirrored = true;
      };

      brightness = {
        brightnessStep = 5;
        enforceMinimum = true;
        enableDdcSupport = false;
      };

      nightLight = {
        enabled = false;
        autoSchedule = true;
        nightTemp = "4000";
        dayTemp = "6500";
        manualSunrise = "06:30";
        manualSunset = "18:30";
      };

      idle = {
        enabled = true;
        screenOffTimeout = 600;
        lockTimeout = 660;
        suspendTimeout = 1800;
        fadeDuration = 5;
      };

      colorSchemes = {
        useWallpaperColors = false;
        predefinedScheme = "Catppuccin";
        darkMode = true;
        schedulingMode = "off";
        generationMethod = "fruit-salad";
        syncGsettings = true;
      };

      templates = {
        activeTemplates = [
          {
            id = "niri";
            enabled = true;
          }
          {
            id = "code";
            enabled = true;
          }
          {
            id = "telegram";
            enabled = true;
          }
          {
            id = "kitty";
            enabled = true;
          }
          {
            id = "starship";
            enabled = true;
          }
          {
            id = "steam";
            enabled = true;
          }
          {
            id = "qt";
            enabled = true;
          }
          {
            id = "gtk";
            enabled = true;
          }
          {
            id = "fuzzel";
            enabled = true;
          }
          {
            id = "foot";
            enabled = true;
          }
          {
            id = "btop";
            enabled = true;
          }
          {
            id = "sway";
            enabled = true;
          }
          {
            id = "zed";
            enabled = true;
          }
        ];
        enableUserTheming = false;
      };

      hooks.enabled = false;
      plugins = {
        autoUpdate = true;
        notifyUpdates = true;
      };
    };

    # Catppuccin Mocha (dark) explicit colors — from noctalia-colorschemes community repo.
    # Overrides the predefinedScheme above for pixel-perfect color control.
    colors = {
      mPrimary = "#b4befe"; # lavender
      mOnPrimary = "#11111b"; # crust
      mSecondary = "#f5bde6"; # pink
      mOnSecondary = "#11111b";
      mTertiary = "#c6a0f6"; # mauve
      mOnTertiary = "#11111b";
      mError = "#f38ba8"; # red
      mOnError = "#11111b";
      mSurface = "#1e1e2e"; # base
      mOnSurface = "#cdd6f4"; # text
      mHover = "#c6a0f6"; # mauve
      mOnHover = "#11111b";
      mSurfaceVariant = "#313244"; # surface1
      mOnSurfaceVariant = "#a3b4eb";
      mOutline = "#4c4f69"; # overlay1
      mShadow = "#11111b"; # crust
    };
  };

  # noctalia writes back to settings.json at runtime, turning home-manager's symlink into a plain
  # file. On the next rebuild, home-manager tries to back it up to settings.json.backup, which
  # already exists from the previous cycle, causing a failure. Clean both files before activation.
  # gtk.css is also overwritten by nwg-look (symlink) or noctalia's GTK template at runtime.
  home.activation.cleanNoctaliaConflicts = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    rm -f "${config.xdg.configHome}/noctalia/settings.json.backup"
  '';

  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];
  };

  xdg.dataFile."applications/kbd-layout-viewer5.desktop".text = ''
    [Desktop Entry]
    NoDisplay=true
    Type=Application
    Name=Keyboard Layout Viewer
  '';

  # fcitx5 is configured at system level (configuration.nix) with waylandFrontend = true.
  # Declaring i18n.inputMethod here would overwrite ~/.config/fcitx5/profile and
  # strip the Wayland frontend, breaking input on native Wayland apps.

  home.packages = with pkgs; [
    kitty
    cliphist
    wl-clipboard
    wl-clip-persist
    nautilus
    pavucontrol
    brightnessctl
    wlsunset
    imagemagick
    xwayland-satellite

    # Image viewer
    loupe

    # Screenshot annotation (open with swappy after Print)
    swappy

    # Screen recording
    wf-recorder

    # Calculator
    gnome-calculator

    # GTK theming: adw-gtk3 is the base theme; nwg-look applies it
    # One-time setup: open nwg-look, select adw-gtk3, click Apply
    # Then in noctalia: Settings → Color Scheme → Templates → enable GTK
    adw-gtk3
    nwg-look
  ];

  # gvfs-daemon: required by Nautilus for rename, trash, and metadata operations.
  # The linked-runtime unit has no [Install] section so it won't auto-start without this.
  systemd.user.services.gvfs-daemon = {
    Unit = {
      Description = "Virtual filesystem service";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.gtk.vfs.Daemon";
      ExecStart = "${pkgs.gvfs}/libexec/gvfsd";
      Slice = "session.slice";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
