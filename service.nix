{ pkgs, sourcescript, ... }:
let
  transcode-script = pkgs.writeShellApplication {
    name = "transcode-script.sh";
    runtimeInputs = with pkgs; [ ffmpeg parallel bc ];
    text = builtins.readFile sourcescript;
  };
  logs-script = pkgs.writeShellApplication {
    name = "logs-script.sh";
    runtimeInputs = with pkgs; [ tmux multitail btop ];
    text = builtins.readFile ./logs.sh;
  };
in {
  #system.stateVersion = "25.11";
  time.timeZone = "Europe/Paris";

  services.ttyd = {
    enable = true;
    writeable = false; # set to true if you whishes to interract (security breach if exposed !)
    port = 80;
    writeable = false;
    entrypoint = [ "${logs-script}/bin/logs-scripts.sh" ];
  };

  services.getty.autologinUser = "root";

  systemd.services.transcode = {
    description = "Run script when network is online";
    wants = [ "network-online.target" ];
    after = [ "network.target" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${transcode-script}/bin/transcode-script.sh";
    };
  };

  fileSystems."/transcode" = import ./filesystem.nix;
}
