echo ">>> [CPU] Starting : $(readlink -f $process) ($crf)"
ffmpeg -nostdin -hide_banner -i "$(readlink -f $process)" \
	-vf "$VIDEO_FILTER" \
	-c:v libx265 \
	-crf "$crf" \
	-preset "$preset_cpu" \
	-pix_fmt yuv420p10le \
	-map 0 -c:a copy -c:s copy \
	"$output" 2>&1 | stdbuf -oL tr '\r' '\n' | grep --line-buffered -E "fps=|speed=|size="