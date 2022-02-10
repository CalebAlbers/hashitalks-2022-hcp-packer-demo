#! /usr/bin/env bash

set -eEuo pipefail

usage() {
  cat <<EOF
This script checks for a 200 OK response from a supplied URL

Usage:
   $(basename "$0") <url>

Example:
  > $(basename "$0") https://example.com/api/v2/healthz
      [Check: 1/25] Service is not ready yet, retrying in 5 seconds...
      [Check: 2/25] Service is not ready yet, retrying in 5 seconds...
      🎉 Service is up! 🎉
EOF
  exit 1
}

test "$#" -eq 1 || usage

host="$1"

i=1
interval=5 # check every 5 seconds
max_attempts=25 # 5 minutes

until $(curl --output /dev/null --silent --head --fail "$host"); do
    if [ ${i} -ge ${max_attempts} ];then
      echo "Service state is unhealthy after ${i} attempts... failing health check."
      exit 1
    fi

    echo "[Check: ${i}/${max_attempts}] Service is not ready yet, retrying in ${interval} seconds..."
    i=$(($i + 1))

    sleep $interval
done

echo "🎉 Service is up! 🎉"
