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
      system = "x86_64-linux";
      systempkgs = import nixpkgs { inherit system; };
      helpers = import ./helpers.nix {
        inherit nixpkgs;
        inherit nixos-generators;
      };
      pkgs = systempkgs;
    in {
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          shfmt
          nixfmt
          bc
          ffmpeg
          parallel
          multitail
        ];
      };

      packages.${system} = helpers.transcodersDeclaration;
      formatter.${system} = pkgs.nixfmt;
    };
}
