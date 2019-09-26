# Files and aseprite

## Creating the initial file

- Open the .aseprite file (likely 32-main-unit-base.aseprite or 32-main-unit-base-back.aseprite).
- Adjust / create the new layer and turn off visible for all others
- Export as horizontal sprite sheet (png)

## Adjusting it to work with the way of loading files for Godot2

In the directory the sprite sheet export is in, use:

```sh
convert 32-head-shorthair-back.png -crop 32x32 32-head-shorthair-back.png
```

That will generate a 32-head-shorthair-back-0.png and -1.png files

Next, resize to work well with game via:

```sh
ls 32-head-shorthair*.png | xargs -I{} convert {} -filter point -resize 300%  {}
```

That will make them big enough to work well with the godot2 game while
keeping the pixel art aspect ratio (so the 32px is 3x as big, 96px)
