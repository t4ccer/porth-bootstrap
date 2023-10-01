{
  description = "general-template";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ self, nixpkgs, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.pre-commit-hooks-nix.flakeModule
      ];

      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem = { config, self', pkgs, ... }:
        let
          mkPorth = with pkgs; callPackage (import ./porth.nix) { };
        in
        {
          pre-commit.settings = {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
            };
          };

          devShells.default = pkgs.mkShell {
            shellHook = config.pre-commit.installationScript;
            nativeBuildInputs = [
              pkgs.fasm
              self'.packages.porth
            ];
          };

          packages = {
            porth = mkPorth.porth;
            default = self'.packages.porth;
            test = mkPorth.buildPorthApplication {
              name = "test";
              src = ./.;
              main = "test.porth";
            };
          };
        };
    };
}
