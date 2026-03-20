{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixos-generators, ... }:
    let
      systempkgs = import nixpkgs { system = "x86_64-linux"; };
      helpers = import ./helpers.nix {
        inherit nixpkgs;
        inherit nixos-generators;
      };
    in {
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

      packages.x86_64-linux = helpers.transcodersDeclaration;
    };
}
