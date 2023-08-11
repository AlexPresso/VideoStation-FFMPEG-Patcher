#!/bin/sh

repo_base_url="https://raw.githubusercontent.com/AlexPresso/VideoStation-FFMPEG-Patcher"
curl "$repo_base_url/main/patcher.sh" | bash -s -- -a unpatch

exit 0
