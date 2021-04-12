#!/bin/bash

function run() {
	if [[ ! $(cat /proc/cpuinfo | grep 'model name' | uniq) =~ "ARMv8" ]]; then
		echo "[ERROR] This script is only intended for ARMv8 CPUs"
		return -1
	fi

	echo "[INFO] Saving current ffmpeg as ffmpeg.orig"
	mv -n /var/packages/VideoStation/target/lib/ffmpeg /var/packages/VideoStation/target/lib/ffmpeg.orig

	echo "[INFO] Downloading patched ffmpeg files to /tmp/ffmpeg"
	echo ""

	declare -a ffmpegfiles=(
		"libavcodec.so.56"
		"libavdevice.so.56"
		"libavfilter.so.56"
		"libavformat.so.56"
		"libavutil.so.54"
		"libpostproc.so.53"
		"libswresample.so.1"
		"libswscale.so.3"
	)

	mkdir /tmp/ffmpeg

	for file in "${ffmpegfiles[@]}"
	do
		wget -O "/tmp/ffmpeg/$file" "https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher/blob/main/ffmpeg/$file?raw=true"
	done

	mv /tmp/ffmpeg /var/packages/VideoStation/target/lib/

	cp -n /var/packages/VideoStation/target/lib/libsynovte.so /var/packages/VideoStation/target/lib/libsynovte.so.orig
	chown VideoStation:VideoStation /var/packages/VideoStation/target/lib/libsynovte.so.orig

	sed -i -e 's/eac3/3cae/' -e 's/dts/std/' -e 's/truehd/dheurt/' /var/packages/VideoStation/target/lib/libsynovte.so

	echo ""
	echo "[SUCCESS] Done patching, please restart VideoStation (stop and start from package center)"
}

run

