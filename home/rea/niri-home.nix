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
      gaps = 12;
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
      # Force niri to render on the NVIDIA GPU (card1/renderD129).
      # Without this, niri may pick card0 (AMD iGPU), causing cross-GPU buffer copies → tearing.
      render-drm-device = "/dev/dri/renderD129";
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
    # Catppuccin Mocha — dark variant from noctalia-colorschemes community repo.
    # These override noctalia's built-in color generation; switch to
    # colorScheme.scheme = "Catppuccin Lavender" in the GUI if you prefer runtime switching.
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
}
