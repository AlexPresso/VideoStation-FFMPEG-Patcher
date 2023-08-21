#!/bin/bash

#########################
# VARS
#########################

pid=$$
child=""
stderrfile="/tmp/gstinspect-$pid.stderr"
errcode=0

#########################
# UTILS
#########################

log() {
  local now
  now=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$now] [$1] $2" >> $stderrfile
}
newline() {
  echo "" >> $stderrfile
}
info() {
  log "INFO" "$1"
}

handle_error() {
  log "ERROR" "An error occurred"
  newline
  errcode=1
  endprocess
}

endprocess() {
  info "========================================[end gst $pid]"
  newline

  if [[ $errcode -eq 1 ]]; then
    cp "$stderrfile" "$stderrfile.prev"
  fi

  rm "$stderrfile"

  if [[ "$child" != "" ]]; then
    kill "$child"
  fi

  exit $errcode
}

#########################
# ENTRYPOINT
#########################

trap endprocess SIGINT SIGTERM
trap handle_error ERR

rm -f "/tmp/gstinspect*.stderr.prev"

newline
info "========================================[start gst-inspect $pid]"
info "GST_ARGS: $*"

/var/packages/VideoStation/target/bin/gst-inspect-1.0.orig "$@" 2>> $stderrfile &

child=$!
wait "$child"

endprocess