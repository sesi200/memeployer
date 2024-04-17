#!/usr/bin/env bash

set -e

mkdir wasms | true

wget https://github.com/dfinity/sdk/raw/master/src/distributed/assetstorage.wasm.gz -O wasms/assetstorage.wasm.gz
wget https://download.dfinity.systems/ic/02dcaf3ccdfe46bd959d683d43c5513d37a1420d/canisters/ic-icrc1-ledger.wasm.gz -O wasms/icrc1_ledger.wasm.gz