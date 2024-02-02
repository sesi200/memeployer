module {
    public type Key = Text;
    public type GrantPermission = {
        to_principal : Principal;
        permission : Permission;
    };
    public type Permission = {
        #Commit;
        #ManagePermissions;
        #Prepare;
    };
    public type AssetCanister = actor {
        grant_permission : (GrantPermission) -> async ();
        // Single call to create an asset with content for a single content encoding that
        // fits within the message ingress limit.
        store : (
            {
                key : Key;
                content_type : Text;
                content_encoding : Text;
                content : Blob;
                sha256 : ?Blob;
            }
        ) -> async ();
    };
};
