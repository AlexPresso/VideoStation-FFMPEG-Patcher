#!/bin/bash

###############################
# VARS
###############################

# shellcheck source=/.github/workflows/mock/VERSION
source "/etc/VERSION"
dsm_version="$productversion $buildnumber-$smallfixnumber"
repo_base_url="https://raw.githubusercontent.com/AlexPresso/VideoStation-FFMPEG-Patcher"
action="patch"
branch="main"
ffmpegversion=""
wrappers=(
  "ffmpeg"
  "gst-launch-1.0"
  "gst-inspect-1.0"
)

vs_base_path=/var/packages/VideoStation
vs_path="$vs_base_path/target"
libsynovte_path="$vs_path/lib/libsynovte.so"
cp_base_path=/var/packages/CodecPack
cp_path="$cp_base_path/target"
cp_bin_path="$cp_path/bin"
cp_to_patch=(
  "ffmpeg41:ffmpeg"
  "ffmpeg27:ffmpeg"
  "ffmpeg33:ffmpeg"
  "gst-launch-1.0:gst-launch-1.0"
  "gst-inspect-1.0:gst-inspect-1.0"
)

gstreamer_plugins=(
  "libgstdtsdec"
  "libgstlibav"
)
gstreamer_libs=(
  "libavcodec-ffmpeg.so.56"
  "libavformat-ffmpeg.so.56"
  "libavutil-ffmpeg.so.54"
  "libbluray.so.1"
  "libdca.so.0"
  "libgme.so.0"
  "libgnutls-deb0.so.28"
  "libgsm.so.1"
  "libhogweed.so.4"
  "libmodplug.so.1"
  "libnettle.so.6"
  "libnuma.so.1"
  "libopenjpeg.so.5"
  "libopenjpeg_JPWL.so.5"
  "libopus.so.0"
  "liborc-0.4.so.0"
  "libp11-kit.so.0"
  "libpng12.so.0"
  "librtmp.so.1"
  "libschroedinger-1.0.so.0"
  "libshine.so.3"
  "libsoxr.so.0"
  "libspeex.so.1"
  "libssh-gcrypt.so.4"
  "libssh-gcrypt_threads.so.4"
  "libswresample-ffmpeg.so.1"
  "libtasn1.so.6"
  "libtheora.so.0"
  "libtheoradec.so.1"
  "libtheoraenc.so.1"
  "libtwolame.so.0"
  "libva.so.1"
  "libvpx.so.2"
  "libvpx.so.2.0"
  "libwavpack.so.1"
  "libwebp.so.5"
  "libx264.so.146"
  "libx265.so.59"
  "libxvidcore.so.4"
  "libzvbi.so.0"
  "libzvbi-chains.so.0"
  "dri/dummy_drv_video.so"
  "x264-10bit/libx264.so.146"
  "x265-10bit/libx265.so.59"
)

###############################
# UTILS
###############################

log() {
  printf "\e[0;37m[%s] \e[0m[%s] %b" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2$3"
}
info() {
  log "INFO" "\e[0m" "$1\n"
}
error() {
  log "ERROR" "\e[0;31m" "$1\n"
}
success() {
  log "SUCCESS" "\e[0;32m" "$1\n"
}

welcome_motd() {
  info "ffmpeg-patcher"

  download "motd" "$repo_base_url/$branch/motd.txt" /tmp/tmp.wget
  log "Message of the day" "\033[1;33m" "\n\n$(cat /tmp/tmp.wget)\n\n"

  sleep 3
}

root_check() {
  if [[ "$EUID" -ne 0 ]]; then
    error "This tool needs root access (please run 'sudo -i' before proceeding)."
    exit 1
  fi
}

check_dependencies() {
  missingDeps=0

  for dependency in "${dependencies[@]}"; do
    if [[ ! -d "/var/packages/$dependency" ]]; then
      error "Missing $dependency package, please install it and re-run the patcher."
      missingDeps=1
    fi
  done

  if [[ $missingDeps -eq 1 ]]; then
    exit 1
  fi
}

clear_cache() {
  if [[ -d "$cp_base_path/etc/gstreamer-1.0" ]]; then
    info "Clearing CodecPack gstreamer cache..."
    rm -f "$cp_base_path/etc/gstreamer-1.0/registry.*.bin"
  fi

  if [[ -d "$vs_base_path/etc/gstreamer-1.0" ]]; then
    info "Clearing VideoStation gstreamer cache..."
    rm -f "$vs_base_path/etc/gstreamer-1.0/registry.*.bin"
  fi
}

