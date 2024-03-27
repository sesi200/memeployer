import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export type AccountIdentifier = Uint8Array | number[];
export interface DepositAddressResult {
  'principal' : Principal,
  'deposit_address' : AccountIdentifier,
  'subaccount' : Subaccount,
}
export interface FrontendFile {
  'content' : Uint8Array | number[],
  'path' : string,
  'content_type' : string,
}
export interface ICRCConfig {
  'decimals' : [] | [number],
  'token_symbol' : string,
  'transfer_fee' : bigint,
  'token_name' : string,
}
export interface Memeployer {
  'deployNewProject' : ActorMethod<[NewInput], NewResult>,
  'getDepositAddress' : ActorMethod<[[] | [Principal]], DepositAddressResult>,
  'greet' : ActorMethod<[string], string>,
  'upload_frontend_binary' : ActorMethod<[Uint8Array | number[]], undefined>,
  'upload_icrc_binary' : ActorMethod<[Uint8Array | number[]], undefined>,
}
export interface NewInput {
  'frontend_config' : [] | [Array<FrontendFile>],
  'icrc_config' : [] | [ICRCConfig],
}
export interface NewResult {
  'frontend_canister' : [] | [Principal],
  'token_canister' : [] | [Principal],
}
export type Subaccount = Uint8Array | number[];
export interface _SERVICE extends Memeployer {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
