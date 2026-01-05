# this fake transcoder simply sleeps a random amount of time and return a blank file
# used to test the main logic without actually transcoding the files

waitingTime=$(shuf -i 1-5 -n 1)
echo ">>> [TEST] Starting : $process | faking $waitingTime seconds long process"
sleep "$waitingTime"
touch "$output"