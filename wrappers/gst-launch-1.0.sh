#!/bin/bash

#########################
# VARS
#########################

pid=$$
child=""
stderrfile="/tmp/gstlaunch-$pid.stderr"
errcode=0

#########################
# UTILS
#########################

function log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2" >> $stderrfile
}
function newline() {
  echo "" >> $stderrfile
}
function info() {
  log "INFO" "$1"
}

function handle_error() {
  log "ERROR" "An error occurred"
  newline
  errcode=1
  endprocess
}

function endprocess() {
  info "========================================[end gst $pid]"
  newline
  rm "$stderrfile"

  if [[ "$child" != "" ]]; then
      kill -9 "$child"
  fi

  exit $errcode
}

#########################
# ENTRYPOINT
#########################

trap endprocess SIGTERM
trap handle_error ERR

newline
info "========================================[start gst-launch $pid]"
info "GST_ARGS: $*"

/var/packages/VideoStation/target/bin/gst-launch-1.0.orig "$@" 2> $stderrfile &

child=$!
wait $child

endprocess