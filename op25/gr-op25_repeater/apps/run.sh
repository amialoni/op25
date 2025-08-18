#!/bin/bash
cd ~/op25/op25/gr-op25_repeater/apps/

# Kill old processes
pkill -f rx.py || true
pkill -f ffmpeg || true
pkill -f http.server || true
sleep 2
rtl_test -t
# Stop flag
if [[ "$1" == "-s" ]]; then
    echo "Stopped OP25, FFmpeg and HTTP server."
    exit 0
fi

RTL_DEV="rtl=1"
# -o 500
# Start OP25 receiver

# nohup 
./rx.py --nocrypt \
    --args "$RTL_DEV" \
    --gains "lna:32" \
    -S 1000000 \
    -q 19  \
    -d 0 -v 1 -2 -f 867.475e6 \
    -X -V -w \
    -l http:0.0.0.0:8080 &

sleep 5

# Stream to browser via HLS
mkdir -p  html
sudo python3 -m http.server 81 &
#ffmpeg -re -f s16le -ar 8000 -ac 1 -i udp://127.0.0.1:23456 \
#  -c:a aac -b:a 64k \
#  -f hls -hls_time 5 -hls_list_size 12 -hls_flags delete_segments \
#  /srv/www/myradio.tovmeod.com/op25/op25.m3u8 &

# nohup ffmpeg -re -f s16le -ar 8000 -ac 1 -i udp://127.0.0.1:23456 \
# -c:a aac -b:a 64k \
# -f hls -hls_time 5 -hls_list_size 52 -hls_flags delete_segments+append_list \
#  html/op25.m3u8 &

 ffmpeg -re -f s16le -ar 8000 -ac 1 -i udp://127.0.0.1:23456 \
-f lavfi -t 3600 -i aevalsrc=0::duration=3600:sample_rate=8000 \
-filter_complex "[0:a][1:a]amix=inputs=2:dropout_transition=9999" \
-c:a aac -b:a 64k \
-f hls -hls_time 5 -hls_list_size 0 -hls_flags append_list+omit_endlist \
html/op25.m3u8 &


