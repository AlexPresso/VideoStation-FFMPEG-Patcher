#!/bin/bash

#########################
# VARS
#########################

ffmpeg_version=@ffmpeg_version@
pid=$$
child=""
stderrfile="/tmp/ffmpeg-$pid.stderr"
errcode=0
path=$(realpath "$0")
args=()

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

fix_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -ss)
        shift
        args+=("-ss" "$1" "-noaccurate_seek")
        ;;

      -acodec)
        shift
        if [[ "$1" = "libfaac" ]]; then
          args+=("-acodec" "aac")
        else
          args+=("-acodec" "libfdk_aac")
        fi
        ;;

      -vf)
        shift
        arg="$1"

        if [[ "$arg" =~ "scale_vaapi" ]]; then
          scale_w=$(echo "$arg" | sed -n 's/.*w=\([0-9]\+\):h=\([0-9]\+\).*/\1/p')
          scale_h=$(echo "$arg" | sed -n 's/.*w=\([0-9]\+\):h=\([0-9]\+\).*/\2/p')

          if (( scale_w && scale_h )); then
            arg="format=nv12|vaapi,hwupload,scale_vaapi=w=$scale_w:h=$scale_h:format=nv12,setsar=sar=1"
          else
            arg="format=nv12|vaapi,hwupload,scale_vaapi=format=nv12,setsar=sar=1"
          fi
        fi

        args+=("-vf" "$arg")
        ;;

      -r)
        shift
        ;;

      *) args+=("$1") ;;
    esac

    shift
  done
}

#########################
# ENTRYPOINT
#########################

trap endprocess SIGINT SIGTERM
trap handle_error ERR

rm -f /tmp/ffmpeg*.stderr.prev

fix_args "$@"

newline
info "========================================[start $0 $pid]"
info "DEFAULT ARGS: $*"
info "UPDATED ARGS: ${args[*]}"

info "Trying fixed args with $path.orig ..."
"${path}.orig" "${args[@]}" <&0 2>> $stderrfile &
child=$!
wait "$child"

if [[ $errcode -eq 0 ]]; then
  endprocess
fi

errcode=0
info "Trying default args with $path.orig ..."
"${path}.orig" "$@" <&0 2>> $stderrfile &
child=$!
wait "$child"

if [[ $errcode -eq 0 ]]; then
  endprocess
fi

errcode=0
info "Trying with SC's $ffmpeg_version and fixed args..."
"/var/packages/${ffmpeg_version}/target/bin/ffmpeg" "${args[@]}" <&0 2>> $stderrfile &
child=$!
wait "$child"

endprocess
