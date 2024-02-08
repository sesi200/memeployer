// import type { createActor } from '../../../declarations/memeployer_backend';

import { HttpAgent, type Identity, Actor, type ActorSubclass } from '@dfinity/agent';
import { idlFactory } from './idlFactory';
import { BACKEND_CANISTER_ID, DFX_NETWORK, HOST } from './config';
import type { _SERVICE } from '../../../declarations/memeployer_backend/memeployer_backend.did';

export type ActorType = ReturnType<typeof createActor>;

export const createActor = (identity: Identity): ActorSubclass<_SERVICE> => {
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
	return Actor.createActor(idlFactory, {
		agent,
		canisterId: BACKEND_CANISTER_ID
	});
};
