#!/bin/bash

MYDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
SAVEDIR=$(pwd)

# Check programs
if [ -z "$(which ffmpeg)" ]; then
    echo "Error: ffmpeg is not installed"
    exit 1
fi

if [ -z "$(which MP4Box)" ]; then
    echo "Error: MP4Box is not installed"
    exit 1
fi

cd "$MYDIR"

TARGET_FILES=$(find ./ -type f -name "*.mp4")
for f in $TARGET_FILES
do
    f=$(basename "$f") # fullname of the file
    f="${f%.*}" # name without extension

    if [ ! -d "dash_${f}" ]; then
        echo "Converting \"$f\" to multi-bitrate video in MPEG-DASH"

        ffmpeg -y -i "${f}.mp4" -c:a aac -b:a 128k -vn -g 120 "${f}_audio.mp4"
        ffmpeg -y -i "${f}.mp4" -c:v h264 -b:v 2500k -vf "scale=-2:1080" -g 120 -f mp4 "${f}_2500.mp4"
        ffmpeg -y -i "${f}.mp4" -c:v h264 -b:v 1000k -vf "scale=-2:720" -g 120 -f mp4 "${f}_1000.mp4"
        ffmpeg -y -i "${f}.mp4" -c:v h264 -b:v 200k -vf "scale=-2:360" -g 120 -f mp4 "${f}_200.mp4"

        rm -f ffmpeg*log*
		
        MP4Box -dash 8000 -frag 8000 -segment-name seg_ "${f}_2500.mp4#video" "${f}_1000.mp4#video" "${f}_200.mp4#video" presentation.mp4#audio -out master_manifest.mpd
    fi

done

cd "$SAVEDIR"