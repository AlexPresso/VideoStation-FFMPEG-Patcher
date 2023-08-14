#!/bin/sh

curl "@repo_base_url@/@branch@/patcher.sh" | bash -s -- -a unpatch

exit 0
