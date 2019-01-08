# Magic Shield Attack :: HTML
Notes about the HTML can go here.

# To capture a nice video
```
ffmpeg -f x11grab -s 1920x1080 -i :0.0+0,00 -c:v libx264 -preset ultrafast -crf 0 /tmp/my-vid.mkv
```

To then crop it in length (5 seconds in, until 15 seconds at end):

```
ffmpeg -ss 00:00:05.0 -i my-vid.mkv -t 00:00:15.0 my-vid-1.mkv
```

To change to webm/ogg:

```
ffmpeg -i my-vid-1.mkv video.{mp4,ogg}
```
