#!/bin/bash

RAW=test_raw_sequence
MOVIE=test_movie
FFMPEG_SEQ=test_ffmpeg_sequence

mkdir -p $RAW
mkdir -p $MOVIE
mkdir -p $FFMPEG_SEQ

# generate image sequence
for i in $(seq -f "%05g" 0 999)
do
        #convert -size 52x18 -pointsize 16 -font /usr/share/fonts/truetype/freefont/FreeMono.ttf label:$i $i.png 
        convert -size 52x18 -pointsize 16 label:$i $RAW/$i.png 
done    


# render video
ffmpeg -y -f image2 -r 30 -i $RAW"%/05d.png" -r 30 $MOVIE"/test.avi"

# extract individual frames with ffmpeg
ffmpeg -i -start_number 0 $MOVIE"/test.avi" -an -f image2 $FFMPEG_SEQ"/output_%05d.png"