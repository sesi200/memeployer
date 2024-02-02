module {
    public type Account = {
        owner : Principal;
        subaccount : ?Blob;
    };

    public type ArchiveOptions = {
        num_blocks_to_archive : Nat64;
        max_transactions_per_response : ?Nat64;
        trigger_threshold : Nat64;
        max_message_size_bytes : ?Nat64;
        cycles_for_archive_creation : ?Nat64;
        node_max_memory_size_bytes : ?Nat64;
        controller_id : Principal;
    };

    public type MetadataValue = {
        #Nat : Nat;
        #Int : Int;
        #Text : Text;
        #Blob : Blob;
    };

    public type FeatureFlags = {
        icrc2 : Bool;
    };

    public type InitArgs = {
        minting_account : Account;
        fee_collector_account : ?Account;
        transfer_fee : Nat;
        decimals : ?Nat8;
        max_memo_length : ?Nat16;
        token_symbol : Text;
        token_name : Text;
        metadata : [(Text, MetadataValue)];
        initial_balances : [(Account, Nat)];
        feature_flags : ?FeatureFlags;
        maximum_number_of_accounts : ?Nat64;
        accounts_overflow_trim_quantity : ?Nat64;
        archive_options : ArchiveOptions;
    };

    public type LedgerArg = {
        #Init : InitArgs;
    };
};
