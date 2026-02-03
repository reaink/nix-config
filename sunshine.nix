# Sunshine game streaming service with Steam integration
# Based on: https://github.com/Mistyttm/nixos-configs/blob/main/modules/nixos/sunshine.nix
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.sunshineStreaming;
  
  # Helper utility for launching Steam games from Sunshine
  # This works around Sunshine's security wrapper that prevents Steam from launching
  # Examples:
  #   steam-run-url steam://rungameid/1086940  # Start Baldur's Gate 3
  #   steam-run-url steam://open/bigpicture    # Start Steam Big Picture
  #   steam-run-url steam://open/gamepadui     # Start Steam Deck UI
  steam-run-url = pkgs.writeShellApplication {
    name = "steam-run-url";
    text = ''
      echo "$1" > "/run/user/$(id --user)/steam-run-url.fifo"
    '';
    runtimeInputs = [
      pkgs.coreutils
    ];
  };

  # Helper to launch Steam and wait for it to exit
  # This ensures Sunshine properly tracks the Steam process
  steam-launch-and-wait = pkgs.writeShellApplication {
    name = "steam-launch-and-wait";
    text = ''
      set -euo pipefail
      
      # Launch Steam with the provided URL
      steam "$1" &
      STEAM_PID=$!
      
      # Wait for Steam process to fully start
      sleep 3
      
      # Monitor Steam process - exit when it's gone
      while kill -0 "$STEAM_PID" 2>/dev/null; do
        sleep 1
      done
    '';
    runtimeInputs = [
      pkgs.coreutils
      pkgs.procps
    ];
  };
  
  # FIFO listener service using Python for robust message handling
  steam-fifo-listener = pkgs.writers.writePython3 "steam-fifo-listener" {
    libraries = [ ];
  } ''
    # Steam FIFO listener for Sunshine
    import os
    import subprocess
    import sys
    from pathlib import Path


    def main():
        # Use XDG_RUNTIME_DIR for FIFO location
        runtime_dir = os.getenv('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')
        fifo_path = Path(runtime_dir) / 'steam-run-url.fifo'

        print(f"Creating FIFO at {fifo_path}", file=sys.stderr)

        try:
            # Create FIFO if it doesn't exist
            if fifo_path.exists():
                fifo_path.unlink()
            os.mkfifo(fifo_path, 0o600)

            print(f"Listening for Steam URLs on {fifo_path}...", file=sys.stderr)

            # Open FIFO in read mode and process messages
            while True:
                with open(fifo_path, 'r') as fifo:
                    for line in fifo:
                        url = line.strip()
                        if not url:
                            continue

                        print(f"Received URL: {url}", file=sys.stderr)

                        try:
                            # Launch Steam with the URL
                            subprocess.Popen(
                                ['steam', url],
                                start_new_session=True,
                                stdout=subprocess.DEVNULL,
                                stderr=subprocess.DEVNULL
                            )
                            print(f"Launched Steam with: {url}", file=sys.stderr)
                        except Exception as e:
                            print(f"Error launching Steam: {e}", file=sys.stderr)
        finally:
            if fifo_path.exists():
                fifo_path.unlink()


    if __name__ == '__main__':
        main()
  '';
in {
  options.services.sunshineStreaming = {
    enable = mkEnableOption "Enable Sunshine streaming with Steam workaround";
    
    hostName = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = "The name of this host as seen in Moonlight";
    };
    
    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to open the firewall for Sunshine";
    };
    
    autoStart = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to start Sunshine automatically on login";
    };
    
    user = mkOption {
      type = types.str;
      default = "rea";
      description = "The user to configure Sunshine for";
    };
    
    outputName = mkOption {
      type = types.str;
      default = "0";
      description = "Wayland output name (0 for X11 display number)";
    };
    
    cudaSupport = mkOption {
      type = types.bool;
      default = true;
      description = "Enable CUDA/NVENC support for hardware encoding";
    };
  };
  
  config = mkIf cfg.enable {
    # System-level Sunshine configuration
    security.wrappers.sunshine = {
      source = "${
        if cfg.cudaSupport
        then pkgs.sunshine.override { 
          cudaSupport = true; 
          cudaPackages = pkgs.cudaPackages; 
        }
        else pkgs.sunshine
      }/bin/sunshine";
      capabilities = "cap_sys_admin+p";
      owner = "root";
      group = "root";
    };
    
    # Firewall configuration
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [
        47984  # HTTPS
        47989  # HTTP
        47990  # Web UI
        48010  # Admin
      ];
      allowedUDPPortRanges = [
        { from = 47998; to = 48000; }  # Video/audio streaming
      ];
    };
    
    # Home Manager configuration for the specified user
    home-manager.users.${cfg.user} = {
      # Install helper scripts
      home.packages = [
        steam-run-url
        steam-launch-and-wait
      ];
      
      # Sunshine apps configuration
      xdg.configFile."sunshine/apps.json".text = builtins.toJSON {
        env = {
          PATH = "$(PATH):$(HOME)/.local/bin";
        };
        apps = [
          {
            name = "Desktop";
            image-path = "desktop.png";
          }
          {
            name = "Steam Big Picture";
            # Use cmd to track the process properly
            cmd = "${lib.getExe steam-launch-and-wait} steam://open/bigpicture";
            # Close Big Picture when stream ends
            undo = "${pkgs.procps}/bin/pkill -f 'steam.*bigpicture'";
            image-path = "steam.png";
          }
        ];
      };
      
      # FIFO listener systemd service
      systemd.user.services.steam-run-url = {
        Unit = {
          Description = "Steam URL FIFO listener for Sunshine";
          After = [ "graphical-session.target" ];
        };
        
        Service = {
          Type = "simple";
          ExecStart = "${steam-fifo-listener}";
          Restart = "always";
          RestartSec = "3";
          Environment = [
            "PATH=/run/wrappers/bin:/etc/profiles/per-user/${cfg.user}/bin:/run/current-system/sw/bin"
          ];
        };
        
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
      
      # Sunshine user service
      systemd.user.services.sunshine = {
        Unit = {
          Description = "Sunshine self-hosted game streaming";
          After = [ "graphical-session.target" "steam-run-url.service" ];
          PartOf = [ "graphical-session.target" ];
        };
        
        Service = {
          Type = "simple";
          ExecStart = "/run/wrappers/bin/sunshine";
          Restart = "on-failure";
          RestartSec = "5";
          Environment = [
            "LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/opengl-driver-32/lib"
          ];
        };
        
        Install = {
          WantedBy = mkIf cfg.autoStart [ "graphical-session.target" ];
        };
      };
    };
  };
}
