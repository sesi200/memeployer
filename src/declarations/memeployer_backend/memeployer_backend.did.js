export const idlFactory = ({ IDL }) => {
  const FrontendFile = IDL.Record({
    'content' : IDL.Vec(IDL.Nat8),
    'path' : IDL.Text,
    'content_type' : IDL.Text,
  });
  const ICRCConfig = IDL.Record({
    'decimals' : IDL.Opt(IDL.Nat8),
    'token_symbol' : IDL.Text,
    'transfer_fee' : IDL.Nat,
    'token_name' : IDL.Text,
  });
  const NewInput = IDL.Record({
    'frontend_config' : IDL.Opt(IDL.Vec(FrontendFile)),
    'icrc_config' : IDL.Opt(ICRCConfig),
  });
  const NewResult = IDL.Record({
    'frontend_canister' : IDL.Opt(IDL.Principal),
    'token_canister' : IDL.Opt(IDL.Principal),
  });
  const AccountIdentifier = IDL.Vec(IDL.Nat8);
  const Subaccount = IDL.Vec(IDL.Nat8);
  const DepositAddressResult = IDL.Record({
    'principal' : IDL.Principal,
    'deposit_address' : AccountIdentifier,
    'subaccount' : Subaccount,
  });
  const Memeployer = IDL.Service({
    'deployNewProject' : IDL.Func([NewInput], [NewResult], []),
    'getDepositAddress' : IDL.Func(
        [IDL.Opt(IDL.Principal)],
        [DepositAddressResult],
        [],
      ),
    'greet' : IDL.Func([IDL.Text], [IDL.Text], ['query']),
    'upload_frontend_binary' : IDL.Func([IDL.Vec(IDL.Nat8)], [], ['oneway']),
    'upload_icrc_binary' : IDL.Func([IDL.Vec(IDL.Nat8)], [], ['oneway']),
  });
  return Memeployer;
};
export const init = ({ IDL }) => { return []; };
