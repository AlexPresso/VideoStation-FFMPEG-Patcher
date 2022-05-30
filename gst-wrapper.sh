#!/bin/bash

#########################
# VARS
#########################

pid=$$
defaultargs=($@)
hlsslice=${@: -1}
hlsroot=${hlsslice::-14}
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

function endprocess() {
  info "========================================[end gst $pid]"
  newline
  rm "$stderrfile"
}

#########################
# ENTRYPOINT
#########################

trap endprocess SIGTERM

newline
info "========================================[start gst $pid]"
info "GST_ARGS: ${defaultargs[*]}"

/var/packages/gstreamer/target/bin/gst-launch-1.0 "${defaultargs[@]}" 2> $stderrfile
