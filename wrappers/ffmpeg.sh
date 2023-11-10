#!/bin/bash

#########################
# VARS
#########################

ffmpeg_version=ffmpeg
pid=$$
child=""
stderrfile="/tmp/ffmpeg-$pid.stderr"
errcode=0
path=$(realpath "$0")
args=()

# shellcheck source=/patch_config.sh
source "/var/packages/VideoStation/patch/patch_config.sh" | source "/var/packages/CodecPack/patch/patch_config.sh"
# shellcheck source=/utils/patch_utils.sh
source "/var/packages/VideoStation/patch/patch_utils.sh" | source "/var/packages/CodecPack/patch/patch_utils.sh"

#########################
# UTILS
#########################

trap endprocess SIGINT SIGTERM
trap handle_error ERR

rm -f /tmp/ffmpeg*.stderr.prev

fix_args "$@"

newline
info "========================================[start ffmpeg $pid]"
info "DEFAULT ARGS: $*"
info "UPDATED ARGS: ${args[*]}"

info "Trying fixed args with $path..."
"${path}.orig" "${args[@]}" <&0 2>> $stderrfile &
child=$!
wait "$child"

if [[ $errcode -eq 0 ]]; then
  endprocess
fi

errcode=0
info "Trying default args with $path..."
"${path}.orig" "$@" <&0 2>> $stderrfile &
child=$!
wait "$child"

if [[ $errcode -eq 0 ]]; then
  endprocess
fi

errcode=0
info "Trying with SC's ffmpeg and fixed args..."
"/var/packages/${ffmpeg_version}/target/bin/ffmpeg" "${args[@]}" <&0 2>> $stderrfile &
child=$!
wait "$child"

endprocess
