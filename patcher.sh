#!/bin/bash

function save_current() {
  echo "[INFO] Saving current ffmpeg as ffmpeg.orig"
	mv -n /var/packages/VideoStation/target/lib/ffmpeg /var/packages/VideoStation/target/lib/ffmpeg.orig
}

function save_and_patch() {
	cp -n /var/packages/VideoStation/target/lib/libsynovte.so /var/packages/VideoStation/target/lib/libsynovte.so.orig
	chown VideoStation:VideoStation /var/packages/VideoStation/target/lib/libsynovte.so.orig

	sed -i -e 's/eac3/3cae/' -e 's/dts/std/' -e 's/truehd/dheurt/' /var/packages/VideoStation/target/lib/libsynovte.so
}

function armv8_procedure() {
  save_current

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

  save_and_patch

	echo ""
	echo "[SUCCESS] Done patching, please restart VideoStation (stop and start from package center)"
}

function others_procedure() {
  save_current

  wget -O - https://gist.githubusercontent.com/BenjaminPoncet/bbef9edc1d0800528813e75c1669e57e/raw/ffmpeg-wrapper > /var/packages/VideoStation/target/bin/ffmpeg

  chown root:VideoStation /var/packages/VideoStation/target/bin/ffmpeg
  chmod 750 /var/packages/VideoStation/target/bin/ffmpeg
  chmod u+s /var/packages/VideoStation/target/bin/ffmpeg

  save_and_patch
}

if [[ $(cat /proc/cpuinfo | grep 'model name' | uniq) =~ "ARMv8" ]]; then
  armv8_procedure
else
  others_procedure
fi

