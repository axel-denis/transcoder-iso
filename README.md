# NixOS Based TRANSCODER .iso
This project allows decentralized transcoding for a large media library, distributed accross many computers.
It directly provides an ISO image (or a virtual machine binary) than can be launched as a live iso and getting to work without manual intervention.

It is almost bare metal on purpose. No configuration gui, no tools... I didn't thought I would publish this in the first place.

# What is does with the defaults scripts (you can add your own)
- Converts h264 to h265 
- HDR to SDR if needed
- All files stored in 10bits mode (even if was 8bit before)
- Display a web page to see the current logs of transcoding on the port 80

# Support:
- CPU (sowfware)
- NVENC (nvidia hardware) (not properly tested)
- QSV (intel hardware) (not properly tested)


# How to use

## Setup first

Have a Samba share containing the following:
```
/to_transcode
  -> all video files
```
Video files should be symlinks for performances purposes. (also because they will be deleted during the process)

Each node will connect to the Samba, select a file in `/to_transcode` and move it to `/transcoding`
Then transcode it, putting the result in `/transcoded`

## Now the real steps

### configuration
Set `fsAddress`, `fsUsername` and `fsPassword` accordingly for your Samba system.
(`fsAddress` example: `192.168.200/transcoding`)

Your server should of course host a Samba session like described in this file. If you're using NixOS as your server system, like every Chad does, you can host one [like so.](https://nixos.wiki/wiki/Samba)

Tweak the scripts in `./transcoders` if needed.
- `nvidia.sh` and `intel.sh` scripts use a percentage of the original file size as the new size target (70% as a default)
- `cpu.sh` uses the more common CRF value (23 as default)

You can add your own FFMPEG line in a new script. It will be detected, and you'll be able to build it using the script's name: `nix build ".#transcode-<yourscript>"`. See more later.

In the [main](./main.sh) script, you can change
- `TARGET_PERCENT` / `CRF_VALUE` to tweak the quality/size of the output
- `JOBS` to change the number of parallel jobs on this computer
- `PRESET` (slower = better result at the cost of time)

You can also change other variables, but it will probably break the whole software if you don't fix it accordingly.

### Building the project (ISO or VM)
**Build the iso you need** with the following command:
```nix
nix build ".#transcode-<cpu/nvidia/intel/...>"
```

If you want to quickly try without having a machine to test on, you can directly generate a virtual machine to test on (no additional steps required!). Just add "-vm" at the end of your desired script. Example:
```nix
nix build ".#transcode-cpu-vm"
```
Then run the resulting binary: `./result/bin/run-nixos-vm`


Note: I didn't test the VMs for hardware encoding, only CPU, please let me know if it works (or not) for your setup. NixOs being quite pure, I think it should work out of the box.

---

---
<br>

#### Other distros
On NixOS building this project will work directly, however on another distro, I don't know, you're on your own, with your weak distro (I'm joking)

<img src="https://media1.tenor.com/m/RcVw51AFOv4AAAAd/farcry5-farcry.gif" width="200">


Starting by installing Nix on your OS should be your first step in this case.

### Deploying
To flash the iso on an usb key, you may use:
```
sudo dd if=./<selected_iso.iso> of=/dev/<sda or your usb key> status=progress
```

Then just boot on every computer you have with the iso you generated.
If you did this correctly, and each node is able to connect to the Samba share, everything should work nicely.
You can check status of transcoding on each node on port `80`

## More tips

1.
If you have a large library, it's maybe split between many disks. No worries. You can use [mount --bind](https://unix.stackexchange.com/questions/198590/what-is-a-bind-mount) to mount directories you want on your Samba.
It's better to do this than to use symlinks. Symlinks should not be pointing outside of your Samba share. With `mount --bind`, you mount the dirs you want onto your Samba share, then create the needed symlinks from this mount to the `/to_transcode` and voila, your symlink goes to and from your Samba share only.

2.
You should check the output before deleting your original files. The market of codecs, color ranges, video formats and more is a total mess and the settings I choose may not work for you.
That's why using symlinks in the `/to_transcode` folder is best.

## Adding your own script
You can see the existing scripts in the `transcoders` folder. They are just an FFMPEG command, triggered by [main.sh](./main.sh).

You can add your own. Most of the variables provided by [main](./main.sh) are optionals, (telling a target size, if the media is hdr, etc).
The only mandatory are the `process` (symlink to the file to transcode) and the `output` (where to save the transcoded file) ones.

Note that `process` is a symlink, so you must resolve it:
```bash
readlink -f $process
```

The `VIDEO_FILTER` provides an SDR color space to convert to if the media is HDR.

---

# More thoughts
On the defaults provided scripts, everything is converted to 10bit video for simplicity.
We can think that this is a huge loss in storage space, but after looking more into it, it seems that it helps the encoder avoid making compression artefacts and using large data to hide it, so a 8bit file shouldn't grow much if transcoded stored in 10bit (even less as we are transcoding to h265)
