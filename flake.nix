{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nixos-generators,
      ...
    }:
    let
      systempkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      devShells.x86_64-linux.default = systempkgs.mkShellNoCC {
        packages = with systempkgs; [
          shfmt
          nixfmt
          bc
          ffmpeg
          parallel
          multitail
        ];
      };

      packages.x86_64-linux =
        let
          pkgs = systempkgs;
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
        in
        {
          transcode-intel = nixos-generators.nixosGenerate (source ./transcoders/intel.sh);
          transcode-nvidia = nixos-generators.nixosGenerate (source ./transcoders/nvidia.sh);
          transcode-cpu = nixos-generators.nixosGenerate (source ./transcoders/cpu.sh);
        };
    };
}
