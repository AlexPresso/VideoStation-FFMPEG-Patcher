#!/bin/bash

#########################
# VARS
#########################

pid=$$
childpid=""
defaultargs=(${@:3})
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

function killchild() {
    rm $stderrfile

    if [[ "$childpid" -ne "" ]]; then
        info "Killed child ($childpid)"
        kill -TERM "$childpid" 2>/dev/null
    fi
}

#########################
# ENTRYPOINT
#########################

trap killchild SIGTERM

movie=$(cat "$hlsroot/video_metadata" | jq -r ".path")

info "========================================[$pid]"
info "MOVIE: $movie"
info "HLS_ROOT: $hlsroot"
info "DEFAULT_ARGS: ${defaultargs[*]}"

declare -a args=(
    "-i" "$movie"
    "${defaultargs[@]}"
)

info "ARGS: ${args[*]}"
/var/packages/ffmpeg/target/bin/ffmpeg "${args[@]}" 2> $stderrfile &

childpid=$!
wait $childpid

