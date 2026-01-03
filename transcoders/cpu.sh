# ==========================================
# CONFIGURATION FOR CPU (SOFTWARE)
# ==========================================
CRF_VALUE=23
PRESET="slow"
JOBS=2
OUTPUT_DIR="/transcoding/transcoded/"
INPUT_DIR="/transcoding/to_transcode"
PROCESS_DIR="/transcoded/transcoding"
LOG_FILE="/transcoder.log"
# ==========================================

mkdir -p "$OUTPUT_DIR"

do_encode() {
	input="$1"
	crf="$2"
	out_dir="$3"
	process_dir="$4"
	preset="$5"

	process="$process_dir/${input}"
	output="$out_dir/${input%.*}.mkv"

	mv $input $process

	# Checking for HDR
	is_hdr=$(ffprobe -v error -show_streams "$process" | grep "transfer=smpte2084")

	if [ -n "$is_hdr" ]; then
		echo "=> HDR file : converting to 10-bit SDR..."
		VIDEO_FILTER="zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709,format=yuv420p10le"
	else
		echo "=> SDR file : Direct encoding to 10-bit..."
		VIDEO_FILTER="format=yuv420p10le"
	fi

	echo ">>> [CPU] Starting : $process ($((avg_bitrate / 1000)) kbps)"

	ffmpeg -nostdin -hide_banner -i "$process" \
		-vf "$VIDEO_FILTER" \
		-c:v libx265 \
		-crf "$crf" \
		-preset "$preset" \
		-pix_fmt yuv420p10le \
		-map 0 -c:a copy -c:s copy \
		"$output" 2>&1 | stdbuf -oL tr '\r' '\n' | grep --line-buffered -E "fps=|speed=|size="

	echo "[$(date +'%H:%M:%S')] TERMINÉ : $process"
}

export -f do_encode

parallel --will-cite --jobs "$JOBS" --line-buffer \
	do_encode {} "$CRF_VALUE" "$OUTPUT_DIR" "$PROCESS_DIR" "$PRESET" \
	::: "${INPUT}/*.*" | tee -a "$LOG_FILE"
