#!/bin/bash

###############################
# VARS
###############################

source "/etc/VERSION"
cpu_platform=$(</proc/syno_platform)
dsm_version="$productversion $buildnumber-$smallfixnumber"
repo_base_url="https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher"
version="2.0"
action="patch"
branch="main"
ffmpegversion=""
wrappers=(
  "ffmpeg"
  "gst-launch-1.0"
  "gst-inspect-1.0"
)

vs_path=/var/packages/VideoStation/target
libsynovte_path="$vs_path/lib/libsynovte.so"
cp_path=/var/packages/CodecPack/target/pack
cp_bin_path="$cp_path/bin"
cp_to_patch=(
  "ffmpeg41:ffmpeg"
  "ffmpeg27:ffmpeg"
  "ffmpeg33:ffmpeg"
  "gst-launch-1.0:gst-launch-1.0"
  "gst-inspect-1.0:gst-inspect-1.0"
)

gstreamer_platforms=(
  "REALTEK_RTD1296"
)
gstreamer_plugins=(
  "libgstdtsdec"
)
gstreamer_libs=(
  "libdca.so.0"
  "liborc-0.4.so.0"
  "liborc-test-0.4.so.0"
)

###############################
# UTILS
###############################

function log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2"
}
function info() {
  log "INFO" "$1"
}
function error() {
  log "ERROR" "$1"
}

function root_check() {
  if [[ "$EUID" -ne 0 ]]; then
    error "This tool needs root access (please run 'sudo -i' before proceeding)."
    exit 1
  fi
}

function welcome_motd() {
  info "ffmpeg-patcher v$version"

  motd=$(curl -s -L "$repo_base_url/blob/$branch/motd.txt?raw=true")
  if [ "${#motd}" -ge 1 ]; then
    log "Message of the day"
    echo ""
    echo "$motd"
    echo ""
  fi
}

function restart_packages() {
  if [[ -d $cp_bin_path ]]; then
    info "Restarting CodecPack..."
    synopkg restart CodecPack
  fi

  info "Restarting VideoStation..."
  synopkg restart VideoStation
}

function check_dependencies() {
  missingDeps=false

  for dependency in "${dependencies[@]}"; do
    if [[ ! -d "/var/packages/$dependency" ]]; then
      error "Missing $dependency package, please install it and re-run the patcher."
      missingDeps=true
    fi
  done

  if [[ $missingDeps -eq 1 ]]; then
    exit 1
  fi
}

################################
# PATCH PROCEDURES
################################

function patch() {
  info "====== Patching procedure (branch: $branch) ======"

  for filename in "${wrappers[@]}"; do
    if [[ -f "$vs_path/bin/$filename" ]]; then
      info "Saving current $filename as $filename.orig"
      mv -n "$vs_path/bin/$filename" "$vs_path/bin/$filename.orig"

      info "Downloading and installing $filename's wrapper..."
      wget -q -O - "$repo_base_url/blob/$branch/wrappers/$filename.sh?raw=true" > "$vs_path/bin/$filename"
      chown root:VideoStation "$vs_path/bin/$filename"
      chmod 750 "$vs_path/bin/$filename"
      chmod u+s "$vs_path/bin/$filename"
    fi
  done

  if [[ -d $cp_bin_path ]]; then
    for file in "${cp_to_patch[@]}"; do
      filename="${file%%:*}"
      target="${file##*:}"

      if [[ -f "$cp_bin_path/$filename" ]]; then
        info "Patching CodecPack's $filename"

        mv -n "$cp_bin_path/$filename" "$cp_bin_path/$filename.orig"
        ln -s -f "$vs_path/bin/$target" "$cp_bin_path/$filename"
      fi
    done
  fi

  if [[ "${gstreamer_platforms[*]}" =~ $cpu_platform ]]; then
    info "Downloading gstreamer plugins..."

    for plugin in "${gstreamer_plugins[@]}"; do
      info "Downloading $plugin to gstreamer directory..."

      wget -q -O - "$repo_base_url/blob/$branch/plugins/$plugin.so?raw=true" \
        > "$vs_path/lib/gstreamer/gstreamer-1.0/$plugin.so"
    done

    for lib in "${gstreamer_libs[@]}"; do
      info "Downloading $lib to gstreamer directory..."

      wget -q -O - "$repo_base_url/blob/$branch/libs/$lib.so?raw=true" \
        > "$vs_path/lib/gstreamer/$lib.so"
    done
  fi

  info "Setting ffmpeg version to: ffmpeg$ffmpegversion"
  sed -i -e "s/@ffmpeg_version@/ffmpeg$ffmpegversion/" "$vs_path/bin/ffmpeg"

  info "Saving current libsynovte.so as libsynovte.so.orig"
  cp -n "$libsynovte_path" "$libsynovte_path.orig"
  chown VideoStation:VideoStation "$libsynovte_path.orig"

  info "Enabling eac3, dts and truehd"
  sed -i -e 's/eac3/3cae/' -e 's/dts/std/' -e 's/truehd/dheurt/' "$libsynovte_path"

  restart_packages

  echo ""
  info "Done patching, you can now enjoy your movies ;) (please add a star to the repo if it worked for you)"
}

function unpatch() {
  info "====== Unpatch procedure ======"

  info "Restoring libsynovte.so"
  mv -T -f "$libsynovte_path.orig" "$libsynovte_path"

  find "$vs_path/bin" -type f -name "*.orig" | while read -r filename; do
    info "Restoring VideoStation's $filename"
    mv -T -f "$filename" "${filename::-5}"
  done

  if [[ -d $cp_bin_path ]]; then
    find $cp_bin_path -type f -name "*.orig" | while read -r filename; do
      info "Restoring CodecPack's $filename"
      mv -T -f "$filename" "${filename::-5}"
    done
  fi

  if [[ "${gstreamer_platforms[*]}" =~ $cpu_platform ]]; then
    for plugin in "${gstreamer_plugins[@]}"; do
      info "Removing gstreamer's $plugin plugin"
      rm -f "$vs_path/lib/gstreamer/gstreamer-1.0/$plugin.so"
    done

    for lib in "${gstreamer_libs[@]}"; do
      info "Removing gstreamer's $lib library"
      rm -f "$vs_path/lib/gstreamer/$lib.so"
    done
  fi

  restart_packages

  echo ""
  info "unpatch complete"
}

################################
# ENTRYPOINT
################################
root_check
check_dependencies

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
  cp_bin_path=/var/packages/CodecPack/target/pack/bin
  info "Tuned script for DSM $dsm_version"
fi

case "$action" in
  unpatch) unpatch;;
  patch) patch;;
esac

