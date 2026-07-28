{
  description = "nerd-dictation packaged as a Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    ,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

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

        vosk-model-hi = pkgs.stdenv.mkDerivation rec {
          pname = "vosk-model-small-hi";
          version = "0.22";

          src = pkgs.fetchzip {
            url = "https://alphacephei.com/vosk/models/vosk-model-small-hi-${version}.zip";
            sha256 = "sha256-1c2pd86m1bdj8j5xdlp6a8shjz6ic53xqncjrdjzzg06hmz3i6nq=";
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
            # Rename original binary
            mv $out/bin/nerd-dictation $out/bin/.nerd-dictation-original
            
            # Create single wrapper that handles both PATH and WTYPE defaults
            makeWrapper $out/bin/.nerd-dictation-original $out/bin/nerd-dictation \
              --prefix PATH : ${pkgs.lib.makeBinPath [
              pkgs.sox
              pkgs.wtype
              pkgs.xdotool
            ]} \
              --run 'if [[ "$1" == "begin" ]] && ! [[ " $* " =~ " --simulate-input-tool" ]]; then set -- "$1" --simulate-input-tool=WTYPE "''${@:2}"; fi'
            
            # Install language models
            mkdir -p $out/share/nerd-dictation/models
            ln -s ${vosk-model-en-us} $out/share/nerd-dictation/models/en-us
            ln -s ${vosk-model-hi} $out/share/nerd-dictation/models/hi
          '';

          doCheck = false;

          meta = with pkgs.lib; {
            description = "Offline speech-to-text dictation using Vosk";
            license = licenses.gpl3Only;
            platforms = platforms.linux;
          };
        };

        # Helper script for easy usage
        dictation = pkgs.writeShellScriptBin "dictation" ''
          MODEL_EN="${nerd-dictation}/share/nerd-dictation/models/en-us/vosk-model-small-en-us-0.15"
          MODEL_HI="${nerd-dictation}/share/nerd-dictation/models/hi/vosk-model-small-hi-0.22"
          NERD_DICTATION="${nerd-dictation}/bin/nerd-dictation"

          # Auto-detect available audio input method
          detect_audio_input() {
            if command -v pw-cat >/dev/null 2>&1; then
              echo "PW-CAT"
            elif command -v parec >/dev/null 2>&1; then
              echo "PAREC"
            elif command -v sox >/dev/null 2>&1; then
              echo "SOX"
            else
              echo ""
            fi
          }

          AUDIO_INPUT=$(detect_audio_input)
          
          if [ -z "$AUDIO_INPUT" ]; then
            echo "Error: No audio recording tool found!"
            echo ""
            echo "Please ensure one of the following is available on your system:"
            echo "  - PipeWire (provides pw-cat)"
            echo "  - PulseAudio (provides parec)"
            echo "  - SoX (provides sox)"
            echo ""
            echo "On NixOS, most systems already have PipeWire or PulseAudio."
            exit 1
          fi

          case "$1" in
            en|english)
              echo "Starting English dictation in background..."
              echo "Using audio input: $AUDIO_INPUT"
              "$NERD_DICTATION" begin --vosk-model-dir="$MODEL_EN" --input="$AUDIO_INPUT" "''${@:2}" &
              sleep 2
              if pgrep -f "nerd-dictation.*begin" > /dev/null; then
                echo "✓ Dictation is running in background"
                echo ""
                echo "Speak into your microphone. Text will be typed where your cursor is."
                echo ""
                echo "To stop: dictation stop"
              else
                echo "✗ Failed to start dictation"
              fi
              ;;
            hi|hindi)
              echo "Starting Hindi dictation in background..."
              echo "Using audio input: $AUDIO_INPUT"
              "$NERD_DICTATION" begin --vosk-model-dir="$MODEL_HI" --input="$AUDIO_INPUT" "''${@:2}" &
              sleep 2
              if pgrep -f "nerd-dictation.*begin" > /dev/null; then
                echo "✓ Dictation is running in background"
                echo ""
                echo "Speak into your microphone. Text will be typed where your cursor is."
                echo ""
                echo "To stop: dictation stop"
              else
                echo "✗ Failed to start dictation"
              fi
              ;;
            stop|end)
              if pgrep -f "nerd-dictation.*begin" > /dev/null; then
                echo "Stopping dictation..."
                "$NERD_DICTATION" end
                sleep 1
                echo "✓ Dictation stopped"
              else
                echo "No dictation process running"
              fi
              ;;
            status)
              if pgrep -f "nerd-dictation.*begin" > /dev/null; then
                echo "✓ Dictation is running"
                echo ""
                ps aux | grep -E "[n]erd-dictation.*begin" | head -3
              else
                echo "✗ Dictation is not running"
              fi
              ;;
            test)
              echo "=== Testing dictation (30 second timeout) ==="
              echo ""
              echo "Audio input method: $AUDIO_INPUT"
              echo ""
              echo "1. Click in a text editor or text field"
              echo "2. Then speak clearly into your microphone"
              echo "3. Say: 'Hello world, this is a test'"
              echo "4. The text should appear where your cursor is"
              echo ""
              echo "Starting in 3 seconds..."
              sleep 3
              "$NERD_DICTATION" begin --vosk-model-dir="$MODEL_EN" --input="$AUDIO_INPUT" --timeout=30 --verbose=1
              ;;
            *)
              echo "Usage: dictation <command> [options]"
              echo ""
              echo "Commands:"
              echo "  en|english  - Start English dictation (runs in background)"
              echo "  hi|hindi    - Start Hindi dictation (runs in background)"
              echo "  stop|end    - Stop dictation"
              echo "  status      - Check if dictation is running"
              echo "  test        - Run a 30-second test"
              echo ""
              echo "Examples:"
              echo "  dictation en                    # Start English dictation"
              echo "  dictation en --continuous       # Continuous mode"
              echo "  dictation hi                    # Start Hindi dictation"
              echo "  dictation status                # Check status"
              echo "  dictation stop                  # Stop dictation"
              echo "  dictation test                  # Test mode"
              echo ""
              echo "The text will be typed using WTYPE (Wayland) automatically."
              ;;
          esac
        '';
      in
      {
        packages = {
          default = dictation;
          dictation = dictation;
          nerd-dictation = nerd-dictation;
          vosk-model-en-us = vosk-model-en-us;
          vosk-model-hi = vosk-model-hi;
        };

        apps = {
          default = {
            type = "app";
            program = "${dictation}/bin/dictation";
          };
          dictation = {
            type = "app";
            program = "${dictation}/bin/dictation";
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
