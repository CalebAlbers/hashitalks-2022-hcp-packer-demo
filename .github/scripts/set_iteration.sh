#! /usr/bin/env bash

set -eEuo pipefail

usage() {
  cat <<EOF
This script is a helper for setting a channel iteration in HCP Packer

Usage:
   $(basename "$0") <bucket_slug> <channel_name> <iteration_id>

---

Requires the following environment variables to be set:
 - HCP_CLIENT_ID
 - HCP_CLIENT_SECRET
 - HCP_ORGANIZATION_ID
 - HCP_PROJECT_ID
EOF
  exit 1
}

auth() {
  token=$(curl --request POST --silent \
    --url 'https://auth.hashicorp.com/oauth/token' \
    --data grant_type=client_credentials \
    --data client_id="$HCP_CLIENT_ID" \
    --data client_secret="$HCP_CLIENT_SECRET" \
    --data audience="https://api.hashicorp.cloud")
  echo "$token" | jq -r '.access_token'
}


# Entry point
test "$#" -eq 3 || usage

bucket_slug="$1"
channel_name="$2"
iteration_id="$3"

base_url="https://api.cloud.hashicorp.com/packer/2021-04-30/organizations/$HCP_ORGANIZATION_ID/projects/$HCP_PROJECT_ID"

# authenticate
bearer=$(auth)

curl --request PATCH \
  --url "$base_url/images/$bucket_slug/channels/$channel_name" \
  --data-raw '{"iteration_id":"'"$iteration_id"'"}' \
  --header "authorization: Bearer $bearer"
