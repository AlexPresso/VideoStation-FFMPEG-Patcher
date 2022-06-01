#!/bin/bash

#########################
# VARS
#########################

pid=$$
hlsslice=${*: -1}
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

function handle_error() {
  log "ERROR" "Error on line $(caller)}"
  endprocess
}

function endprocess() {
  info "========================================[end ffmpeg $pid]"
  newline
  rm -f "$stderrfile"
  exit 1
}

#########################
# ENTRYPOINT
#########################

trap endprocess SIGTERM
trap handle_error ERR

newline
info "========================================[start ffmpeg $pid]"

info "HLS_ROOT: $hlsroot"
info "DEFAULT_ARGS: $*"
movie=$(cat "$hlsroot/video_metadata" | jq -r ".path")
info "MOVIE: $movie"

/var/packages/ffmpeg/target/bin/ffmpeg "$@" 2> $stderrfile
