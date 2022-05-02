#!/bin/bash

###############################
#   VARS
###############################

dsm_version=$(cat /etc.defaults/VERSION | grep productversion | sed 's/productversion=//' | tr -d '"')
repo_base_url=https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher
vs_bin_path=/var/packages/VideoStation/target/bin
cp_bin_path=/var/packages/CodecPack/target/bin
declare -a cp_to_patch=("ffmpeg41" "ffmpeg27")
ffmpeg_bin_path=/var/packages/ffmpeg/target/bin
libsynovte_path=/var/packages/VideoStation/target/lib/libsynovte.so

###############################
#   UTILS
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

function welcome_motd() {
    info "ffmpeg-patcher v1.5"

    motd=$(curl -s -L "$repo_base_url/blob/main/motd.txt?raw=true")
    if [ "${#motd}" -ge 1 ]; then
        log "Message of the day"
        echo ""
        echo "$motd"
        echo ""
    fi
}

function restart_packages() {
    if [[ -d $cp_bin_path ]]; then
        log "INFO" "Restarting CodecPack..."
        synopkg restart CodecPack
    fi

    info "Restarting VideoStation..."
    synopkg restart VideoStation
}

function check_dependencies() {
    if [[ ! -d $ffmpeg_bin_path ]]; then
        error "Missing SynoCommunity ffmpeg package, please install it and re-run the patcher."
        exit 1
    fi
}

################################
#   PATCH PROCEDURES
################################

function patch() {
    info "====== Patching procedure ======"

    info "Saving current ffmpeg as ffmpeg.orig"
    mv -n "$vs_bin_path/ffmpeg" "$vs_bin_path/ffmpeg.orig"

    info "Downloading ffmpeg's wrapper..."
    wget -q -O - "$repo_base_url/blob/main/ffmpeg-wrapper.sh?raw=true" > "$vs_bin_path/ffmpeg"
    chown root:VideoStation "$vs_bin_path/ffmpeg"
    chmod 750 "$vs_bin_path/ffmpeg"
    chmod u+s "$vs_bin_path/ffmpeg"

    if [[ -d $cp_bin_path ]]; then
        for filename in "${cp_to_patch[@]}"; do
            info "Patching CodecPack's $filename"

            mv -n "$cp_bin_path/$filename" "$cp_bin_path/$filename.orig"
            ln -s -f "$vs_bin_path/ffmpeg" "$cp_bin_path/$filename"
        done
    fi

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
    mv -f "$libsynovte_path.orig" "$libsynovte_path"

    info "Restoring VideoStation's ffmpeg"
    mv -f "$vs_bin_path/ffmpeg.orig" "$vs_bin_path/ffmpeg"

    if [[ -d $cp_bin_path ]]; then
        find $cp_bin_path -type f -name "ffmpeg*.orig" | while read filename
        do
            info "Restoring CodecPack's $filename"
            mv -T -f "$filename" "${filename::-5}"
        done
    fi

    restart_packages

    echo ""
    info "unpatch complete"
}

################################
#   ENTRYPOINT
################################
welcome_motd
arg1=${1:--patch}

check_dependencies

info "You're running DSM $dsm_version"
if [[ $dsm_version = "7.1" ]]; then
    cp_bin_path=/var/packages/CodecPack/target/pack/bin

    info "Tuned script for DSM 7.1"
fi

case "$arg1" in
    -unpatch)
        unpatch
    ;;
    -patch)
        patch
    ;;
esac
