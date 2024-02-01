set -e

dfx start --clean --background || true
dfx deploy --with-cycles 1000t --yes

memeployer_backend=$(dfx canister id memeployer_backend)
identity=$(dfx identity whoami)
ic-repl -r "http://localhost:4943" <<END
import memeployer_backend = "${memeployer_backend}"
identity ${identity} "~/.config/dfx/identity/${identity}/identity.pem"
call memeployer_backend.upload_icrc_binary(file "icrc.wasm.gz")
END

dfx canister call memeployer_backend deployNewProject '(record { token_symbol = "SYMB"; token_name = "token name"; transfer_fee = 5;})'