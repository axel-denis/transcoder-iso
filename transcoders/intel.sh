# ==========================================
# CONFIGURATION INTEL QSV (HARDWARE)
# ==========================================
TARGET_PERCENT=70
JOBS=2
OUTPUT_DIR="/transcoding/transcoded/"
INPUT_DIR="/transcoding/to_transcode"
PROCESS_DIR="/transcoded/transcoding"
PRESET="slower" # veryfast, fast, medium, slow, slower, veryslow
LOG_FILE="/transcoder.log"
# ==========================================

mkdir -p "$OUTPUT_DIR"

do_encode() {
	input="$1"
	target_pct="$2"
	out_dir="$3"
	process_dir="$4"
	preset="$5"

	process="$process_dir/${input}"
	output="$out_dir/${input%.*}.mkv"

	mv $input $process

	# Estimating target size
	size_bytes=$(stat -c%s "$process")
	target_size_bytes=$((size_bytes * target_pct / 100))
	duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$process")
	avg_bitrate=$(echo "($target_size_bytes * 8 / $duration) - 192000" | bc)

	# Checking for HDR
	is_hdr=$(ffprobe -v error -show_streams "$process" | grep "transfer=smpte2084")
	if [ -n "$is_hdr" ]; then
		echo "=> HDR file : converting to 10-bit SDR..."
		VIDEO_FILTER="zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709,format=yuv420p10le"
	else
		echo "=> SDR file : Direct encoding to 10-bit..."
		VIDEO_FILTER="format=yuv420p10le"
	fi

	echo ">>> [INTEL QSV] Starting : $process ($((avg_bitrate / 1000)) kbps)"

	ffmpeg -nostdin -hide_banner -i "$process" \
		-vf "$VIDEO_FILTER" \
		-c:v hevc_qsv \
		-preset "$preset" \
		-b:v "$avg_bitrate" \
		-maxrate "$((avg_bitrate * 15 / 10))" \
		-bufsize "$((avg_bitrate * 2))" \
		-look_ahead 1 \
		-pix_fmt p010le \
		-map 0 -c:a copy -c:s copy \
		"$output" 2>&1 | stdbuf -oL tr '\r' '\n' | grep -E "fps=|speed="
}

export -f do_encode

parallel --will-cite --jobs "$JOBS" --line-buffer \
	do_encode {} "$TARGET_PERCENT" "$OUTPUT_DIR" "$PROCESS_DIR" "$PRESET" \
	::: "${INPUT}/*.*" | tee -a "$LOG_FILE"
