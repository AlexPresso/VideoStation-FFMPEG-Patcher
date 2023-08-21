#!/bin/bash

#########################
# VARS
#########################

pid=$$
child=""
stderrfile="/tmp/ffmpeg-$pid.stderr"
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
  info "========================================[end ffmpeg $pid]"
  newline

  if [[ $errcode -eq 1 ]]; then
    cp "$stderrfile" "$stderrfile.prev"
  fi

  rm -f "$stderrfile"

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

rm -f /tmp/ffmpeg*.stderr.prev

newline
info "========================================[start ffmpeg $pid]"
info "DEFAULT ARGS: $*"

/var/packages/@ffmpeg_version@/target/bin/ffmpeg "$@" <&0 2>> $stderrfile &

child=$!
wait "$child"

endprocess
