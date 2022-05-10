#!/bin/bash

#########################
# VARS
#########################

pid=$$
defaultargs=${@:3}
hlsslice=${@: -1}
hlsroot=${hlsslice::-14}
stderrfile="/tmp/ffmpeg-$pid.stderr"

#########################
# UTILS
#########################

function log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2" >> /tmp/ffmpeg.log
}
function info() {
	log "INFO" "$1"
}

#########################
# ENTRYPOINT
#########################

movie=$(cat "$hlsroot/video_metadata" | jq -r ".path")

info "========================================[$pid]"
info "MOVIE: $movie"
info "HLS_ROOT: $hlsroot"
info "DEFAULT_ARGS: ${defaultargs[*]}"

declare -a args=(
    "-i" "'$movie'"
    "${defaultargs[@]}"
    "$hlsroot/slice-%05d.ts"
)

info "ARGS: ${args[*]}"
/var/packages/ffmpeg/target/bin/ffmpeg "${args[@]}" 2> $stderrfile &

#rm $stderrfile
