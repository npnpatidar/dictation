# nerd-dictation Usage Guide

## ✅ What was fixed

The flake now:
- ✅ Automatically uses **WTYPE** for Wayland (no need to specify it manually)
- ✅ Includes **en-US** and **de-DE** language models
- ✅ Models are pre-downloaded and ready to use

## Quick Start

### Option 1: Use the helper script (easiest)

The script now runs dictation in the **background** automatically!

```bash
# Start English dictation (runs in background)
dictation en

# Check if it's running
dictation status

# Stop dictation
dictation stop

# Start German dictation (runs in background)
dictation de

# Test mode (30 seconds, foreground)
dictation test
```

**Typical workflow:**
```bash
# 1. Start dictation
dictation en

# 2. Click in a text editor
# 3. Speak into your microphone
# 4. Text appears automatically!

# 5. When done, stop it
dictation stop
```

### Option 2: Use nerd-dictation directly

**English (background):**
```bash
./result/bin/nerd-dictation begin \
  --vosk-model-dir=./result/share/nerd-dictation/models/en-us/vosk-model-small-en-us-0.15 &
```

**German (background):**
```bash
./result/bin/nerd-dictation begin \
  --vosk-model-dir=./result/share/nerd-dictation/models/de/vosk-model-small-de-0.15 &
```

**Stop:**
```bash
./result/bin/nerd-dictation end
```

**Note:** Add `&` at the end to run in background, or omit it to run in foreground.

## How it works

1. **Start dictation** with one of the commands above
2. **Click in a text editor or text field** to give it focus
3. **Speak clearly** into your microphone
4. **Text will be typed automatically** where your cursor is
5. **Stop** when done with `./result/bin/nerd-dictation end` or Ctrl+C

## Useful options

```bash
# Continuous mode (keeps listening between pauses)
./result/bin/nerd-dictation begin \
  --vosk-model-dir=./result/share/nerd-dictation/models/en-us/vosk-model-small-en-us-0.15 \
  --continuous

# Auto-stop after 30 seconds of silence
./result/bin/nerd-dictation begin \
  --vosk-model-dir=./result/share/nerd-dictation/models/en-us/vosk-model-small-en-us-0.15 \
  --timeout=30

# Verbose output (useful for debugging)
./result/bin/nerd-dictation begin \
  --vosk-model-dir=./result/share/nerd-dictation/models/en-us/vosk-model-small-en-us-0.15 \
  --verbose=1

# Run in background
./result/bin/nerd-dictation begin \
  --vosk-model-dir=./result/share/nerd-dictation/models/en-us/vosk-model-small-en-us-0.15 &
```

## Installing system-wide

```bash
# Install to your Nix profile
nix profile install .

# Then use from anywhere
nerd-dictation begin \
  --vosk-model-dir=$(nix build --print-out-paths --no-link .)/share/nerd-dictation/models/en-us/vosk-model-small-en-us-0.15
```

## Troubleshooting

**"No text found in the audio"**
- Speak louder and more clearly
- Check your microphone is working: `parecord test.wav` (Ctrl+C to stop)
- Ensure your microphone isn't muted

**Text not being typed**
- Make sure a text field has focus (cursor is blinking)
- WTYPE is now automatically used for Wayland ✓

**Speech not recognized**
- Speak in complete sentences
- Avoid background noise
- The small models have limited vocabulary
