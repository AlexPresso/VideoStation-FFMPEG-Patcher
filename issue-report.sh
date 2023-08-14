#!/bin/bash

###############################
# VARS
###############################

# shellcheck source=/.github/workflows/mock/VERSION
source "/etc/VERSION"
dsm_version="$productversion $buildnumber-$smallfixnumber"
vs_path=/var/packages/VideoStation
cp_path=/var/packages/CodecPack

###############################
# UTILS
###############################

function root_check() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "This tool needs root access (please run 'sudo -i' before proceeding)."
    exit 1
  fi
}

################################
# ENTRYPOINT
################################

root_check

echo "
================ ISSUE REPORT TOOL ================

System Details.....................................
  DSM Version: $dsm_version
  Arch details: $(uname -a)

Package Details....................................
  VideoStation version: $(synopkg version VideoStation || echo "Not installed")
  FFMPEG version: $(synopkg version ffmpeg || echo "Not installed")
  CodecPack version: $(synopkg version CodecPack || echo "Not installed")

Patch Details......................................
  Is patched ? $([ -f "$vs_path/target/lib/libsynovte.so.orig" ] && echo "yes" || echo "no")
  Has gstreamer ? $([ -f "$vs_path/target/bin/gst-launch-1.0" ] && echo "yes" || echo "no")
"

echo "  CodecPack target/bin content:"
ls -l "$cp_path/target/bin"
echo ""
echo "  CodecPack target/pack/bin content:"
ls -l "$cp_path/target/pack/bin"

echo ""
echo "Gstreamer last stderr logs........................."
tail -22 /tmp/gstreamer*.stderr

echo ""
echo "FFMPEG head logs..................................."
head /tmp/ffmpeg*.stderr
echo ""
echo "FFMPEG last stderr logs............................"
tail -22 /tmp/ffmpeg*.stderr

