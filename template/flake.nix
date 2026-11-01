{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    notes.url = "github:rizesql/typst-notes";
  };

  outputs =
    inputs@{ flake-parts, notes, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem =
        { pkgs, ... }:
        {
          devShells.default = notes.lib.mkShell {
            inherit pkgs;
            name = "course";
          };
        };
    };
}
