set -e

dfx start --clean --background || true
dfx deploy --yes
dfx deps deploy

memeployer_backend=$(dfx canister id memeployer_backend)
identity=$(dfx identity whoami)
ic-repl -r "http://localhost:4943" <<END
import memeployer_backend = "${memeployer_backend}"
identity ${identity} "~/.config/dfx/identity/${identity}/identity.pem"
call memeployer_backend.upload_icrc_binary(file("icrc.wasm.gz"))
call memeployer_backend.upload_frontend_binary(file("assetstorage.wasm.gz"))

call memeployer_backend.deployNewProject(record { icrc_config = opt record {token_symbol = "SYMB"; token_name = "token name"; transfer_fee = 5;}; frontend_config = opt record {index_html = file("index.html");};})

END
