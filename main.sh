# ==========================================
# CONFIGURATION
# ==========================================
# common
JOBS=2
INPUT_DIR="/transcoding/to_transcode"
OUTPUT_DIR="/transcoding/transcoded"
TRACKING_FILE="/transcoding/transcoding_list.txt"
LOG_FILE="/transcoding/transcoder.log"

HOME="/" # don't change

# specific to [platform]
TARGET_PERCENT=70 # [intel, nvidia]
CRF_VALUE=23 # [cpu]
PRESET_CPU="slow" # veryfast, fast, medium, slow, slower, veryslow [cpu]
PRESET_INTEL="slower" # [intel]
PRESET_NVIDIA="slow" # [nvidia]
# ==========================================

do_encode() {

	# exporting variables helps the nix bash compiler not scream about unused variables
	export input="$1"
	input_name=$(basename "$input")
	export input_name
	export target_pct="$2"
	export crf="$3"
	export out_dir="$4"
	export tracking_file="$5"
	export preset_cpu="$6"
	export preset_intel="$7"
	export preset_nvidia="$8"

	if [ ! -f "$input" ]; then
		return 0
	fi

	# Use a lock file to ensure atomic checks across multiple jobs and nodes.
 	(
		flock -x 200
		[ ! -f "$tracking_file" ] && touch "$tracking_file"
		grep -Fxq "$input" "$tracking_file" && exit 1
		echo "$input" >> "$tracking_file"
	) 200>"${tracking_file}.lock" || return 0

	process="$input"
	output="$out_dir/${input_name%.*}.mkv"


	# Estimating target size (for intel/nvidia)
	size_bytes=$(stat -c%s "$process")
	target_size_bytes=$((size_bytes * target_pct / 100))
	duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$process")
	avg_bitrate=$(echo "($target_size_bytes * 8 / $duration) - 192000" | bc)
	export avg_bitrate

	# Checking for HDR
	is_hdr=$(ffprobe -v error -show_streams "$process" | grep "transfer=smpte2084")
	if [ -n "$is_hdr" ]; then
		echo "=> HDR file : converting to 10-bit SDR..."
		export VIDEO_FILTER="zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709,format=yuv420p10le"
	else
		echo "=> SDR file : Direct encoding to 10-bit..."
		export VIDEO_FILTER="format=yuv420p10le"
	fi

	ENCODER # will be replaced by the encoder by the nix code

	echo "[$(date +'%H:%M:%S')] FINISHED : $process"
}

export -f do_encode

echo "" > $LOG_FILE
mkdir -p "$OUTPUT_DIR"


while true; do
parallel --will-cite --jobs "$JOBS" --line-buffer \
	do_encode {} "$TARGET_PERCENT" "$CRF_VALUE" "$OUTPUT_DIR" "$TRACKING_FILE" \
	"$PRESET_CPU" "$PRESET_INTEL" "$PRESET_NVIDIA" \
	::: "$(find "$INPUT_DIR" -type f)" | tee -a "$LOG_FILE";
sleep 5;
done