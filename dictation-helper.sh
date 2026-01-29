#!/bin/bash

MODEL_EN="$(dirname "$0")/../share/nerd-dictation/models/en-us/vosk-model-small-en-us-0.15"
MODEL_DE="$(dirname "$0")/../share/nerd-dictation/models/de/vosk-model-small-de-0.15"
NERD_DICTATION="$(dirname "$0")/nerd-dictation"

case "$1" in
  en|english)
    echo "Starting English dictation in background..."
    "$NERD_DICTATION" begin --vosk-model-dir="$MODEL_EN" "${@:2}" &
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
  de|german|deutsch)
    echo "Starte deutsche Diktierfunktion im Hintergrund..."
    "$NERD_DICTATION" begin --vosk-model-dir="$MODEL_DE" "${@:2}" &
    sleep 2
    if pgrep -f "nerd-dictation.*begin" > /dev/null; then
      echo "✓ Diktierfunktion läuft im Hintergrund"
      echo ""
      echo "Sprechen Sie ins Mikrofon. Text wird an der Cursorposition eingegeben."
      echo ""
      echo "Zum Stoppen: dictation stop"
    else
      echo "✗ Fehler beim Starten"
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
    echo "1. Click in a text editor or text field"
    echo "2. Then speak clearly into your microphone"
    echo "3. Say: 'Hello world, this is a test'"
    echo "4. The text should appear where your cursor is"
    echo ""
    echo "Starting in 3 seconds..."
    sleep 3
    "$NERD_DICTATION" begin --vosk-model-dir="$MODEL_EN" --timeout=30 --verbose=1
    ;;
  *)
    echo "Usage: dictation <command> [options]"
    echo ""
    echo "Commands:"
    echo "  en|english  - Start English dictation (runs in background)"
    echo "  de|german   - Start German dictation (runs in background)"
    echo "  stop|end    - Stop dictation"
    echo "  status      - Check if dictation is running"
    echo "  test        - Run a 30-second test"
    echo ""
    echo "Examples:"
    echo "  dictation en                    # Start English dictation"
    echo "  dictation en --continuous       # Continuous mode"
    echo "  dictation de                    # Start German dictation"
    echo "  dictation status                # Check status"
    echo "  dictation stop                  # Stop dictation"
    echo "  dictation test                  # Test mode"
    echo ""
    echo "The text will be typed using WTYPE (Wayland) automatically."
    ;;
esac
