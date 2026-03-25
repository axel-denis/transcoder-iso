echo ">>> [DVD] Starting : $process ($crf)"

ffmpeg -nostdin -hide_banner -i "$process" \
	-vf "yadif=1:-1:0,format=yuv420p" -c:v libsvtav1 -preset 4 -crf 26 -map_metadata 0 -c:a libopus -b:a 128k \
	"$output" 2>&1 | stdbuf -oL tr '\r' '\n' | grep --line-buffered -E "fps=|speed=|size="

sleep 5
exiftool -tagsfromfile "$process" "-FileModifyDate" "-FileCreateDate" "$output"
