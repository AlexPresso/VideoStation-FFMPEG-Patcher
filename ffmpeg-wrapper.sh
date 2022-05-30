#!/bin/bash

#########################
# VARS
#########################

pid=$$
defaultargs=($@)
hlsslice=${@: -1}
hlsroot=${hlsslice::-14}
stderrfile="/tmp/ffmpeg-$pid.stderr"
logfile="/tmp/ffmpeg.log"

#########################
# UTILS
#########################

function log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2" >> $logfile
}
function newline() {
    echo "" >> $logfile
}
function info() {
    log "INFO" "$1"
}

function endprocess() {
    info "========================================[end ffmpeg $pid]"
    newline
    rm "$stderrfile"
}

#########################
# ENTRYPOINT
#########################

trap endprocess SIGTERM

movie=$(cat "$hlsroot/video_metadata" | jq -r ".path")

newline
info "========================================[start ffmpeg $pid]"
info "MOVIE: $movie"
info "HLS_ROOT: $hlsroot"
info "DEFAULT_ARGS: ${defaultargs[*]}"

/var/packages/ffmpeg/target/bin/ffmpeg "${defaultargs[@]}" 2> $stderrfile
