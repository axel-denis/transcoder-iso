echo ">>> [INTEL QSV] Starting : $(readlink -f $process) ($((avg_bitrate / 1000)) kbps)"
ffmpeg -nostdin -hide_banner -hwaccel qsv -i "$(readlink -f $process)" \
	-vf "$VIDEO_FILTER" \
	--hwaccel_output_format qsv \
	-c:v h265_qsv \
	-preset "$preset_intel" \
	-b:v "$avg_bitrate" \
	-maxrate "$((avg_bitrate * 15 / 10))" \
	-bufsize "$((avg_bitrate * 2))" \
	-look_ahead 1 \
	-pix_fmt p010le \
	-map 0 -c:a copy -c:s copy \
	"$output" 2>&1 | stdbuf -oL tr '\r' '\n' | grep -E "fps=|speed="
