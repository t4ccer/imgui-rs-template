{
  description = "cgrs";
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

          packages = { };

          devShells.default = pkgs.mkShell {
            shellHook = ''
              ${config.pre-commit.installationScript}
              PATH=$PATH:$(pwd)/target/release
            '';

            nativeBuildInputs = [
              pkgs.clang
              pkgs.cmake
              pkgs.pkgsCross.mingwW64.stdenv.cc
              pkgs.pkgsStatic.stdenv.cc
              pkgs.wineWow64Packages.unstableFull
              rustToolchain
              pkgs.python3
              pkgs.pkg-config
            ];

            buildInputs = [
              # pkgs.clang.libc
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
            ];

            env = {
              CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS = "-L${pkgs.pkgsCross.mingwW64.windows.mingw_w64_pthreads}/lib";
              CC_x86_64_pc_windows_gnu = "x86_64-w64-mingw32-gcc";
              CXX_x86_64_pc_windows_gnu = "x86_64-w64-mingw32-g++";
              CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER = "x86_64-w64-mingw32-gcc";

              # CC_x86_64_unknown_linux_musl = "x86_64-unknown-linux-musl-gcc";
              # CXX_x86_64_unknown_linux_musl = "x86_64-unknown-linux-musl-g++";
              # CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER = "x86_64-unknown-linux-musl-gcc";

              LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
              LD_LIBRARY_PATH = lib.makeLibraryPath [
                pkgs.libGL
                pkgs.xorg.libX11
                pkgs.xorg.libXrandr
                pkgs.xorg.libXinerama
                pkgs.xorg.libXcursor
                pkgs.xorg.libXi
                pkgs.libxkbcommon
              ];
            };
          };
        };
    };
}
