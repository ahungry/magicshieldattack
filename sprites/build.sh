#!/bin/bash

set +x

for f in $(ls 32-*.png); do
    #echo $f
    convert $f -crop 32x32 $f
done
