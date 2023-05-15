#!/bin/bash

###############################
# VARS
###############################

source "/etc/VERSION"
dsm_version="$productversion $buildnumber-$smallfixnumber"
repo_base_url="https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher"
version="2.0"
action="patch"
branch="main"
ffmpegversion=""
wrappers=("ffmpeg")

vs_path=/var/packages/VideoStation/target
libsynovte_path="$vs_path/lib/libsynovte.so"
cp_bin_path=/var/packages/CodecPack/target/bin
cp_to_patch=(
  "ffmpeg41:ffmpeg"
  "ffmpeg27:ffmpeg"
  "ffmpeg33:ffmpeg"
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
      wget -q -O - "$repo_base_url/blob/$branch/$filename-wrapper.sh?raw=true" > "$vs_path/bin/$filename"
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

  info "Creating symlink to ffmpeg$ffmpegversion"
  ln -s -f "$vs_path/bin/wrapper_ffmpeg" "/var/packages/ffmpeg$ffmpegversion/target/bin/ffmpeg"

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

  info "Deleting symlink to ffmpeg$ffmpegversion"
  rm -f "$vs_path/bin/wrapper_ffmpeg"

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

