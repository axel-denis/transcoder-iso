{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixos-generators, ... }:
    let pkgs = import nixpkgs { system = "x86_64-linux"; };
    in {
      devShells.x86_64-linux.default = pkgs.mkShellNoCC {
        packages = with pkgs; [ shfmt nixfmt bc ffmpeg parallel multitail ];
      };

      packages.x86_64-linux = let
        pkgs = pkgs;
        source = sourcescript: {
          system = "x86_64-linux";
          pkgs = pkgs;
          format = "iso";
          modules = [
            (import ./service.nix {
              pkgs = pkgs;
              sourcescript = sourcescript;
            })
          ];
        };
      in {
        transcode-intel =
          nixos-generators.nixosGenerate (source ./transcoders/intel.sh);
        transcode-nvidia =
          nixos-generators.nixosGenerate (source ./transcoders/nvidia.sh);
        transcode-cpu =
          nixos-generators.nixosGenerate (source ./transcoders/cpu.sh);
      };
    };
}
