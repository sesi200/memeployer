import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import List "mo:base/List";

import Account "Account";
import LedgerTypes "LedgerTypes";
import AssetCanisterTypes "AssetCanisterTypes";
import Ledger "canister:icp_ledger";
import CMC "canister:cmc";

actor class Memeployer() = self {
  let MINT_MEMO : Nat64 = 1347768404;

  type ICRCConfig = {
    token_symbol : Text;
    token_name : Text;
    transfer_fee : Nat;
    decimals : ?Nat8;
  };

  type FrontendFile = {
    path : Text;
    content : Blob;
    content_type : Text;
  };

  type NewInput = {
    icrc_config : ?ICRCConfig;
    frontend_config : ?[FrontendFile];
  };

  type NewResult = {
    token_canister : ?Principal;
    frontend_canister : ?Principal;
  };

  stable var deployed_projects : List.List<(Principal, NewResult)> = null;

  public shared (args) func listMyProjects() : async [NewResult] {
    let filtered = List.filter<(Principal, NewResult)>(deployed_projects, func(c, _) { c == args.caller });
    let mapped = List.map<(Principal, NewResult), NewResult>(filtered, func(_, p) { p });
    List.toArray(mapped);
  };

  type DepositAddressResult = {
    deposit_address : Account.AccountIdentifier;
    principal : Principal;
    subaccount : Account.Subaccount;
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

  func createCanister(coController : Principal, cycles : Nat) : async* Principal {
    let IC0 : Management = actor ("aaaaa-aa");
    let this = Principal.fromActor(self);

    Cycles.add(cycles);
    (await IC0.create_canister({ settings = ?{ controllers = ?[this, coController] } })).canister_id;
  };

  func createLedger(coController : Principal, config : ICRCConfig, cycles : Nat) : async* Principal {
    let IC0 : Management = actor ("aaaaa-aa");
    let this = Principal.fromActor(self);
    let real_icrc_wasm = switch (icrc_wasm) {
      case (?value) { value };
      case (null) { throw Error.reject("ICRC wasm not uploaded") };
    };
    let icrc = await* createCanister(coController, cycles);
    await IC0.install_code({
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
    });
    icrc;
  };

  func createFrontend(coController : Principal, config : [FrontendFile], cycles : Nat) : async* Principal {
    let IC0 : Management = actor ("aaaaa-aa");
    let this = Principal.fromActor(self);
    let real_frontend_wasm = switch (frontend_wasm) {
      case (?value) { value };
      case (null) { throw Error.reject("Asset canister wasm not uploaded") };
    };
    let frontend = await* createCanister(coController, cycles);
    await IC0.install_code({
      mode = #install;
      canister_id = frontend;
      wasm_module = real_frontend_wasm;
      arg = to_candid (());
    });
    let asset_canister : AssetCanisterTypes.AssetCanister = actor (Principal.toText(frontend));
    await asset_canister.grant_permission({
      to_principal = coController;
      permission = #Commit;
    });

    for (file in Iter.fromArray(config)) {
      await asset_canister.store({
        key = file.path;
        content_type = file.content_type;
        content_encoding = "identity";
        content = file.content;
        sha256 = null;
      });

    };

    frontend;
  };

  func mintAddress() : Account.AccountIdentifier {
    let this = Principal.fromActor(self);
    let cmc : Principal = Principal.fromActor(CMC);
    Account.accountIdentifier(cmc, Account.principalToSubaccount(this));
  };

  public shared (args) func getDepositAddress(sub : ?Principal) : async DepositAddressResult {
    let this = Principal.fromActor(self);
    let principal = switch (sub) {
      case (?sub) { sub };
      case (null) { args.caller };
    };

    let subaccount = Account.principalToSubaccount(principal);

    return {
      deposit_address = Account.accountIdentifier(this, subaccount);
      principal = this;
      subaccount = subaccount;
    };

  };

  public query func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };

  public shared (args) func deployNewProject(input : NewInput) : async NewResult {
    let cycles = await convert(args.caller);
    let icrc_canister_id = switch (input.icrc_config) {
      case (?icrc_config) {
        ?(await* createLedger(args.caller, icrc_config, (cycles / 10 * 2)));
      };
      case (null) { null /* not deploying an icrc token */ };
    };
    let frontend_canister_id = switch (input.frontend_config) {
      case (?frontend_config) {
        ?(await* createFrontend(args.caller, frontend_config, (cycles / 10 * 7)));
      };
      case (null) { null /* not deploying a frontend */ };
    };

    deployed_projects := List.push(
      (
        args.caller,
        {
          token_canister = icrc_canister_id;
          frontend_canister = frontend_canister_id;
        },
      ),
      deployed_projects,
    );

    return {
      token_canister = icrc_canister_id;
      frontend_canister = frontend_canister_id;
    };
  };

  func convert(from : Principal) : async Nat {
    let this = Principal.fromActor(self);
    let ans = await Ledger.transfer({
      memo = MINT_MEMO;
      amount = { e8s = 99990000 };
      fee = { e8s = 10000 };
      from_subaccount = ?Blob.toArray(Account.principalToSubaccount(from));
      to = Blob.toArray(mintAddress());
      created_at_time = null;
    });
    let blockIndex = switch (ans) {
      case (#Ok(blockIndex)) { blockIndex };
      case (#Err(err)) { Debug.trap("aaaa") };
    };

    let mint = await CMC.notify_top_up({
      block_index = blockIndex;
      canister_id = this;
    });
    switch (mint) {
      case (#Ok(cycles)) { cycles };
      case (#Err(err)) { Debug.trap("bbbb") };
    };
  };
};
