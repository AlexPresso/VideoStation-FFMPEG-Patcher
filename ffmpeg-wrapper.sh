#!/bin/bash

#########################
# VARS
#########################

pid=$$
movie=""
hlsslice=${@: -1}
hlsroot=${hlsslice::-14}
metadata=$(cat "$hlsroot/video_metadata")
stderrfile="/tmp/ffmpeg-$pid.stderr"

#########################
# UTILS
#########################

function log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2" >> /tmp/ffmpeg.log
}
function info() {
	log "INFO" "$1"
}

#########################
# ENTRYPOINT
#########################

movie=$(echo $metadata | jq -r ".path")
profile=$(echo $metadata | jq -r ".profile_value" | sed -e 's/--/-/g')
seektime=$(cat "$hlsroot/seek_time" || echo 00000)
audiotrack=$(cat "$hlsroot/audio_id")

info "========================================[$pid]"
info "MOVIE: $movie"
info "HLS_ROOT: $hlsroot"
info "PROFILE: $profile"
info "START_TIME: $seektime"
info "AUDIO_ID: $audiotrack"

declare -a args=("-i" "'$movie'")

args+=("${profile[@]}")
args+=("-ss" "$seektime")
args+=("$hlsroot/slice-%05d.ts")

info "ARGS: ${args[*]}"
/var/packages/ffmpeg/target/bin/ffmpeg "${args[@]}" 2> $stderrfile &

rm $stderrfile
