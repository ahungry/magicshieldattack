#!/bin/bash

# Builds the images from small aseprite 32x32 images into 32 * 3 images (maybe we need bigger?)

set +x

for f in $(ls 32-*.png | grep -vE '[01].png$'); do
    convert $f -crop 32x32 $f
done

for f in $(ls 32-*.png | grep -E '[01].png$'); do
    convert $f -filter point -resize 300% $f
done

ls -thr *png | xargs -I{} identify {}
