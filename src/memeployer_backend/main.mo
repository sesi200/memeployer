import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import LedgerTypes "LedgerTypes";

actor class Memeployer() = self {
  type NewInput = {
    token_symbol : Text;
    token_name : Text;
    transfer_fee : Nat;
    decimals : ?Nat8;
  };

  type NewResult = {
    token_canister : ?Principal;
  };

  type CanisterSettings = { controllers : ?[Principal] };

  type Management = actor {
    create_canister : ({ settings : ?CanisterSettings }) -> async ({
      canister_id : Principal;
    });
    install_code : ({
      mode : { #install; #reinstall; #upgrade };
      canister_id : Principal;
      wasm_module : Blob;
      arg : Blob;
    }) -> async ();
    update_settings : ({ canister_id : Principal; settings : CanisterSettings }) -> async ();
  };

  stable var icrc_wasm : ?Blob = null;
  stable var nft_wasm : ?Blob = null;
  public shared (args) func upload_icrc_binary(wasm : Blob) {
    assert (Principal.isController(args.caller));
    icrc_wasm := ?wasm;
  };

  func createCanister(coController : Principal) : async* Principal {
    let IC0 : Management = actor ("aaaaa-aa");
    let this = Principal.fromActor(self);

    Cycles.add(1_000_000_000_000);
    (await IC0.create_canister({ settings = ?{ controllers = ?[this, coController] } })).canister_id;
  };

  public query func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };

  public shared (args) func deployNewProject(input : NewInput) : async NewResult {
    let IC0 : Management = actor ("aaaaa-aa");
    let this = Principal.fromActor(self);
    let icrc = await* createCanister(args.caller);
    let real_icrc_wasm = switch (icrc_wasm) {
      case (?value) { value };
      case (null) { throw Error.reject("ICRC wasm not uploaded") };
    };
    await IC0.install_code(
      {
        mode = #install;
        canister_id = icrc;
        wasm_module = real_icrc_wasm;
        arg = to_candid (
          (
            #Init {
              minting_account = {
                owner = args.caller;
                subaccount = null;
              };
              fee_collector_account = null;
              transfer_fee = input.transfer_fee;
              decimals = input.decimals;
              max_memo_length = null;
              token_symbol = input.token_symbol;
              token_name = input.token_name;
              metadata = [];
              initial_balances = [];
              feature_flags = ?{
                icrc2 = true;
              };
              maximum_number_of_accounts = null;
              accounts_overflow_trim_quantity = null;
              archive_options = {
                num_blocks_to_archive = 1_000_000_000;
                max_transactions_per_response = ?50;
                trigger_threshold = 1_000_000_000;
                max_message_size_bytes = ?1_000;
                cycles_for_archive_creation = ?1_000_000_000_000;
                node_max_memory_size_bytes = null;
                controller_id = this;
              };
            }
          ) : LedgerTypes.LedgerArg
        );
      }
    );
    return {
      token_canister = ?icrc;
    };
  };
};
