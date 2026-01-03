nix build ".#transcode-cpu" && cp ./result/iso/*.iso transcode_cpu.iso;
echo "done cpu";
nix build ".#transcode-intel" && cp ./result/iso/*.iso transcode_intel.iso;
echo "done intel";
nix build ".#transcode-nvidia" && cp ./result/iso/*.iso transcode_nvidia.iso;
echo "done nvidia";