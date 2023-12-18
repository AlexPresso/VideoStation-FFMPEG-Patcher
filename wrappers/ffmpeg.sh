#!/bin/bash

# shellcheck source=/utils/patch_utils.sh
source "/var/packages/VideoStation/patch/patch_utils.sh" 2> /tmp/ffmpeg-0.stderr.prev ||
source "/var/packages/CodecPack/patch/patch_utils.sh" 2> /tmp/ffmpeg-0.stderr.prev ||
{ echo "Cannot load patch_utils.sh" >> "/tmp/ffmpeg-0.stderr.prev" && echo "Cannot load patch_utils.sh" && exit 1; }

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

#########################
# LOAD CONFIG
#########################

# shellcheck source=/utils/patch_config.sh
source "/var/packages/VideoStation/patch/patch_config.sh" 2> /tmp/ffmpeg-0.stderr.prev ||
source "/var/packages/CodecPack/patch/patch_config.sh" 2> /tmp/ffmpeg-0.stderr.prev ||
{ echo "Cannot load patch_config.sh" >> "/tmp/ffmpeg-0.stderr.prev" && echo "Cannot load patch_config.sh" && exit 1; }

#########################
# ENTRYPOINT
#########################

trap endprocess SIGINT SIGTERM
trap handle_error ERR

rm -f /tmp/ffmpeg*.stderr.prev

fix_args "$@"

newline
info "========================================[start $0 $pid]"
info "DEFAULT ARGS: $*"
info "UPDATED ARGS: ${args[*]}"

info "Trying fixed args with $path.orig ..."
"${path}.orig" "${args[@]}" <&0 2>> $stderrfile &
child=$!
wait "$child"

if [[ $errcode -eq 0 ]]; then
  endprocess
fi

errcode=0
info "Trying default args with $path.orig ..."
"${path}.orig" "$@" <&0 2>> $stderrfile &
child=$!
wait "$child"

if [[ $errcode -eq 0 ]]; then
  endprocess
fi

errcode=0
info "Trying with SC's $ffmpeg_version and fixed args..."
"/var/packages/${ffmpeg_version}/target/bin/ffmpeg" "${args[@]}" <&0 2>> $stderrfile &
child=$!
wait "$child"

endprocess
