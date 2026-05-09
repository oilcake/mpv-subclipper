# Subclipper

`Subclipper` is a plugin on top of [mpv](https://github.com/mpv-player/mpv) that turns the video player into a portable editing station.
Mark loops (A-B repeat) while watching, save them to a file, and later process into separate clips (if needed, of course).

## Features
- Set loop points with customisable hotkeys
- Save loops to `.clp` file alongside your video (happens automatically)
- Support any number of loops per video
- Automatically load existing loops when opening a video
- Export loops to individual clips using `process.lua`

Includes convenient hotkeys for loop manipulation.

## Installation
If you keep `mpv` files in the default location, install with:
```bash
bash install.sh
```

Currently Mac and Linux only. Contributions for cross-platform support are welcome.

## Usage

While playing a video in `mpv`:
- Use hotkeys (see `main.lua`) to set loop start/end
- Loops are saved automatically and can be adjusted later
- Process loops into separate files:

```bash
lua process.lua [input video] [optional: output directory]
```

See `batch.lua` for processing examples (reencode, lossless cut, etc.).

## Notes

- `batch.lua` provides customisable conversion methods
- `process.lua` passes arguments to the batch processor
- Adapt both scripts to fit your workflow
- If you need lossless cut functionality make sure [smartcut](https://github.com/skeskinen/smartcut) is on your `PATH`
- The same goes to `ffmpeg` - it is needed to reencode clips if you use `process.lua`