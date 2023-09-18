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
          scale_w=$(echo "$arg" | sed -e 's/.*=w=//g' | sed -e 's/:h=.*//g')
          # shellcheck disable=SC2001
          scale_h=$(echo "$arg" | sed -e 's/.*:h=//g')
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

"/var/packages/${ffmpeg_version}/target/bin/ffmpeg" "${args[@]}" <&0 2>> $stderrfile &

child=$!
wait "$child"

endprocess
