{ nixpkgs, nixos-generators, ... }:

let
  lib = nixpkgs.lib;
  pkgs = import nixpkgs { system = "x86_64-linux"; };

  source = sourcescript: {
    system = "x86_64-linux";
    inherit pkgs;
    format = "iso";
    modules = [
      (import ./service.nix {
        inherit pkgs;
        sourcescript = sourcescript;
      })
    ];
  };

  source-vm = sourcescript: {
    system = "x86_64-linux";
    inherit pkgs;
    format = "vm";
    modules = [
      (import ./service.nix {
        inherit pkgs;
        sourcescript = sourcescript;
      })
      {
        virtualisation.cores = 12;
        virtualisation.memorySize = 8096;
      }
    ];
  };

  source-script = sourcescript:
    (pkgs.mkShellNoCC {
      packages =
        [
          (pkgs.writeShellApplication {
            name = "transcode-script.sh";
            runtimeInputs = with pkgs; [ ffmpeg parallel bc exiftool ];
            text = import ./transcoder.nix nixpkgs.lib sourcescript;
          })
        ];
    });

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
    {
      name = "transcode-${transcoder.name}-script";
      value = source-script transcoder.path;
    }
  ];

in {
  transcodersDeclaration = (builtins.listToAttrs
    (lib.flatten (map transcoderToDeclaration listTranscoders)));
}
