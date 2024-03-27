#!/usr/bin/env bash

DEFAULT_IDENTITY=$(dfx identity whoami)
DEFAULT_ACCOUNT_ID=$(dfx ledger account-id)

MINTER_IDENTITY=minter

if [ "$MINTER_IDENTITY" == "$WHOAMI" ]; then
  echo "You can't run this script as the minter identity. Please run it as a different identity."
  exit 1
fi

if ! dfx identity list | grep -q $MINTER_IDENTITY; then
  echo "Creating minter identity..."
  dfx identity new $MINTER_IDENTITY
  dfx identity use $DEFAULT_IDENTITY

else
  echo "Accessing minter identity..."

fi

MINT_ACC_ID=$(dfx ledger account-id --identity $MINTER_IDENTITY)

dfx deploy icp_ledger --specified-id ryjl3-tyaaa-aaaaa-aaaba-cai --argument "
  (variant {
    Init = record {
      minting_account = \"$MINT_ACC_ID\";
      initial_values = vec {
        record {
          \"$DEFAULT_ACCOUNT_ID\";
          record {
            e8s = 1000_00000000 : nat64;
          };
        };
      };
      send_whitelist = vec {};
      transfer_fee = opt record {
        e8s = 10_000 : nat64;
      };
      token_symbol = opt \"ICP\";
      token_name = opt \"Internet Computer\";
    }
  })
"

dfx deploy cmc --specified-id rkp4c-7iaaa-aaaaa-aaaca-cai --argument "(opt record {
    minting_account_id = opt \"${MINT_ACC_ID}\";
    ledger_canister_id = opt principal \"ryjl3-tyaaa-aaaaa-aaaba-cai\";
    governance_canister_id = opt principal \"aaaaa-aa\";
    last_purged_notification = opt 0;
    exchange_rate_canister = null;
})"

# hack to get rid of dfx pull error
rm ~/.cache/dfinity/pulled/rdmx6-jaaaa-aaaaa-aaadq-cai/canister.wasm.gz

dfx deps pull
dfx deps init
dfx deps deploy internet_identity
dfx deploy

ICRC1_LEDGER_WASM=$(hexdump -ve '1/1 "%.2x"' wasms/icrc1_ledger.wasm.gz | sed 's/../\\&/g')
dfx canister call memeployer_backend upload_icrc_binary --argument-file <(echo "(blob \"$ICRC1_LEDGER_WASM\")")

ASSETSTORAGE_WASM=$(hexdump -ve '1/1 "%.2x"' wasms/assetstorage.wasm.gz | sed 's/../\\&/g')
dfx canister call memeployer_backend upload_frontend_binary --argument-file <(echo "(blob \"$ASSETSTORAGE_WASM\")")
