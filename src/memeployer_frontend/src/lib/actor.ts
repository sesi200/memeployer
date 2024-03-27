import { HttpAgent, type Identity, Actor, type ActorSubclass } from '@dfinity/agent';
import { backendIdlFactory, ledgerIdlFactory } from './idlFactory';
import { BACKEND_CANISTER_ID, DFX_NETWORK, HOST } from './config';
import type { _SERVICE as BackendService } from '../../../declarations/memeployer_backend/memeployer_backend.did';
import type { _SERVICE as LedgerService } from '../../../declarations/icp_ledger/icp_ledger.did';

export type BackendActorType = ReturnType<typeof createBackendActor>;
export type LedgerActorType = ReturnType<typeof createLedgerActor>;

export const createBackendActor = (identity: Identity): ActorSubclass<BackendService> => {
	const agent = new HttpAgent({
		host: HOST,
		identity
	});

	// Fetch root key for certificate validation during development
	if (DFX_NETWORK !== 'ic') {
		agent.fetchRootKey().catch((err) => {
			console.warn('Unable to fetch root key. Check to ensure that your local replica is running');
			console.error(err);
		});
	}

	// Creates an actor with using the candid interface and the HttpAgent
	return Actor.createActor(backendIdlFactory, {
		agent,
		canisterId: BACKEND_CANISTER_ID
	});
};

export const createLedgerActor = (identity: Identity): ActorSubclass<LedgerService> => {
	const agent = new HttpAgent({
		host: HOST,
		identity
	});

	// Fetch root key for certificate validation during development
	if (DFX_NETWORK !== 'ic') {
		agent.fetchRootKey().catch((err) => {
			console.warn('Unable to fetch root key. Check to ensure that your local replica is running');
			console.error(err);
		});
	}

	// Creates an actor with using the candid interface and the HttpAgent
	return Actor.createActor(ledgerIdlFactory, {
		agent,
		canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai'
	});
};
