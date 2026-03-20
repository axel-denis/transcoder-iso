{ nixpkgs, nixos-generators, ... }:

let
  lib = nixpkgs.lib;
  systempkgs = import nixpkgs { system = "x86_64-linux"; };

  source = sourcescript: {
    system = "x86_64-linux";
    pkgs = systempkgs;
    format = "iso";
    modules = [
      (import ./service.nix {
        pkgs = systempkgs;
        sourcescript = sourcescript;
      })
    ];
  };

  source-vm = sourcescript: {
    system = "x86_64-linux";
    pkgs = systempkgs;
    format = "vm";
    modules = [
      (import ./service.nix {
        pkgs = systempkgs;
        sourcescript = sourcescript;
      })
      {
        virtualisation.cores = 12;
        virtualisation.memorySize = 8096;
      }
    ];
  };

  listTranscodersScripts = (lib.filesystem.listFilesRecursive ./transcoders/.);

  extractTranscoderNameAndPath = path: {
    name = (lib.removeSuffix ".sh" (builtins.baseNameOf path));
    inherit path;
  };

  listTranscoders = (map extractTranscoderNameAndPath listTranscodersScripts);

  transcoderToDeclaration = transcoder: [
    {
      name = "transcode-${transcoder.name}";
      value = nixos-generators.nixosGenerate (source transcoder.path);
    }
    {
      name = "transcode-${transcoder.name}-vm";
      value = nixos-generators.nixosGenerate (source-vm transcoder.path);
    }
  ];

in {
  transcodersDeclaration = (builtins.listToAttrs
    (lib.flatten (map transcoderToDeclaration listTranscoders)));
}
