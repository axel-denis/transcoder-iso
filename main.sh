# ==========================================
# CONFIGURATION
# ==========================================
# common
JOBS=2
INPUT_DIR="/transcoding/to_transcode"
PROCESS_DIR="/transcoding/transcoding"
OUTPUT_DIR="/transcoding/transcoded"
LOG_FILE="/transcoder.log"

# specific to [platform]
TARGET_PERCENT=70 # [intel, nvidia]
CRF_VALUE=23 # [cpu]
PRESET_CPU="slow" # veryfast, fast, medium, slow, slower, veryslow [cpu]
PRESET_INTEL="slower" # [intel]
PRESET_NVIDIA="slow" # [nvidia]
# ==========================================

mkdir -p "$INPUT_DIR"
mkdir -p "$PROCESS_DIR"
mkdir -p "$OUTPUT_DIR"

do_encode() {
	# exporting variables helps the nix bash compiler not scream about unused variables
	export input="$1"
	input_name=$(basename $input)
	export input_name
	export target_pct="$2"
	export crf="$3"
	export out_dir="$4"
	export process_dir="$5"
	export preset_cpu="$6"
	export preset_intel="$7"
	export preset_nvidia="$8"

	if [ ! -f "$input" ]; then
		return 0
	fi

	process="$process_dir/$input_name"
	output="$out_dir/${input_name%.*}.mkv"

	mv "$input" "$process"

	# Estimating target size (for intel/nvidia)
	size_bytes=$(stat -c%s "$process")
	target_size_bytes=$((size_bytes * target_pct / 100))
	duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$process")
	avg_bitrate=$(echo "($target_size_bytes * 8 / $duration) - 192000" | bc)
	export avg_bitrate

	# Checking for HDR
	is_hdr=$(ffprobe -v error -show_streams "$(readlink -f $process)" | grep "transfer=smpte2084")
	if [ -n "$is_hdr" ]; then
		echo "=> HDR file : converting to 10-bit SDR..."
		export VIDEO_FILTER="zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709,format=yuv420p10le"
	else
		echo "=> SDR file : Direct encoding to 10-bit..."
		export VIDEO_FILTER="format=yuv420p10le"
	fi

	ENCODER # will be replaced by the encoder by the nix code

	echo "[$(date +'%H:%M:%S')] FINISHED : $process"
	rm "$process"
}

export -f do_encode

echo "" > $LOG_FILE
parallel --will-cite --jobs "$JOBS" --line-buffer \
	do_encode {} "$TARGET_PERCENT" "$CRF_VALUE" "$OUTPUT_DIR" "$PROCESS_DIR" \
	"$PRESET_CPU" "$PRESET_INTEL" "$PRESET_NVIDIA" \
	::: $INPUT_DIR/* | tee -a "$LOG_FILE"
