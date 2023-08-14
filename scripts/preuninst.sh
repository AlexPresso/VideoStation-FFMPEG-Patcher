#!/bin/sh

repo_full_url=@repo_full_url
curl "$repo_full_url/patcher.sh" | bash -s -- -a unpatch

exit 0
