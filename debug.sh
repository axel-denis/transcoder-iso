# ==========================================
# CONFIGURATION
# ==========================================
# common
JOBS=5
INPUT_DIR="/test/to_transcode"
PROCESS_DIR="/test/transcoding"
OUTPUT_DIR="/test/transcoded"
LOG_FILE="/test/transcoder.log"

# specific to [platform]
TARGET_PERCENT=70     # [intel, nvidia]
CRF_VALUE=23          # [cpu]
PRESET_CPU="slow"     # veryfast, fast, medium, slow, slower, veryslow [cpu]
PRESET_INTEL="slower" # [intel]
PRESET_NVIDIA="slow"  # [nvidia]
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

	waitingTime=$(shuf -i 1-5 -n 1)
	echo ">>> [TEST] Starting : $process | faking $waitingTime seconds long process"
	sleep "$waitingTime"
	touch "$output"

	echo "[$(date +'%H:%M:%S')] FINISHED : $process"
	rm "$process"
}

export -f do_encode


touch /test/to_transcode/test1.mp4
touch /test/to_transcode/test2.mkv
touch /test/to_transcode/test3.mkv
touch /test/to_transcode/test4.mkv
touch /test/to_transcode/test5.mkv

parallel --will-cite --jobs "$JOBS" --line-buffer \
	do_encode {} "$TARGET_PERCENT" "$CRF_VALUE" "$OUTPUT_DIR" "$PROCESS_DIR" \
	"$PRESET_CPU" "$PRESET_INTEL" "$PRESET_NVIDIA" \
	::: $INPUT_DIR/* | tee -a "$LOG_FILE"
