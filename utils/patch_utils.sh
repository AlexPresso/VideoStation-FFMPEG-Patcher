#!/bin/bash

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
  kill_child
}

fix_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
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
            arg="scale_vaapi=w=$scale_w:h=$scale_h:format=nv12,hwupload,setsar=sar=1"
          else
            arg="scale_vaapi=format=nv12,hwupload,setsar=sar=1"
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