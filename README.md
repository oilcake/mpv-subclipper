Subclipper is something like looper and portable editing station on top of wonderful mpv-player.

You can add cut-points to your videos while watching it, and any chosen region will be immediately looped and its loop boundaries saved to file. in any video you can setup as many loops as needed, and later use a script in `process.lua` to reencode(or lossless cut) all your parts to new files.

Comes with a lot of customized hotkeys.

Currently Mac and Linux only. If anybody wants to make it cross-platform you are welcome to contribute.

if you keep your mpv-related files in default location you can install the plugin with:

```bash
bash install.sh
```

Note that `batch.lua` is a bit messy and may not exactly fit your needs. You may think of it as an example how different conversion methods can be used automatically according to file's format, dimensions, or clip's size. Also, `process.lua` is only used to feed command line's args to batch processor object. Probably you want to customize both `batch.lua` and `process.lua`.
