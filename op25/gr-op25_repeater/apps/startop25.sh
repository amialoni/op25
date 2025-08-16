#!/bin/bash

# Set directory
DIR=~/op25/op25/gr-op25_repeater/apps/
cd $DIR

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

# Overwrite trunk.tsv (optional, adjust NAC and frequencies if needed)
cat > trunk.tsv << EOL
0x371	867475000,867012500	0	tags.tsv
EOL

# Stop existing processes
pkill -f rx.py
pkill -f op25.liq

# Run start_op25.sh
./run.sh

echo "Configuration files updated and OP25 started."
echo "Check stream at http://192.168.1.8:8000/op25"
echo "View logs: 'screen -r op25' or 'screen -r stream'"
