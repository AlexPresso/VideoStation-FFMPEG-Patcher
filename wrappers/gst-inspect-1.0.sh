#!/bin/bash

export GST_DEBUG=1 #1: ERROR (Log fatal errors only).

#########################
# VARS
#########################

pid=$$
child=""
stderrfile="/tmp/gstinspect-$pid.stderr"
path=$(realpath "$0")
errcode=0

#########################
# UTILS
#########################

log() {
  local now
  now=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$now] [$1] $2" >> "$stderrfile"
}

newline() {
  echo "" >> "$stderrfile"
}

info() {
  log "INFO" "$1"
}

kill_child() {
  if [[ "$child" != "" ]]; then
    kill "$child" > /dev/null 2> /dev/null || :
  fi
}

endprocess() {
  info "========================================[end $0 $pid]"
  newline

  if [[ $errcode -eq 1 ]]; then
    cp "$stderrfile" "$stderrfile.prev"
  fi

  kill_child
  rm -f "$stderrfile"

  exit "$errcode"
}

handle_error() {
  log "ERROR" "An error occurred"
  newline
  errcode=1
  kill_child
}

#########################
# ENTRYPOINT
#########################

trap endprocess SIGINT SIGTERM
trap handle_error ERR

rm -f /tmp/gstinspect*.stderr.prev

newline
info "========================================[start gst-inspect $pid]"
info "GST_ARGS: $*"

"$path.orig" "$@" 2>> $stderrfile &

child=$!
wait "$child"

endprocess
