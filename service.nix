{ pkgs, sourcescript, ... }:
let
  transcode-script = pkgs.writeShellApplication {
    name = "transcode-script.sh";
    runtimeInputs = with pkgs; [ ffmpeg parallel bc exiftool ];
    text = import ./transcoder.nix pkgs.lib sourcescript;
  };
  logs-script = pkgs.writeShellApplication {
    name = "logs-script.sh";
    runtimeInputs = with pkgs; [ tmux multitail btop ];
    text = builtins.readFile ./logs.sh;
  };
in {
  system.stateVersion = "25.11";
  time.timeZone = "Europe/Paris";

  services.ttyd = {
    enable = true;
    writeable =
      false; # set to true if you whishes to interract (security breach if exposed !)
    port = 80;
    entrypoint = [ "${logs-script}/bin/logs-script.sh" ];
  };

  networking.firewall.allowedTCPPorts = [ 80 ];

  services.getty.autologinUser = "root";

  systemd.services.transcode = {
    description = "Run script when network is online";
    wants = [ "network-online.target" ];
    requires = [ "network.target" "network-online.target" "transcoding.mount" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${transcode-script}/bin/transcode-script.sh";
    };
  };

  #fileSystems."/transcode" = import ./filesystem.nix;

  # Required for systemd to be able to execute mount.cifs
  environment.systemPackages = [ pkgs.cifs-utils ];

  systemd.mounts = [{
    description = "CIFS Mount for Transcodings";
    what = "//192.168.0.101/transcodings";
    where = "/transcoding";
    type = "cifs";
    options = "username=${builtins.getEnv "fsUsername"},password=${builtins.getEnv "fsPassword"},_netdev,x-systemd.after=network-online.target,x-systemd.mount-timeout=30";
    requires = [ "network-online.target" "network.target" ];
    after = [ "network-online.target" "network.target" ];
  }];

  systemd.automounts = [{
    description = "Automount for Transcodings";
    where = "/transcoding";
    requires = [ "network-online.target" ];
    after = [ "network-online.target" "network.target" ];
    wantedBy = [ "multi-user.target" ];
  }];
}
