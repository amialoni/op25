#!/bin/bash
cd ~/op25/op25/gr-op25_repeater/apps/

# Kill old processes
sudo pkill -f rx.py || true
sudo pkill -f ffmpeg || true
sleep 1
rtl_test -t
# Stop flag
if [[ "$1" == "-s" ]]; then
    echo "Stopped OP25 and FFmpeg."
    exit 0
fi
last_octet=$(ip -br a | grep wlp1s0 | awk '{print $3}' | cut -d'.' -f4 | cut -d'/' -f1)
echo "ip=$last_octet"
case $last_octet in
    8|10)
        echo "Last octet is $last_octet. Performing action for 8 or 10..."
	RTL_DEV="rtl=0"
	RTL_FRQ="867.475e6"
	RTL_PPM="18"
	RTL_GAIN="37"
	M3U_PATH="../www/www-static/op25.m3u8"
        # Add your action here, e.g., touch /tmp/octet_8_or_10
        ;;
    185)
        echo "Last octet is 185. Performing action for 185..."
	RTL_DEV="rtl=0"
	RTL_FRQ="867.475e6"
	RTL_PPM="-4"
	RTL_GAIN="30"
	M3U_PATH="../www/www-static/op25.m3u8"
        # Add your action here, e.g., touch /tmp/octet_185
        ;;
    16|138)
        echo "Last octet is 185. Performing action for 185..."
	RTL_DEV="rtl=0"
	RTL_FRQ="867.475e6"
	RTL_PPM="-4"
	RTL_GAIN="30"
	M3U_PATH="../www/www-static/op25.m3u8"
        # Add your action here, e.g., touch /tmp/octet_185
        ;;
    *)
        echo "Last octet is $last_octet, which is neither 8, 10, nor 185. No action taken."
	RTL_DEV="rtl=0"
	RTL_FRQ="867.475e6"
	RTL_PPM="-4"
	RTL_GAIN="30"
	M3U_PATH="../www/www-static/op25.m3u8"
        ;;
esac

# Start OP25 receiver
set -x
./rx.py --nocrypt \
    --args "$RTL_DEV" \
    --gains "lna:$RTL_GAIN" \
    -S 2400000 \
    -q "$RTL_PPM" -o 500 \
    -d 0 -v 1 -2 -f "$RTL_FRQ" \
    -X -V -w \
    -l http:0.0.0.0:8080 &
set +x
sleep 1

# Stream to browser via HLS
#mkdir -p  ../www/www-static/html
#sudo python3 -m http.server 8081 &
ffmpeg -re -f s16le -ar 8000 -ac 1 -i udp://127.0.0.1:23456 \
  -c:a aac -b:a 64k \
  -f hls -hls_time 5 -hls_list_size 12 -hls_flags delete_segments \
  "$M3U_PATH" &

#ffmpeg -re -f s16le -ar 8000 -ac 1 -i udp://127.0.0.1:23456 \
#-c:a aac -b:a 64k \
#-f hls -hls_time 5 -hls_list_size 52 -hls_flags delete_segments+append_list \
# html/op25.m3u8 &

#ffmpeg -re -thread_queue_size 512 \
#-f s16le -ar 8000 -ac 1 -i udp://127.0.0.1:23456 \
#-f lavfi -i aevalsrc=0:d=1740:s=8000 \
#-filter_complex "[0:a][1:a]amix=inputs=2:dropout_transition=9999[aout]" \
#-map "[aout]" \
#-f tee "[f=hls:hls_time=5:hls_list_size=0:hls_flags=append_list+omit_endlist:c=aac:b:a=64k]html/op25.m3u8|[f=segment:segment_time=1740:reset_timestamps=1:c=libmp3lame:b:a=64k]html/op25_%03d.mp3" &

#ffmpeg -re -thread_queue_size 512 \
#-f s16le -ar 8000 -ac 1 -i udp://127.0.0.1:23456 \
#-f lavfi -i aevalsrc=0:d=1740:s=8000 \
#-filter_complex "[0:a][1:a]amix=inputs=2:dropout_transition=9999[aout]" \
#-map "[aout]" -c:a aac -b:a 64k \
#-f tee "[f=hls:hls_time=1740:hls_list_size=0:hls_flags=append_list+omit_endlist]../www/www-static/html/op25.m3u8|[f=segment:segment_time=1740:reset_timestamps=1]html/op25_%03d.ts" &

# ffmpeg -re -thread_queue_size 512 \
# -f s16le -ar 8000 -ac 1 -i udp://127.0.0.1:23456 \
# -f lavfi -i aevalsrc=0:d=1740:s=8000 \
# -filter_complex "[0:a][1:a]amix=inputs=2:dropout_transition=9999[aout]" \
# -map "[aout]" -c:a aac -b:a 64k \
# -f hls -hls_time 5 -hls_list_size 6 -hls_flags append_list+omit_endlist+independent_segments \
# -hls_segment_filename html/op25_%03d.ts html/op25.m3u8 &


# ffmpeg -re -thread_queue_size 512 \
# -f s16le -ar 8000 -ac 1 -i udp://127.0.0.1:23456 \
# -f lavfi -i aevalsrc=0:d=1740:s=8000 \
# -filter_complex "[0:a][1:a]amix=inputs=2:dropout_transition=9999[aout]" \
# -map "[aout]" \
# -c:a aac -b:a 64k \
# -f hls -hls_time 5 -hls_list_size 6 -hls_flags append_list+omit_endlist+independent_segments \
# -hls_segment_filename html/op25_%03d.ts \
# -hls_m3u8_url html/op25.m3u8 \
# &&(  # New section for creating separate audio files
#     -f null -i [aout] -acodec copy output1.aac  # First 29 minutes
#     -f null -i [aout] -acodec copy output2.aac # Next 29 minutes (starts after first one ends)
# ) 
