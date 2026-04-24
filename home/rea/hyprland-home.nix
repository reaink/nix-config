{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    waybar
    swaynotificationcenter
    rofi
    hyprshot
    hyprpicker
    hyprpolkitagent
    cliphist
    wl-clipboard
    swaybg
    ghostty
    nautilus
    networkmanagerapplet
    blueman
    pavucontrol
    brightnessctl
    kdePackages.kdeconnect-kde
    wtype
  ];

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    # Must be false when using UWSM — they conflict
    systemd.enable = false;

    settings = {
      monitor = ",preferred,auto,auto";

      env = [
        "LIBVA_DRIVER_NAME,nvidia"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "GBM_BACKEND,nvidia-drm"
        "GDK_BACKEND,wayland,x11"
        "QT_QPA_PLATFORM,wayland;xcb"
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Adwaita"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
      ];

      exec-once = [
        "uwsm app -- waybar"
        "uwsm app -- swaync"
        "uwsm app -- nm-applet --indicator"
        "uwsm app -- blueman-applet"
        "uwsm app -- ${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent"
        "swaybg -c '#2e3440'"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "fcitx5 -d --replace"
      ];

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgba(88c0d0ff) rgba(81a1c1ff) 45deg";
        "col.inactive_border" = "rgba(4c566aaa)";
        layout = "dwindle";
        allow_tearing = false;
      };

      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
        };
        shadow = {
          enabled = true;
          range = 8;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "easeOut, 0.05, 0.9, 0.1, 1.05"
          "workspaceIn, 0.25, 0.85, 0.25, 1.0"
        ];
        animation = [
          "windows, 1, 5, easeOut"
          "windowsOut, 1, 4, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 6, default"
          "workspaces, 1, 5, workspaceIn, slide"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        vfr = true;
      };

      cursor = {
        # Required for NVIDIA — hardware cursors cause glitches
        no_hardware_cursors = true;
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = false;
        };
      };

      "$mod" = "SUPER";

      bind = [
        "$mod, Return, exec, uwsm app -- ghostty"
        "$mod, Q, killactive"
        "$mod, M, exit"
        "$mod, E, exec, uwsm app -- nautilus"
        "$mod, Space, exec, rofi -show drun"
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"
        "$mod, P, pseudo"
        "$mod, S, togglesplit"

        # Screenshot
        ", Print, exec, hyprshot -m region"
        "$mod, Print, exec, hyprshot -m window"

        # Clipboard history
        "$mod, C, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"

        # Notifications
        "$mod, N, exec, swaync-client -t"

        # Focus
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # Move window
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"

        # Move window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"

        # Workspace scroll
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Media / brightness keys — repeating
      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl set 10%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
      ];

      windowrule = [
        "float, class:^(nm-connection-editor)$"
        "float, class:^(blueman-manager)$"
        "float, class:^(pavucontrol)$"
        "float, class:^(org.gnome.Nautilus)$, title:Properties$"
      ];
    };
  };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 36;
        spacing = 4;
        modules-left = [
          "hyprland/workspaces"
          "hyprland/window"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "tray"
          "pulseaudio"
          "network"
          "bluetooth"
          "custom/notification"
        ];

        "hyprland/workspaces" = {
          format = "{id}";
          on-click = "activate";
        };

        "hyprland/window" = {
          max-length = 60;
        };

        "clock" = {
          format = "{:%Y-%m-%d %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "network" = {
          format-wifi = "󰤨 {signalStrength}%";
          format-ethernet = "󰈀 {ipaddr}";
          format-disconnected = "󰤭";
          tooltip-format = "{ifname}: {ipaddr}";
          on-click = "nm-connection-editor";
        };

        "bluetooth" = {
          format = "󰂯";
          format-disabled = "󰂲";
          format-connected = "󰂱 {num_connections}";
          on-click = "blueman-manager";
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = "󰝟";
          format-icons = {
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          on-click = "pavucontrol";
        };

        "tray" = {
          spacing = 10;
        };

        "custom/notification" = {
          tooltip = false;
          format = "{icon}";
          format-icons = {
            notification = "󰂚";
            none = "󰂜";
            dnd-notification = "󰂛";
            dnd-none = "󰂛";
          };
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "swaync-client -swb";
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape = true;
        };
      };
    };
    style = ''
      * {
        font-family: "Maple Mono NF CN", "Noto Sans CJK SC", monospace;
        font-size: 13px;
      }
      window#waybar {
        background-color: rgba(46, 52, 64, 0.92);
        color: #d8dee9;
        border-bottom: 2px solid rgba(136, 192, 208, 0.4);
      }
      .modules-left, .modules-center, .modules-right {
        padding: 0 8px;
      }
      #workspaces button {
        padding: 0 6px;
        color: #4c566a;
        border-radius: 4px;
        margin: 4px 2px;
      }
      #workspaces button.active {
        color: #88c0d0;
        background-color: rgba(136, 192, 208, 0.15);
      }
      #workspaces button:hover {
        background-color: rgba(216, 222, 233, 0.1);
      }
      #window { color: #d8dee9; }
      #clock { color: #ebcb8b; }
      #network { color: #88c0d0; }
      #bluetooth { color: #81a1c1; }
      #pulseaudio { color: #b48ead; }
      #tray { padding: 0 4px; }
      #custom-notification { color: #a3be8c; }
    '';
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        grace = 5;
        hide_cursor = true;
      };
      background = [
        {
          monitor = "";
          path = "screenshot";
          blur_passes = 3;
          blur_size = 7;
        }
      ];
      input-field = [
        {
          monitor = "";
          size = "300, 50";
          position = "0, -80";
          halign = "center";
          valign = "center";
          dots_center = true;
          fade_on_empty = false;
          placeholder_text = "Password";
          shadow_passes = 2;
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        lock_cmd = "hyprlock";
      };
      listener = [
        {
          timeout = 600;
          on-timeout = "hyprlock";
        }
        {
          timeout = 900;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
