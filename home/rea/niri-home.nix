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
      {
        command = [
          "wl-paste"
          "--type"
          "text"
          "--watch"
          "cliphist"
          "store"
        ];
      }
      {
        command = [
          "wl-paste"
          "--type"
          "image"
          "--watch"
          "cliphist"
          "store"
        ];
      }
      { command = [ "xwayland-satellite" ]; }
    ];

    environment = {
      "NIXOS_OZONE_WL" = "1";
      "ELECTRON_OZONE_PLATFORM_HINT" = "wayland";
      "GDK_BACKEND" = "wayland,x11";
      "QT_QPA_PLATFORM" = "wayland;xcb";
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
      gaps = 8;
      center-focused-column = "on-overflow";
      preset-column-widths = [
        { proportion = 0.5; }
        { proportion = 0.667; }
        { proportion = 1.0; }
      ];
      border = {
        enable = true;
        width = 2;
        active.color = "#c4a7e7";
        inactive.color = "#393552";
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
      # Force niri to render on the NVIDIA GPU (card1/renderD129).
      # Without this, niri may pick card0 (AMD iGPU), causing cross-GPU buffer copies → tearing.
      render-drm-device = "/dev/dri/renderD129";
    };

    outputs."DP-1" = {
      variable-refresh-rate = "on-demand";
    };

    overview.backdrop-color = "#1f1d2e";

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
      "Mod+Return".action.spawn = [ "kitty" ];
      "Mod+E".action.spawn = [ "nautilus" ];
      "Mod+Space".action.spawn = noctalia "launcher toggle";
      "Mod+Shift+E".action.spawn = noctalia "sessionMenu toggle";
      "Mod+N".action.spawn = noctalia "notifications toggle";
      "Mod+Alt+L".action.spawn = noctalia "lockScreen lock";

      "Mod+Q".action.close-window = { };

      "Mod+Left".action.focus-column-left = { };
      "Mod+Right".action.focus-column-right = { };
      "Mod+Up".action.focus-window-up = { };
      "Mod+Down".action.focus-window-down = { };
      "Mod+H".action.focus-column-left = { };
      "Mod+L".action.focus-column-right = { };
      "Mod+K".action.focus-window-up = { };
      "Mod+J".action.focus-window-down = { };

      "Mod+Shift+Left".action.move-column-left = { };
      "Mod+Shift+Right".action.move-column-right = { };
      "Mod+Shift+Up".action.move-window-up = { };
      "Mod+Shift+Down".action.move-window-down = { };
      "Mod+Shift+H".action.move-column-left = { };
      "Mod+Shift+L".action.move-column-right = { };
      "Mod+Shift+K".action.move-window-up = { };
      "Mod+Shift+J".action.move-window-down = { };

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

      "Mod+F".action.fullscreen-window = { };
      "Mod+Shift+V".action.toggle-window-floating = { };
      "Mod+C".action.center-column = { };
      "Mod+R".action.switch-preset-column-width = { };
      "Mod+Shift+R".action.reset-window-height = { };

      "Print".action.screenshot = { };
      "Mod+Print".action.screenshot-window = { };

      "XF86AudioRaiseVolume".action.spawn = noctalia "volume increase";
      "XF86AudioLowerVolume".action.spawn = noctalia "volume decrease";
      "XF86AudioMute".action.spawn = noctalia "volume muteOutput";
      "XF86MonBrightnessUp".action.spawn = [
        "brightnessctl"
        "s"
        "10%+"
      ];
      "XF86MonBrightnessDown".action.spawn = [
        "brightnessctl"
        "s"
        "10%-"
      ];

      "Mod+Shift+Q".action.quit = { };
      "Mod+Shift+Slash".action.show-hotkey-overlay = { };
    };
  };

  programs.noctalia-shell.enable = true;

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
    nautilus
    pavucontrol
    brightnessctl
    wlsunset
    imagemagick
    xwayland-satellite
  ];
}