clean() {
  info "Cleaning orphan files..."

  rm -f /tmp/tmp.wget
  rm -f /tmp/ffmpeg.log
  rm -f /tmp/ffmpeg*.stderr
  rm -f /tmp/ffmpeg*.stderr.prev
  rm -f /tmp/gstreamer.log
  rm -f /tmp/gst*.stderr
  rm -f /tmp/gst*.stderr.prev
}

download() {
  log "INFO" "\e[0m" "Downloading $1... "

  wget -q -O - "$2" > /tmp/temp.wget
  downloadStatus=$?

  if [[ $downloadStatus == 0 ]]; then
    mv -f /tmp/temp.wget "$3"
    printf "\e[0;32mDone\n"
  else
    printf "\e[0;31mError\n"
    error "An error occurred while downloading $2. Rolling back changes..."
    unpatch

    error "An error occurred while downloading $2, every changes were rolled back."
    error "Please check your internet connection / GithubStatus. If you think this is an error, please file an issue to the repository."
    exit 1
  fi
}

################################
# PATCH PROCEDURES
################################

patch() {
  check_dependencies

  info "====== Patching procedure (branch: $branch) ======"

  if [[ -f "$vs_path/lib/libsynovte.so.orig" ]]; then
    error "You're trying to patch over an already patched VideoStation, if that's really what you want to do, please unpatch before patching again."
    exit 1
  fi

  for filename in "${wrappers[@]}"; do
    if [[ -f "$vs_path/bin/$filename" ]]; then
      info "Saving current $filename as $filename.orig"
      mv -n "$vs_path/bin/$filename" "$vs_path/bin/$filename.orig"

      download "$filename.sh" "$repo_base_url/$branch/wrappers/$filename.sh" "$vs_path/bin/$filename"
      chown root:VideoStation "$vs_path/bin/$filename"
      chmod 750 "$vs_path/bin/$filename"
      chmod u+s "$vs_path/bin/$filename"

      sed -i -e "s/@package_name@/VideoStation/" "$vs_path/bin/$filename"
      sed -i -e "s/@ffmpeg_version@/ffmpeg$ffmpegversion/" "$vs_path/bin/$filename"
    fi
  done

  if [[ -d $cp_bin_path ]]; then
    for file in "${cp_to_patch[@]}"; do
      filename="${file%%:*}"
      target="${file##*:}"

      if [[ -f "$cp_bin_path/$filename" ]]; then
        info "Patching CodecPack's $filename"

        mv -n "$cp_bin_path/$filename" "$cp_bin_path/$filename.orig"
        download "$filename.sh" "$repo_base_url/$branch/wrappers/$target.sh" "$cp_bin_path/$filename"
        chmod 750 "$cp_bin_path/$filename"
        chmod u+s "$cp_bin_path/$filename"

        sed -i -e "s/@package_name@/CodecPack/" "$cp_bin_path/$filename"
        sed -i -e "s/@ffmpeg_version@/ffmpeg$ffmpegversion/" "$cp_bin_path/$filename"
      fi
    done

    if [[ -d "$cp_path/lib/gstreamer" ]]; then
      gst_lib_path="$cp_path/lib/gstreamer/patch"
      gst_plugin_path="$cp_path/lib/gstreamer/gstreamer-1.0/patch"

      info "Downloading CodecPack's gstreamer plugins..."

      mkdir "$gst_plugin_path"
      for plugin in "${gstreamer_plugins[@]}"; do
        download "Gstreamer plugin: $plugin" "$repo_base_url/$branch/plugins/$plugin.so" "$gst_plugin_path/$plugin.so"
      done

      mkdir "$gst_lib_path"
      mkdir -p "$gst_lib_path/dri"
      mkdir -p "$gst_lib_path/x264-10bit"
      mkdir -p "$gst_lib_path/x265-10bit"

      for lib in "${gstreamer_libs[@]}"; do
        download "Gstreamer library: $lib" "$repo_base_url/$branch/libs/$lib" "$gst_lib_path/$lib"
      done
    fi
  fi

  if [[ -f "$vs_path/bin/gst-launch-1.0" ]]; then
    gst_lib_path="$vs_path/lib/gstreamer/patch"
    gst_plugin_path="$vs_path/lib/gstreamer/gstreamer-1.0/patch"

    info "Downloading gstreamer plugins..."

    mkdir "$gst_plugin_path"
    for plugin in "${gstreamer_plugins[@]}"; do
      download "Gstreamer plugin: $plugin" "$repo_base_url/$branch/plugins/$plugin.so" "$gst_plugin_path/$plugin.so"
    done

    mkdir "$gst_lib_path"
    mkdir -p "$gst_lib_path/dri"
    mkdir -p "$gst_lib_path/x264-10bit"
    mkdir -p "$gst_lib_path/x265-10bit"

    for lib in "${gstreamer_libs[@]}"; do
      download "Gstreamer library: $lib" "$repo_base_url/$branch/libs/$lib" "$gst_lib_path/$lib"
    done

    info "Saving current GSTOmx configuration..."
    mv -n "$vs_path/etc/gstomx.conf" "$vs_path/etc/gstomx.conf.orig"

    info "Injecting GSTOmx configuration..."
    cp -n "$cp_path/etc/gstomx.conf" "$vs_path/etc/gstomx.conf"
  fi

  info "Saving current libsynovte.so as libsynovte.so.orig"
  cp -n "$libsynovte_path" "$libsynovte_path.orig"
  chown VideoStation:VideoStation "$libsynovte_path.orig"

  info "Enabling eac3, dts and truehd"
  sed -i -e 's/eac3/3cae/' -e 's/dts/std/' -e 's/truehd/dheurt/' "$libsynovte_path"

  clear_cache
  clean

  success "Done patching, you can now enjoy your movies ;) (please add a star to the repo if it worked for you)"
}

