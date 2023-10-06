#!/bin/bash

#########################
# VARS
#########################

ffmpeg_version=ffmpeg
pid=$$
child=""
stderrfile="/tmp/ffmpeg-$pid.stderr"
errcode=0

# shellcheck source=/patch_config.sh
source "/var/packages/VideoStation/patch_config.sh"

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
  kill_child
}

kill_child() {
  if [[ "$child" != "" ]]; then
    kill "$child"
  fi
}

endprocess() {
  info "========================================[end ffmpeg $pid]"
  newline

  if [[ $errcode -eq 1 ]]; then
    cat "$stderrfile" >> "$stderrfile.prev"
  fi

  kill_child
  rm -f "$stderrfile"

  exit $errcode
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

      -pix_fmt)
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
info "========================================[start ffmpeg $pid]"
info "DEFAULT ARGS: $*"
info "UPDATED ARGS: ${args[*]}"

info "Trying with VideoStation's ffmpeg with fixed args..."
/var/packages/VideoStation/target/bin/ffmpeg.orig "${args[@]}" <&0 2>> $stderrfile &
child=$!
wait "$child"

if [[ $errcode -eq 0 ]]; then
  endprocess
fi

info "Trying with VideoStation's ffmpeg with default args..."
/var/packages/VideoStation/target/bin/ffmpeg.orig "${@}" <&0 2>> $stderrfile &
child=$!
wait "$child"

if [[ $errcode -eq 0 ]]; then
  endprocess
fi

info "Trying with SC's ffmpeg and fixed args..."
"/var/packages/${ffmpeg_version}/target/bin/ffmpeg" "${args[@]}" <&0 2>> $stderrfile &
child=$!
wait "$child"

endprocess
