{ config, pkgs, lib, inputs, ... }:

{
  # Import noctalia home-manager module
  imports = [
    inputs.noctalia.homeModules.default
  ];

  home.packages = with pkgs; [
    # Additional utilities for niri workflow
    brightnessctl
    playerctl
    pamixer
    jq  # For screenshot window detection
    
    # Icon themes
    papirus-icon-theme
    adwaita-icon-theme
    hicolor-icon-theme  # Base icon theme required by many apps
  ];
  
  # GTK and icon theme environment variables
  home.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
  };

  # Configure noctalia shell
  programs.noctalia-shell = {
    enable = true;
    settings = {
      bar = {
        position = "top";
        density = "default";
        showCapsule = true;
        backgroundOpacity = 0.93;
        widgets = {
          left = [
            {
              id = "Workspaces";
            }
          ];
          right = [
            {
              id = "Tray";
            }
            {
              id = "Volume";
            }
            {
              id = "Battery";
            }
            {
              id = "Clock";
            }
            {
              id = "ControlCenter";
            }
          ];
        };
      };
      tray = {
        enable = true;
        iconSize = 16;
        spacing = 8;
        expandByDefault = true;
      };
      appLauncher = {
        enableClipboardHistory = true;
        autoPasteClipboard = false;
        enableClipPreview = true;
        clipboardWrapText = true;
      };
      templates = {
        enableUserTemplates = true;
      };
    };
  };

  # Install xcursor theme
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  # GTK theme configuration
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    font = {
      name = "Inter";
      size = 11;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Foot terminal
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";
        font = "JetBrains Mono:size=11";
        dpi-aware = "yes";
        pad = "10x10";
      };
      mouse = {
        hide-when-typing = "yes";
      };
      colors = {
        alpha = 0.95;
        background = "1e1e2e";
        foreground = "cdd6f4";
        
        regular0 = "45475a";
        regular1 = "f38ba8";
        regular2 = "a6e3a1";
        regular3 = "f9e2af";
        regular4 = "89b4fa";
        regular5 = "f5c2e7";
        regular6 = "94e2d5";
        regular7 = "bac2de";
        
        bright0 = "585b70";
        bright1 = "f38ba8";
        bright2 = "a6e3a1";
        bright3 = "f9e2af";
        bright4 = "89b4fa";
        bright5 = "f5c2e7";
        bright6 = "94e2d5";
        bright7 = "a6adc8";
      };
    };
  };

  # Swayidle for auto-lock
  services.swayidle = {
    enable = true;
    events = {
      before-sleep = "noctalia-shell ipc call lockScreen lock";
      lock = "noctalia-shell ipc call lockScreen lock";
    };
    timeouts = [
      { timeout = 300; command = "noctalia-shell ipc call lockScreen lock"; }
      { timeout = 600; command = "${pkgs.systemd}/bin/systemctl suspend"; }
    ];
  };

  # Clipboard manager service
  systemd.user.services.cliphist = {
    Unit = {
      Description = "Clipboard history manager for Wayland";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.cliphist-images = {
    Unit = {
      Description = "Clipboard image history manager for Wayland";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Niri configuration via niri-flake (declarative settings)
  programs.niri.settings = {
    input = {
      keyboard = {
        xkb = {
          layout = "us";
        };
        repeat-delay = 600;
        repeat-rate = 25;
      };
      
      touchpad = {
        tap = true;
        natural-scroll = true;
        accel-speed = 0.3;
        dwt = true;
      };
      
      mouse = {
        accel-speed = 0.3;
      };

      power-key-handling.enable = false;
    };

    outputs."eDP-1" = {
      mode = {
        width = 5120;
        height = 2880;
        refresh = 60.0;
      };
      scale = 2.0;
      position = {
        x = 0;
        y = 0;
      };
    };

    layout = {
      gaps = 8;
      center-focused-column = "never";
      
      preset-column-widths = [
        { proportion = 0.33333; }
        { proportion = 0.5; }
        { proportion = 0.66667; }
      ];
      
      default-column-width = { proportion = 0.5; };
      
      focus-ring = {
        width = 2;
        active.color = "#89b4fa";
        inactive.color = "#313244";
      };
      
      border = {
        width = 2;
        active.color = "#89b4fa";
        inactive.color = "#313244";
      };
      
      struts = {
        left = 0;
        right = 0;
        top = 0;
        bottom = 0;
      };
    };

    prefer-no-csd = false;
    screenshot-path = "~/Pictures/Screenshots/screenshot-%Y-%m-%d_%H-%M-%S.png";

    environment = {
      NIXOS_OZONE_WL = "1";
    };

    animations = {
      slowdown = 1.0;
      window-open = {
        kind.easing = {
          duration-ms = 150;
          curve = "ease-out-quad";
          curve-args = [];
        };
      };
      window-close = {
        kind.easing = {
          duration-ms = 150;
          curve = "ease-out-quad";
          curve-args = [];
        };
      };
      window-movement = {
        kind.easing = {
          duration-ms = 200;
          curve = "ease-out-cubic";
          curve-args = [];
        };
      };
      horizontal-view-movement = {
        kind.easing = {
          duration-ms = 200;
          curve = "ease-out-cubic";
          curve-args = [];
        };
      };
      window-resize = {
        kind.easing = {
          duration-ms = 150;
          curve = "ease-out-quad";
          curve-args = [];
        };
      };
      config-notification-open-close = {
        kind.easing = {
          duration-ms = 200;
          curve = "ease-out-quad";
          curve-args = [];
        };
      };
    };

    window-rules = [
      # Password manager - tiled
      {
        matches = [{ app-id = "^org\\.keepassxc\\.KeePassXC$"; }];
        default-column-width = { proportion = 0.33333; };
      }
      
      # Telegram - all windows floating except Media viewer
      {
        matches = [
          { app-id = "^org\\.telegram\\.desktop$"; }
        ];
        excludes = [
          { title = "^Media viewer$"; }
        ];
        open-floating = true;
        default-column-width = { fixed = 1200; };
      }
      
      # WeChat - floating window with CSD enabled
      {
        matches = [
          { app-id = "^wechat$"; }
          { title = "^Weixin$"; }
        ];
        open-floating = true;
        draw-border-with-background = false;
        min-width = 1000;
        min-height = 800;
        default-column-width = { fixed = 1000; };
      }
      
      # Spotify - tiled
      {
        matches = [{ app-id = "^com\\.spotify\\.Client$"; }];
        default-column-width = { proportion = 0.5; };
      }
      
      # Media player - floating
      {
        matches = [{ app-id = "^mpv$"; }];
        open-floating = true;
        default-column-width = { proportion = 0.66667; };
      }
      
      # Image viewer - floating
      {
        matches = [{ app-id = "^imv$"; }];
        open-floating = true;
        default-column-width = { fixed = 1200; };
      }
      
      # Screenshot editor - floating
      {
        matches = [{ app-id = "^swappy$"; }];
        open-floating = true;
        default-column-width = { proportion = 0.8; };
      }
    ];

    spawn-at-startup = [
      { command = ["${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"]; }
      { command = ["fcitx5"]; }
      { command = ["noctalia-shell"]; }
    ];

    binds = {
      "Mod+Return".action.spawn = "foot";
      "Mod+Q".action.close-window = [];
      
      # Vim-style navigation  
      "Mod+H".action.focus-column-left = [];
      "Mod+J".action.focus-window-down = [];
      "Mod+K".action.focus-window-up = [];
      "Mod+L".action.focus-column-right = [];
      
      "Mod+Shift+H".action.move-column-left = [];
      "Mod+Shift+J".action.move-window-down = [];
      "Mod+Shift+K".action.move-window-up = [];
      "Mod+Shift+L".action.move-column-right = [];
      
      "Mod+Ctrl+H".action.focus-monitor-left = [];
      "Mod+Ctrl+J".action.focus-monitor-down = [];
      "Mod+Ctrl+K".action.focus-monitor-up = [];
      "Mod+Ctrl+L".action.focus-monitor-right = [];
      
      "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = [];
      "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = [];
      "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = [];
      "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = [];
      
      "Mod+Page_Down".action.focus-workspace-down = [];
      "Mod+Page_Up".action.focus-workspace-up = [];
      "Mod+U".action.focus-workspace-down = [];
      "Mod+I".action.focus-workspace-up = [];
      
      "Mod+Shift+Page_Down".action.move-column-to-workspace-down = [];
      "Mod+Shift+Page_Up".action.move-column-to-workspace-up = [];
      "Mod+Shift+U".action.move-column-to-workspace-down = [];
      "Mod+Shift+I".action.move-column-to-workspace-up = [];
      
      # Workspace switching
      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;
      
      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;
      "Mod+Shift+4".action.move-column-to-workspace = 4;
      "Mod+Shift+5".action.move-column-to-workspace = 5;
      "Mod+Shift+6".action.move-column-to-workspace = 6;
      "Mod+Shift+7".action.move-column-to-workspace = 7;
      "Mod+Shift+8".action.move-column-to-workspace = 8;
      "Mod+Shift+9".action.move-column-to-workspace = 9;
      
      "Mod+Comma".action.consume-window-into-column = [];
      "Mod+Period".action.expel-window-from-column = [];
      
      "Mod+R".action.switch-preset-column-width = [];
      "Mod+F".action.maximize-column = [];
      "Mod+Shift+F".action.fullscreen-window = [];
      "Mod+C".action.center-column = [];
      
      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";
      
      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";
      
      # Screenshots with annotation
      "Print".action.spawn = ["sh" "-c" "grim -g \"$(slurp)\" - | swappy -f -"];
      "Ctrl+Print".action.spawn = ["sh" "-c" "grim - | swappy -f -"];
      "Alt+Print".action.spawn = ["sh" "-c" "grim -g \"$(niri msg -j windows | jq -r '.[] | select(.is_focused == true) | \"\\(.layout.tile_pos_in_workspace_view[0]|floor),\\(.layout.tile_pos_in_workspace_view[1]|floor) \\(.layout.window_size[0])x\\(.layout.window_size[1])\"')\" - | swappy -f -"];
      "Shift+Print".action.screenshot = [];
      
      "Mod+Shift+E".action.quit = [];
      "Mod+Shift+P".action.power-off-monitors = [];
      "Mod+Shift+Ctrl+T".action.toggle-debug-tint = [];
      
      # Media keys
      "XF86AudioRaiseVolume".action.spawn = ["pamixer" "-i" "5"];
      "XF86AudioLowerVolume".action.spawn = ["pamixer" "-d" "5"];
      "XF86AudioMute".action.spawn = ["pamixer" "-t"];
      "XF86AudioMicMute".action.spawn = ["pamixer" "--default-source" "-t"];
      
      "XF86MonBrightnessUp".action.spawn = ["brightnessctl" "set" "5%+"];
      "XF86MonBrightnessDown".action.spawn = ["brightnessctl" "set" "5%-"];
      
      "XF86AudioPlay".action.spawn = ["playerctl" "play-pause"];
      "XF86AudioNext".action.spawn = ["playerctl" "next"];
      "XF86AudioPrev".action.spawn = ["playerctl" "previous"];
      
      # Application shortcuts
      "Mod+T".action.focus-workspace-down = [];
      "Mod+B".action.spawn = "google-chrome-stable";
      "Mod+E".action.spawn = "thunar";
      "Mod+Escape".action.spawn = ["noctalia-shell" "ipc" "call" "lockScreen" "lock"];
      
      # Noctalia keybinds
      "Mod+Space".action.spawn = ["noctalia-shell" "ipc" "call" "launcher" "toggle"];
      "Mod+N".action.spawn = ["noctalia-shell" "ipc" "call" "controlCenter" "toggle"];
      "Mod+V".action.spawn = ["noctalia-shell" "ipc" "call" "launcher" "clipboard"];
      "Mod+S".action.spawn = ["noctalia-shell" "ipc" "call" "sessionMenu" "toggle"];
    };

    debug.render-drm-device = "/dev/dri/renderD128";
  };

  # Create screenshot directory
  home.activation.createScreenshotDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $HOME/Pictures/Screenshots
  '';

  # Screenshot scripts
  home.file.".local/bin/screenshot-area" = {
    executable = true;
    text = ''
      #!/bin/sh
      ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy -f -
    '';
  };

  home.file.".local/bin/screenshot-full" = {
    executable = true;
    text = ''
      #!/bin/sh
      ${pkgs.grim}/bin/grim - | ${pkgs.swappy}/bin/swappy -f -
    '';
  };

  home.file.".local/bin/screenshot-window" = {
    executable = true;
    text = ''
      #!/bin/sh
      # For niri, capture the active window area
      ${pkgs.grim}/bin/grim -g "$(${pkgs.niri-stable}/bin/niri msg -j windows | ${pkgs.jq}/bin/jq -r '.[] | select(.is_focused == true) | "\(.layout.tile_pos_in_workspace_view[0]|floor),\(.layout.tile_pos_in_workspace_view[1]|floor) \(.layout.window_size[0])x\(.layout.window_size[1])"')" - | ${pkgs.swappy}/bin/swappy -f -
    '';
  };
}
