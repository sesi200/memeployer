#!/usr/bin/env bash

set -uo pipefail

COMMITS=$(curl -sLf -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/dfinity/ic/commits?per_page=100" |
  jq '.[].sha' | tr -d \")

if [ "$?" -ne "0" ]; then
  echo >&2 "Unable to fetch the commits from dfinity/ic. Please try again"
  exit 1
fi

for COMMIT in $COMMITS; do
  STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L --head \
    "https://download.dfinity.systems/ic/$COMMIT/canisters/ledger-canister_notify-method.wasm.gz")
  if (($STATUS_CODE >= 200)) && (($STATUS_CODE < 300)); then
    echo "Found artifacts for commit $COMMIT. Downloading..."

    declare -A downloads=(
      ["https://raw.githubusercontent.com/dfinity/ic/\$COMMIT/rs/rosetta-api/icp_ledger/ledger.did"]="wasms/icp_ledger.did"
      ["https://download.dfinity.systems/ic/\$COMMIT/canisters/ledger-canister.wasm.gz"]="wasms/icp_ledger.wasm.gz"

      ["https://raw.githubusercontent.com/dfinity/ic/\$COMMIT/rs/rosetta-api/icp_ledger/index/index.did"]="wasms/icp_ledger_index.did"
      ["https://download.dfinity.systems/ic/\$COMMIT/canisters/ic-icp-index-canister.wasm.gz"]="wasms/icp_ledger_index.wasm.gz"

      ["https://raw.githubusercontent.com/dfinity/ic/\$COMMIT/rs/rosetta-api/icrc1/ledger/ledger.did"]="wasms/icrc1_ledger.did"
      ["https://download.dfinity.systems/ic/\$COMMIT/canisters/ledger-canister_notify-method.wasm.gz"]="wasms/icrc1_ledger.wasm.gz"

      ["https://download.dfinity.systems/ic/\$COMMIT/canisters/cycles-minting-canister.wasm.gz"]="wasms/cmc.wasm.gz"
      ["https://raw.githubusercontent.com/dfinity/ic/\$COMMIT/rs/nns/cmc/cmc.dids"]="wasms/cmc.did"

    )

    for url_template in "${!downloads[@]}"; do
      url="${url_template/\$COMMIT/$COMMIT}"
      destination="${downloads[$url_template]}"

      # Download the file
      echo "Downloading $url to $destination..."
      if ! curl -sfLo "$destination" "$url"; then
        echo "Failed to download from $url"
        exit 2
      fi
    done

    exit 0
  fi
done

echo "No commits with artifacts found"
exit 4
