subclipper is something like looper and portable editing station on top of wonderfool mpv-player

you can add cut-points to your videos while watching it, and any chosen region will be immediatly looped and saved to a file. in any video you can setup as many loops as needed, and later use a process.lua to reencode all your parts to new files

comes with a lot of customized hotkeys

Most probaly it is Unix only, if anybody wants to make it cross-platform you are welcome to contribute

you can use 

```bash
bash install.sh
```



if you keep your mpv-related files in default location



Note that **batch.lua** is a bit messy and may not exactly fit your needs. You may think of it as an example how different conversion methods can be used automatically according to file's format, dimensions, or clip's size. Also, **process.lua** is only used to feed command line's args to batch processor object. Probably you want to customize both **batch.lua** and **process.lua**.
