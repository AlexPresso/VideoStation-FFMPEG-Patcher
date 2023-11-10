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

# shellcheck source=/utils/patch_utils.sh
source "/var/packages/VideoStation/patch/patch_utils.sh" || source "/var/packages/CodecPack/patch/patch_utils.sh"

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
