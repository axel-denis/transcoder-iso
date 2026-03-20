{
  device = "//${fsAddress}"; # ex 192.168.0.200/transcoding
  fsType = "cifs";
  options = [
    "username=${builtins.getEnv "fsUsername"}"
    "password=${builtins.getEnv "fsPassword"}"
    "mfsymlinks" # allows for local symlinks
  ];
}
