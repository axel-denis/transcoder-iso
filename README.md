# NixOS Based TRANSCODER .iso
This project allows decentralized transcoding for a large media library, distributed accross many computers.
It directly provides an ISO image than can be launched as a live iso and getting to work without manual intervention.

It is almost bare metal on purpose. No configuration gui, no tools... I didn't thought I would publish this in the first place.
If you need to change a behavior, you will have to edit the scripts directly. I've tried to make somewhat clear code with config
at the top of files.

# What is does
- Converts h264 to h265
- HDR to SDR if needed
- All files stored in 10bits mode (even if was 8bit before)
- Display a web page to see the current logs of transcoding on the port 80

# Support:
- CPU (sowfware)
- NVENC (nvidia hardware)
- QSV (intel hardware)

# More thoughts
Everything is converted to 10bit video for simplicity.
We can think that this is a huge loss in storage space, but after looking more into it, it seems that it helps the encoder avoid making compression artefacts and using large data to hide it, so a 8bit file shouldn't grow much if transcoded stored in 10bit (even less as we are transcoding to h265)

# How to use

## Theory first

Have a samba share containing the following:
```
/to_transcode
  -> all video files
```
Video files should be symlinks for performances purposes. (also because they will be deleted during the process)

Each node will connect to the samba, select a file in `/to_transcode` and move it to `/transcoding`
Then transcode it, putting the result in `/transcoded`

## Now the real steps

### configuration
Head to `./filesystem.nix` and edit the ip of your server, username and password (samba).
Please be sure to let the rest of the file unchanged.

Your server should of course host a samba session like described in this file. If you're using NixOS as your server system, like every Chad does, you can host one [like so.](https://nixos.wiki/wiki/Samba)

Tweak the scripts in `./transcoders` if needed.
- `nvidia.sh` and `intel.sh` scripts use a percentage of the original file size as the new size target (70% as a default)
- `cpu.sh` uses the more common CRF value (23 as default)

You can change
- TARGET_PERCENT / CRF_VALUE to tweak the quality/size of the output
- JOBS to change the number of parallel jobs on this computer
- PRESET (slower = better result at the cost of time)

You can also change other variables, but it will probably break the whole software if you don't fix it accordingly.

### build
**Build the iso you need** with the following command:
```nix
nix build ".#transcode-<cpu/nvidia/intel>"
```
or build **all the isos** with the little script `./build_all.sh`

On NixOS this will work directly, however on another distro, I don't know, you're on your own, with your weak distro (I'm joking... or am I?)
![joking](https://media1.tenor.com/m/RcVw51AFOv4AAAAd/farcry5-farcry.gif)

Starting by installing Nix should be your first step in this case

### using
To flash the iso on an usb key, you may use:
```bash
sudo dd if=./<selected_iso.iso> of=/dev/<sda or your usb key> status=progress
```

Then just boot on every computer you have with the iso you generated.
If you did this correctly, and each node is able to connect to the samba share, everything should work nicely.
You can check status of transcoding on each node on port `80`

## More tips

1.
If you have a large library, it's maybe split between many disks. No worries. You can use [mount --bind](https://unix.stackexchange.com/questions/198590/what-is-a-bind-mount) to mount directories you want on your samba.
It's better to do this than to use symlinks. Symlinks should not be pointing outside of your samba share. With `mount --bind`, you mount the dirs you want onto your samba share, then create the needed symlinks from this mount to the `/to_transcode` and voila, your symlink goes to and from your samba share only.

2.
You should check the output before deleting your original files. The market of codecs, color ranges, video formats and more is a total mess and the settings I choose may not work for you.
That's why using symlinks in the `/to_transcode` folder is best.