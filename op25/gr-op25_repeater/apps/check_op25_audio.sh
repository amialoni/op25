#!/bin/bash
#
# Debug script for OP25 + Liquidsoap + Icecast
#

ICECAST_HOST="192.168.1.8"
ICECAST_PORT=8000
MOUNT="/op25.mp3"
LIQ_LOG="/tmp/op25.liq.log"

echo "=== Step 1: Is rx.py running? ==="
if pgrep -f rx.py >/dev/null; then
    echo "[OK] rx.py is running"
else
    echo "[FAIL] rx.py is NOT running"
fi

echo
echo "=== Step 2: Is audio.py producing audio? ==="
AUDIO_PY=$(pgrep -a -f "audio.py" | grep -v pgrep)
if [ -n "$AUDIO_PY" ]; then
    echo "[OK] audio.py is running: $AUDIO_PY"
else
    echo "[FAIL] audio.py not running — Liquidsoap will get silence"
fi

echo
echo "=== Step 3: Can we hear audio.py directly? ==="
echo "Recording 3 seconds from audio.py..."
timeout 3s ./audio.py -s > /tmp/op25_test.raw 2>/dev/null
if [ -s /tmp/op25_test.raw ]; then
    echo "[OK] audio.py is producing data"
    echo "You can play it with: play -r 8000 -e signed -b 16 -c 1 /tmp/op25_test.raw"
else
    echo "[FAIL] audio.py produced no audio data"
fi

echo
echo "=== Step 4: Is Liquidsoap connected to Icecast? ==="
if curl -s "http://${ICECAST_HOST}:${ICECAST_PORT}/status-json.xsl" | grep -q "$MOUNT"; then
    echo "[OK] Liquidsoap mountpoint $MOUNT is visible on Icecast"
else
    echo "[FAIL] Liquidsoap is NOT connected to Icecast on $MOUNT"
fi

echo
echo "=== Step 5: Is Liquidsoap logging errors? ==="
if [ -f "$LIQ_LOG" ]; then
    echo "Last 10 lines from $LIQ_LOG:"
    tail -n 10 "$LIQ_LOG"
else
    echo "[WARN] No Liquidsoap log file found at $LIQ_LOG"
fi

echo
echo "=== Step 6: Can we download a sample from Icecast? ==="
timeout 3s curl -s "http://${ICECAST_HOST}:${ICECAST_PORT}${MOUNT}" > /tmp/icecast_sample.mp3
if [ -s /tmp/icecast_sample.mp3 ]; then
    echo "[OK] Got stream data from Icecast — size $(stat -c%s /tmp/icecast_sample.mp3) bytes"
    echo "You can play it with: mpv /tmp/icecast_sample.mp3"
else
    echo "[FAIL] No data from Icecast mount $MOUNT"
fi

echo
echo "=== DONE ==="
