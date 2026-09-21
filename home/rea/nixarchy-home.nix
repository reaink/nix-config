{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  keytaoPackage = inputs.keytao-app.packages.${system}.default;
in
{
  # Omarchy per-user: seeds the Install menu's app selection
  # (~/.config/nixarchy/apps.nix), theme state, and the first-login theme.
  programs.nixarchy = {
    enable = true;
    defaultTheme = "catppuccin";
    # ~/.config/nvim is a read-only symlink to home-manager-files
    # (xdg.configFile."nvim".source in common.nix); nixarchy's imperative
    # spec writes would hit EROFS and fail home-manager activation.
    neovim = "off";
  };

  home.packages = [ keytaoPackage ];

  home.sessionVariables = {
    XMODIFIERS = "@im=keytao";
  };

  systemd.user.sessionVariables = {
    XMODIFIERS = "@im=keytao";
  };

  # KeyTao IME daemon at session start (XDG autostart; Hyprland's systemd
  # session processes it). The KDE virtual-keyboard wiring from kde-home.nix
  # is Plasma-specific and deliberately not carried over.
  xdg.configFile."autostart/keytao-ime.desktop".text = ''
    [Desktop Entry]
    Name=KeyTao IME Daemon
    Exec=${pkgs.coreutils}/bin/env KEYTAO_IME_PANEL_SCALE=0.75 ${keytaoPackage}/bin/keytao-ime
    Icon=keytao-app
    Type=Application
    NoDisplay=true
  '';
}
