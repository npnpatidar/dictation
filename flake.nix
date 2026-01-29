{
  description = "nerd-dictation packaged as a Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};

        nerd-dictation = pkgs.python3Packages.buildPythonApplication {
          pname = "nerd-dictation";
          version = "unstable-2025-10-10";

          src = pkgs.fetchFromGitHub {
            owner = "ideasman42";
            repo = "nerd-dictation";
            rev = "41f372789c640e01bb6650339a78312661530843";
            sha256 = "sha256-xjaHrlJvk8bNvWp1VE4EAHi2VJlAutBxUgWB++3Qo+s=";
          };

          propagatedBuildInputs = with pkgs.python3Packages; [
            vosk
          ];

          nativeBuildInputs = [
            pkgs.makeWrapper
          ];

          postInstall = ''
            wrapProgram $out/bin/nerd-dictation \
              --prefix PATH : ${pkgs.lib.makeBinPath [
              pkgs.sox
              pkgs.wtype # Wayland
              pkgs.xdotool # X11 fallback
            ]}
          '';

          doCheck = false;

          meta = with pkgs.lib; {
            description = "Offline speech-to-text dictation using Vosk";
            license = licenses.gpl3Only;
            platforms = platforms.linux;
          };
        };
      in {
        packages.default = nerd-dictation;

        apps.default = {
          type = "app";
          program = "${nerd-dictation}/bin/nerd-dictation";
        };

        devShells.default = pkgs.mkShell {
          packages = [
            nerd-dictation
            pkgs.vosk-api
            pkgs.sox
            pkgs.wtype
          ];
        };
      }
    );
}
