{
  description = "imgui-rs-template";
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
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
    };
  };
  outputs = inputs @ { self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.pre-commit-hooks-nix.flakeModule
      ];

      systems = inputs.nixpkgs.lib.systems.flakeExposed;

      perSystem =
        { config
        , self'
        , inputs'
        , pkgs
        , lib
        , system
        , ...
        }:
        let
          globalPkgs = pkgs;

          rustToolchain = pkgs.rust-bin.fromRustupToolchain {
            channel = "stable";
            components = [ "rust-analyzer" "rust-src" "rustfmt" "rustc" "cargo" ];
            targets = [
              "x86_64-unknown-linux-gnu"
              "x86_64-unknown-linux-musl"
              "x86_64-pc-windows-gnu"
            ];
          };

          pythonToolchain = "python311";
        in
        {
          _module.args.pkgs = import self.inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.rust-overlay.overlays.rust-overlay
            ];
          };

          pre-commit.settings = {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              rustfmt.enable = true;
            };
            tools = {
              rustfmt = lib.mkForce rustToolchain;
            };
          };

          packages =
            let
              mkDemo = pkgs: pkgs.rustPlatform.buildRustPackage
                {
                  name = "imgui-rs-template";

                  src = ./.;
                  cargoLock.lockFile = ./Cargo.lock;

                  nativeBuildInputs =
                    pkgs.lib.optional pkgs.stdenv.targetPlatform.isUnix pkgs.makeWrapper;

                  buildInputs = [
                    pkgs.libgcc
                    pkgs.freetype
                    pkgs.SDL2
                  ] ++ pkgs.lib.optionals pkgs.stdenv.targetPlatform.isUnix [
                    pkgs.mesa
                    pkgs.wayland
                    pkgs.xorg.libX11
                    pkgs.xorg.libXcursor
                    pkgs.xorg.libXi
                    pkgs.xorg.libXinerama
                    pkgs.xorg.libXrandr
                  ] ++ pkgs.lib.optionals pkgs.stdenv.targetPlatform.isWindows [
                    pkgs.windows.mingw_w64_pthreads
                  ];
                } // pkgs.lib.optionalAttrs pkgs.stdenv.targetPlatform.isWindows {
                env.DXSDK_DIR = "${pkgs.directx-headers}/include";
              };
            in
            {
              demo-linux = mkDemo pkgs;
              demo-windows = mkDemo pkgs.pkgsCross.mingwW64;
            };

          devShells.default = pkgs.mkShell {
            shellHook = ''
              ${config.pre-commit.installationScript}
              PATH=$PATH:$(pwd)/target/release
            '';

            nativeBuildInputs = [
              pkgs.wineWow64Packages.unstableFull
              rustToolchain
            ];

            buildInputs = [
              pkgs.glfw
              pkgs.mesa
              pkgs.wayland
              pkgs.xorg.libX11
              pkgs.xorg.libXcursor
              pkgs.xorg.libXi
              pkgs.xorg.libXinerama
              pkgs.xorg.libXrandr
              pkgs.libgcc
              pkgs.freetype
              pkgs.SDL2
            ];
          };
        };
    };
}
