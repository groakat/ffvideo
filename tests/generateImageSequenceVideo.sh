#!/bin/bash

# generate image sequence
for i in $(seq -f "%05g" 0 999)
do
        convert -size 51x18 -pointsize 16 -font /usr/share/fonts/truetype/freefont/FreeMono.ttf label:$i $i.png 
done    


# render video
ffmpeg -y -f image2 -r 30 -i "%05d.png" -r 30 test.avi

# extract individual frames with ffmpeg
ffmpeg -i "test.avi" -an -f image2 "output_%05d.png"