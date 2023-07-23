#!/bin/bash

#########################
# VARS
#########################

pid=$$
stderrfile="/tmp/gstlaunch-$pid.stderr"
logfile="/tmp/gstreamer.log"

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
  log "ERROR" "An error occurred, here is the $stderrfile content: "
  newline
  cat "$stderrfile" >> $logfile
  newline
  endprocess
}

function endprocess() {
  info "========================================[end gst $pid]"
  newline
  rm "$stderrfile"
  exit 1
}

#########################
# ENTRYPOINT
#########################

trap endprocess SIGTERM
trap handle_error ERR

newline
info "========================================[start gst $pid]"
info "GST_ARGS: $*"

/var/packages/CodecPack/target/pack/bin/gst-launch-1.0.orig "$@" 2> $stderrfile