unpatch() {
  info "====== Unpatch procedure ======"

  if [[ -f "$libsynovte_path.orig" ]]; then
    info "Restoring libsynovte.so"
    mv -T -f "$libsynovte_path.orig" "$libsynovte_path"
  else
    info "libsynovte.so was not patched, keeping actual file."
  fi

  find "$vs_path/bin" -type f -name "*.orig" | while read -r filename; do
    info "Restoring VideoStation's $filename"
    mv -T -f "$filename" "${filename::-5}"
  done

  if [[ -d $cp_bin_path ]]; then
    for file in "${cp_to_patch[@]}"; do
      filename="${file%%:*}"
      target="${file##*:}"

      rm -f "$cp_bin_path/$target"

      if [[ -f  "$cp_bin_path/$filename.orig" ]]; then
        info "Restoring CodecPack's $filename"
        mv -T -f "$cp_bin_path/$filename.orig" "$cp_bin_path/$filename"
      fi
    done

    if [[ -d "$cp_path/lib/gstreamer" ]]; then
      info "Removing CodecPack gstreamer's patched libraries and plugins"
      rm -rf "$cp_path/lib/gstreamer/patch"
      rm -rf "$cp_path/lib/gstreamer/gstreamer-1.0/patch"
    fi
  fi

  if [[ -f "$vs_path/bin/gst-launch-1.0" ]]; then
    info "Removing VideoStation gstreamer's patched libraries and plugins"
    rm -rf "$vs_path/lib/gstreamer/patch"
    rm -rf "$vs_path/lib/gstreamer/gstreamer-1.0/patch"

    if [[ -f "$vs_path/etc/gstomx.conf.orig" ]]; then
      info "Restoring GSTOmx configuration..."
      mv -T -f "$vs_path/etc/gstomx.conf.orig" "$vs_path/etc/gstomx.conf"
    else
      info "GSTOmx configuration was not patched, keeping actual file."
    fi
  fi

  clear_cache
  clean

  success "Unpatch complete"
}

################################
# ENTRYPOINT
################################
root_check

while getopts a:b:p:v: flag; do
  case "${flag}" in
    a) action=${OPTARG};;
    b) branch=${OPTARG};;
    p) repo_base_url="${OPTARG}/AlexPresso/VideoStation-FFMPEG-Patcher";;
    v) ffmpegversion="${OPTARG}";;
    *) echo "usage: $0 [-a patch|unpatch] [-b branch] [-p http://proxy] [-v ffmpegVersion]" >&2; exit 1;;
  esac
done

if [[ "$ffmpegversion" == "4" ]]; then
  ffmpegversion=""
fi

dependencies=("VideoStation" "ffmpeg$ffmpegversion")

welcome_motd

info "You're running DSM $dsm_version"
if [[ -d /var/packages/CodecPack/target/pack ]]; then
  cp_path="$cp_base_path/target/pack"
  cp_bin_path="$cp_path/bin"
  info "Tuned script for DSM $dsm_version"
fi

case "$action" in
  unpatch) unpatch;;
  patch) patch;;
esac

