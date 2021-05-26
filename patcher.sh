#!/bin/bash

function restart_videostation() {
	if [[ -d /var/packages/CodecPack/target/bin ]]; then
  		echo "[INFO] Restarting CodecPack"
		synopkg restart CodecPack
	fi

	echo "[INFO] Restarting VideoStation..."
	synopkg restart VideoStation
}

function save_and_patch() {
	cp -n /var/packages/VideoStation/target/lib/libsynovte.so /var/packages/VideoStation/target/lib/libsynovte.so.orig
	chown VideoStation:VideoStation /var/packages/VideoStation/target/lib/libsynovte.so.orig

	sed -i -e 's/eac3/3cae/' -e 's/dts/std/' -e 's/truehd/dheurt/' /var/packages/VideoStation/target/lib/libsynovte.so
}

function armv8_procedure() {
	echo "[INFO] Saving current ffmpeg as ffmpeg.orig"
	mv -n /var/packages/VideoStation/target/lib/ffmpeg /var/packages/VideoStation/target/lib/ffmpeg.orig

	echo "[INFO] Downloading patched ffmpeg files to /var/packages/VideoStation/target/lib"
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
	);

	if [[ ! -d /var/packages/VideoStation/target/lib/ffmpeg ]]; then
		echo "[INFO] Creating ffmpeg directory"
		mkdir /var/packages/VideoStation/target/lib/ffmpeg
	fi

	for file in "${ffmpegfiles[@]}"
	do
		echo "[INFO] Downloading $file ..."
		wget -q -O "/var/packages/VideoStation/target/lib/ffmpeg/$file" "https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher/blob/main/ffmpeg/$file?raw=true"
	done

  	save_and_patch
  	restart_videostation

	echo ""
	echo "[SUCCESS] Done patching, you can now enjoy your movies ;) (please add a star to the repo if it worked for you)"
}

function others_procedure() {
	echo "[INFO] Saving current ffmpeg as ffmpeg.orig"
	mv -n /var/packages/VideoStation/target/bin/ffmpeg /var/packages/VideoStation/target/bin/ffmpeg.orig

	echo "[INFO] Downloading ffmpeg-wrapper for VideoStation"
	wget -q -O - https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher/blob/main/ffmpeg-wrapper.sh?raw=true > /var/packages/VideoStation/target/bin/ffmpeg

  	chown root:VideoStation /var/packages/VideoStation/target/bin/ffmpeg
  	chmod 750 /var/packages/VideoStation/target/bin/ffmpeg
  	chmod u+s /var/packages/VideoStation/target/bin/ffmpeg

  	if [[ -d /var/packages/CodecPack/target/bin ]]; then
  		echo "[INFO] Detected Advanced Media Extensions"

  		echo "[INFO] Saving current Advanced Media Extensions ffmpeg33 as ffmpeg33.orig"
		mv /var/packages/CodecPack/target/bin/ffmpeg33 /var/packages/CodecPack/target/bin/ffmpeg33.orig

		echo "[INFO] Copying VideoStation's ffmpeg to CodecPack ffmpeg33"
		cp /var/packages/VideoStation/target/bin/ffmpeg /var/packages/CodecPack/target/bin/ffmpeg33

		chmod 755 /var/packages/CodecPack/target/bin/ffmpeg33
	fi

  	save_and_patch
  	restart_videostation

	echo ""
	echo "[SUCCESS] Done patching, you can now enjoy your movies ;) (please add a star to the repo if it worked for you)"
}

if [[ $(cat /proc/cpuinfo | grep 'model name' | uniq) =~ "ARMv8" ]]; then
  	armv8_procedure
else
  	others_procedure
fi

