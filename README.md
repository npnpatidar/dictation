# nerd-dictation Nix Flake

Offline speech-to-text dictation for Linux using Vosk, packaged as a Nix flake with automatic Wayland support.

## Features

- ✅ Automatic WTYPE integration for Wayland
- ✅ Works with your system's audio (PipeWire or PulseAudio)
- ✅ Pre-bundled en-US and de-DE language models
- ✅ Easy-to-use helper script
- ✅ Background operation by default
- ✅ Ready to use after `nix build` or `nix run`

## Requirements

- A working audio system (PipeWire or PulseAudio)
  - Most modern NixOS systems have this already
  - The flake uses your system's audio recording tool (`parec`, `pw-cat`, or `sox`)

## Quick Start

### Option 1: Use with `nix run` (no installation needed)

```bash
# Start English dictation
nix run . -- en

# Start German dictation
nix run . -- de

# Check status
nix run . -- status

# Stop dictation
nix run . -- stop

# Test (30 seconds)
nix run . -- test
```

### Option 2: Build and use locally

```bash
# Build
nix build

# Start English dictation
./result/bin/dictation en

# Start German dictation
./result/bin/dictation de

# Stop dictation
./result/bin/dictation stop
```

### Option 3: Install to your profile

```bash
# Install
nix profile install .

# Use from anywhere
dictation en
dictation stop
```

## How to Use

1. **Start dictation**: `nix run . -- en` (or `de` for German)
2. **Click in a text editor** to focus it
3. **Speak clearly** into your microphone
4. **Text appears automatically** at your cursor!
5. **Stop**: `nix run . -- stop`

## Available Commands

| Command | Description |
|---------|-------------|
| `en` or `english` | Start English dictation (background) |
| `de` or `german` | Start German dictation (background) |
| `stop` or `end` | Stop dictation |
| `status` | Check if dictation is running |
| `test` | Run 30-second test (foreground) |

## Additional Options

Pass extra options after the command:

```bash
# Continuous mode (keeps listening between pauses)
nix run . -- en --continuous

# Set custom timeout
nix run . -- en --timeout=60

# Verbose output
nix run . -- en --verbose=1
```

## Direct Usage (without helper)

You can also use nerd-dictation directly:

```bash
# Using nix run
nix run .#nerd-dictation -- begin \
  --vosk-model-dir=$(nix build --print-out-paths --no-link .)/share/nerd-dictation/models/en-us/vosk-model-small-en-us-0.15

# After nix build
./result/bin/nerd-dictation begin \
  --vosk-model-dir=./result/share/nerd-dictation/models/en-us/vosk-model-small-en-us-0.15
```

## Flake Structure

```
packages:
  - default: nerd-dictation (main package)
  - nerd-dictation: The dictation tool
  - vosk-model-en-us: English language model
  - vosk-model-de: German language model

apps:
  - default: dictation (helper script)
  - dictation: Helper script
  - nerd-dictation: Direct access to nerd-dictation binary

binaries:
  - dictation: User-friendly wrapper script ⭐
  - nerd-dictation: Main dictation tool (auto-uses WTYPE)
```

## Troubleshooting

### "No text found in the audio"
- Speak louder and more clearly
- Ensure microphone isn't muted
- Check microphone works: `parecord test.wav` (Ctrl+C to stop)
- Minimize background noise

### Text not being typed
- Make sure a text field has focus (cursor blinking)
- WTYPE is automatically used for Wayland ✓
- Try the test mode: `nix run . -- test`

### Speech not recognized well
- Speak in complete sentences
- The small models have limited vocabulary
- Consider using larger models (replace in flake)
- Avoid background noise

## Models Included

- **en-US**: vosk-model-small-en-us-0.15 (~40MB)
- **de-DE**: vosk-model-small-de-0.15 (~45MB)

Models are automatically downloaded during build and cached by Nix.

## Development

```bash
# Enter development shell
nix develop

# Build
nix build

# Check flake
nix flake check
```

## License

- nerd-dictation: GPL-3.0
- Vosk models: Apache 2.0

## Credits

- [nerd-dictation](https://github.com/ideasman42/nerd-dictation) by ideasman42
- [Vosk](https://alphacephei.com/vosk/) speech recognition toolkit
