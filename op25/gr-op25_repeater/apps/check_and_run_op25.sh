#!/bin/bash

# Set directory
DIR=~/op25/op25/gr-op25_repeater/apps/
cd $DIR || { echo "Error: Directory $DIR not found"; exit 1; }

# Ensure audio.py is executable
chmod +x audio.py

# Overwrite meta.json
cat > meta.json << EOL
{
  "icecastServerAddress": "192.168.1.8",
  "icecastPort": 8000,
  "icecastPass": "hackme",
  "icecastMountpoint": "op25",
  "icecastMountExt": ".mp3",
  "delay": 0.0
}
EOL

# Overwrite op25.liq
cat > op25.liq << EOL
#!/usr/bin/liquidsoap
set("log.stdout", true)
set("log.file", false)
set("log.level", 3)
set("frame.audio.samplerate", 8000)

input = mksafe(input.external(buffer=0.5, channels=2, samplerate=8000, restart_on_error=false, "./audio.py -s -x 2"))

output.icecast(%mp3(bitrate=16, samplerate=22050, stereo=false),
              host="192.168.1.8", port=8000, mount="op25", password="hackme",
              description="OP25 Scanner", genre="Public Safety", url="http://192.168.1.8",
              content_type="audio/mpeg", input)
EOL
chmod +x op25.liq

# Overwrite trunk.tsv
cat > trunk.tsv << EOL
0x371	867475000,867012500	0	tags.tsv
EOL

# Stop existing processes
pkill -f rx.py
pkill -f op25.liq

# Diagnostic Checks
echo "=== Diagnostic Checks ==="
echo "1. Checking Icecast status:"
sudo systemctl status icecast2 | grep "Active:" || echo "Error: Icecast not running"

echo "2. Checking port 8000:"
netstat -tuln | grep 8000 || echo "Error: Port 8000 not open"

echo "3. Checking audio.py permissions:"
ls -l audio.py | grep "rwxr-xr-x" || echo "Error: audio.py not executable"

echo "4. Checking Icecast logs for /op25:"
cat /var/log/icecast2/error.log | grep "/op25" || echo "No /op25 mount point in Icecast logs"

# Start rx.py and op25.liq
echo "Starting OP25 and Liquidsoap..."
screen -S op25 -dm ./rx.py --nocrypt --args "rtl=1" --gains "lna:30" -S 2400000 -q 18.5 -2 -f 867.475e6 -o 25000 -V -2 -U -l http:0.0.0.0:8080 -M meta.json
sleep 2
screen -S stream -dm ./op25.liq

# Verify processes
echo "5. Checking running processes:"
ps aux | grep -E "rx.py|op25.liq" | grep -v grep || echo "Error: rx.py or op25.liq not running"

echo "6. Checking UDP port 23456:"
ss -uap | grep 23456 || echo "Error: No process listening on 127.0.0.1:23456"

# Instructions
echo "=== Instructions ==="
echo "Check stream: http://192.168.1.8:8000/op25"
echo "View OP25 logs: screen -r op25"
echo "View Liquidsoap logs: screen -r stream"
echo "Check OP25 web interface for transmissions: http://192.168.1.8:8080"
echo "If /op25 is missing, review Liquidsoap and Icecast logs abov"
