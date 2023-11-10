#!/bin/bash

export GST_DEBUG=1 #1: ERROR (Log fatal errors only).

# shellcheck source=/utils/patch_utils.sh
source "/var/packages/VideoStation/patch/patch_utils.sh" 2> /dev/null ||
source "/var/packages/CodecPack/patch/patch_utils.sh" 2> /dev/null ||
{ echo "Cannot load patch_utils.sh" >> "gstlaunch-0.stderr.prev" && echo "Cannot load patch_utils.sh" && exit 1; }

#########################
# VARS
#########################

pid=$$
child=""
stderrfile="/tmp/gstlaunch-$pid.stderr"
path=$(realpath "$0")
errcode=0

#########################
# ENTRYPOINT
#########################

trap endprocess SIGINT SIGTERM
trap handle_error ERR

rm -f /tmp/gstlaunch*.stderr.prev

newline
info "========================================[start $0 $pid]"
info "GST_ARGS: $*"

"$path.orig" "$@" 2>> $stderrfile &

child=$!
wait "$child"

endprocess
