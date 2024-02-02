import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import LedgerTypes "LedgerTypes";
import AssetCanisterTypes "AssetCanisterTypes";

actor class Memeployer() = self {
  type ICRCConfig = {
    token_symbol : Text;
    token_name : Text;
    transfer_fee : Nat;
    decimals : ?Nat8;
  };

  type FrontendConfig = {
    index_html : Blob;
  };

  type NewInput = {
    icrc_config : ?ICRCConfig;
    frontend_config : ?FrontendConfig;
  };

  type NewResult = {
    token_canister : ?Principal;
    frontend_canister : ?Principal;
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
  public shared (args) func upload_icrc_binary(wasm : Blob) {
    assert (Principal.isController(args.caller));
    icrc_wasm := ?wasm;
  };
  stable var frontend_wasm : ?Blob = null;
  public shared (args) func upload_frontend_binary(wasm : Blob) {
    assert (Principal.isController(args.caller));
    frontend_wasm := ?wasm;
  };
  stable var nft_wasm : ?Blob = null;

  func createCanister(coController : Principal) : async* Principal {
    let IC0 : Management = actor ("aaaaa-aa");
    let this = Principal.fromActor(self);

    Cycles.add(1_000_000_000_000);
    (await IC0.create_canister({ settings = ?{ controllers = ?[this, coController] } })).canister_id;
  };

  func createLedger(coController : Principal, config : ICRCConfig) : async* Principal {
    let IC0 : Management = actor ("aaaaa-aa");
    let this = Principal.fromActor(self);
    let real_icrc_wasm = switch (icrc_wasm) {
      case (?value) { value };
      case (null) { throw Error.reject("ICRC wasm not uploaded") };
    };
    let icrc = await* createCanister(coController);
    await IC0.install_code(
      {
        mode = #install;
        canister_id = icrc;
        wasm_module = real_icrc_wasm;
        arg = to_candid (
          (
            #Init {
              minting_account = {
                owner = coController;
                subaccount = null;
              };
              fee_collector_account = null;
              transfer_fee = config.transfer_fee;
              decimals = config.decimals;
              max_memo_length = null;
              token_symbol = config.token_symbol;
              token_name = config.token_name;
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
    icrc;
  };

  func createFrontend(coController : Principal, config : FrontendConfig) : async* Principal {
    let IC0 : Management = actor ("aaaaa-aa");
    let this = Principal.fromActor(self);
    let real_frontend_wasm = switch (frontend_wasm) {
      case (?value) { value };
      case (null) { throw Error.reject("ICRC wasm not uploaded") };
    };
    let frontend = await* createCanister(coController);
    await IC0.install_code(
      {
        mode = #install;
        canister_id = frontend;
        wasm_module = real_frontend_wasm;
        arg = to_candid (());
      }
    );
    let asset_canister : AssetCanisterTypes.AssetCanister = actor (Principal.toText(frontend));
    await asset_canister.grant_permission({
      to_principal = coController;
      permission = #Commit;
    });
    await asset_canister.store({
      key = "/index.html";
      content_type = "text/html";
      content_encoding = "identity";
      content = config.index_html;
      sha256 = null;
    });

    frontend;
  };

  public query func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };

  public shared (args) func deployNewProject(input : NewInput) : async NewResult {
    let icrc_canister_id = switch (input.icrc_config) {
      case (?icrc_config) {
        ?(await* createLedger(args.caller, icrc_config));
      };
      case (null) { null /* not deploying an icrc token */ };
    };
    let frontend_canister_id = switch (input.frontend_config) {
      case (?frontend_config) {
        ?(await* createFrontend(args.caller, frontend_config));
      };
      case (null) { null /* not deploying a frontend */ };
    };

    return {
      token_canister = icrc_canister_id;
      frontend_canister = frontend_canister_id;
    };
  };
};
