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

        # Vosk language models
        vosk-model-en-us = pkgs.stdenv.mkDerivation rec {
          pname = "vosk-model-small-en-us";
          version = "0.15";

          src = pkgs.fetchzip {
            url = "https://alphacephei.com/vosk/models/vosk-model-small-en-us-${version}.zip";
            sha256 = "sha256-7l+bc0sqDJZ8ThsU4J7tffsWClLQkVeuBV6n84zU82A=";
            stripRoot = false;
          };

          installPhase = ''
            mkdir -p $out
            cp -r * $out/
          '';
        };

        vosk-model-de = pkgs.stdenv.mkDerivation rec {
          pname = "vosk-model-small-de";
          version = "0.15";

          src = pkgs.fetchzip {
            url = "https://alphacephei.com/vosk/models/vosk-model-small-de-${version}.zip";
            sha256 = "sha256-3acw1sfI4Y2xptM49bGMKZNBYd9wXflHRVqr+q9BeWE=";
            stripRoot = false;
          };

          installPhase = ''
            mkdir -p $out
            cp -r * $out/
          '';
        };

        vosk = pkgs.python3Packages.buildPythonPackage rec {
          pname = "vosk";
          version = "0.3.45";
          format = "wheel";

          src = pkgs.python3Packages.fetchPypi {
            inherit pname version format;
            dist = "py3";
            python = "py3";
            abi = "none";
            platform = if pkgs.stdenv.isAarch64 then "manylinux2014_aarch64" else "manylinux_2_12_x86_64.manylinux2010_x86_64";
            sha256 = if pkgs.stdenv.isAarch64 then "sha256-VO+0fdiQ5UTp4g8DFkE6zsf4aA0E7AlcYUCrTnAmJwQ=" else "sha256-JeAlCTxDmdcnj1Q1aO2MxUYKw6S/SMI2c6zh4l0mYZ8=";
          };

          nativeBuildInputs = [
            pkgs.autoPatchelfHook
          ];

          buildInputs = [
            pkgs.stdenv.cc.cc.lib
            pkgs.gcc-unwrapped.lib
          ];

          propagatedBuildInputs = with pkgs.python3Packages; [
            cffi
            requests
            srt
            tqdm
            websockets
          ];

          doCheck = false;

          # Disable import check since it needs the runtime libraries
          dontUsePythonImportsCheck = true;
        };

        nerd-dictation = pkgs.python3Packages.buildPythonApplication {
          pname = "nerd-dictation";
          version = "unstable-2025-10-10";

          src = pkgs.fetchFromGitHub {
            owner = "ideasman42";
            repo = "nerd-dictation";
            rev = "41f372789c640e01bb6650339a78312661530843";
            sha256 = "sha256-xjaHrlJvk8bNvWp1VE4EAHi2VJlAutBxUgWB++3Qo+s=";
          };

          sourceRoot = "source/package/python";

          format = "setuptools";

          propagatedBuildInputs = [
            vosk
          ];

          nativeBuildInputs = [
            pkgs.makeWrapper
          ];

          postInstall = ''
            # Create wrapper script that defaults to WTYPE for Wayland
            mv $out/bin/nerd-dictation $out/bin/.nerd-dictation-unwrapped
            
            cat > $out/bin/nerd-dictation << 'WRAPPER_EOF'
#!/bin/bash
# Auto-detect if --simulate-input-tool is not specified and default to WTYPE
args=("$@")
has_simulate_input=false

for arg in "$@"; do
  if [[ "$arg" == --simulate-input-tool* ]]; then
    has_simulate_input=true
    break
  fi
done

if [ "$has_simulate_input" = false ] && [ "$1" = "begin" ]; then
  # Default to WTYPE for Wayland
  args=("$1" --simulate-input-tool=WTYPE "''${@:2}")
fi

exec "$(dirname "$0")/.nerd-dictation-unwrapped" "''${args[@]}"
WRAPPER_EOF
            
            chmod +x $out/bin/nerd-dictation
            
            wrapProgram $out/bin/.nerd-dictation-unwrapped \
              --prefix PATH : ${pkgs.lib.makeBinPath [
              pkgs.sox
              pkgs.wtype # Wayland
              pkgs.xdotool # X11 fallback
            ]}
            
            # Install language models
            mkdir -p $out/share/nerd-dictation/models
            ln -s ${vosk-model-en-us} $out/share/nerd-dictation/models/en-us
            ln -s ${vosk-model-de} $out/share/nerd-dictation/models/de
            
            # Install helper script as 'dictation'
            install -Dm755 ${./dictation-helper.sh} $out/bin/dictation
          '';

          doCheck = false;

          meta = with pkgs.lib; {
            description = "Offline speech-to-text dictation using Vosk";
            license = licenses.gpl3Only;
            platforms = platforms.linux;
          };
        };
      in {
        packages = {
          default = nerd-dictation;
          nerd-dictation = nerd-dictation;
          vosk-model-en-us = vosk-model-en-us;
          vosk-model-de = vosk-model-de;
        };

        apps = {
          default = {
            type = "app";
            program = "${nerd-dictation}/bin/dictation";
          };
          dictation = {
            type = "app";
            program = "${nerd-dictation}/bin/dictation";
          };
          nerd-dictation = {
            type = "app";
            program = "${nerd-dictation}/bin/nerd-dictation";
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [
            nerd-dictation
            pkgs.sox
            pkgs.wtype
          ];
        };
      }
    );
}
