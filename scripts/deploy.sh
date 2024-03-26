set -e

dfx start --clean --background || true
dfx deps pull
dfx deps deploy || true
dfx deploy --yes

deposit_account=$(dfx canister call memeployer_backend getDepositAddress | grep blob | sed "s/^[^\\]*//" | sed "s/[^a-z0-9]//g")
dfx ledger transfer "$deposit_account" --amount 500 --memo 512

memeployer_backend=$(dfx canister id memeployer_backend)
identity=$(dfx identity whoami)
ic-repl -r "http://localhost:8080" <<END
import memeployer_backend = "${memeployer_backend}"
identity ${identity} "~/.config/dfx/identity/${identity}/identity.pem"
call memeployer_backend.upload_icrc_binary(file("icrc.wasm.gz"))
call memeployer_backend.upload_frontend_binary(file("assetstorage.wasm.gz"))

call memeployer_backend.deployNewProject(record { icrc_config = opt record {token_symbol = "SYMB"; token_name = "token name"; transfer_fee = 5;}; frontend_config = opt record {index_html = file("index.html");};})
call memeployer_backend.deployNewProject(record { icrc_config = opt record {token_symbol = "SYMB"; token_name = "token name"; transfer_fee = 5;}; frontend_config = opt record {index_html = file("index.html");};})

END
