import { writable } from 'svelte/store';
import { createActor, type ActorType } from './actor';
import { AuthClient } from '@dfinity/auth-client';
import { BACKEND_CANISTER_ID, HOST, II_URL } from './config';

type AuthState =
	| {
			name: 'unknown';
	  }
	| {
			name: 'authenticated';
			actor: ActorType;
	  }
	| {
			name: 'unauthenticated';
			error?: string;
			authenticating: boolean;
	  };

export type UnauthenticatedState = Extract<AuthState, { name: 'unauthenticated' }>;
export type AuthenticatedState = Extract<AuthState, { name: 'authenticated' }>;

function createAuthStore() {
	const store = writable<AuthState>({
		name: 'unknown'
	});

	return {
		subscribe: store.subscribe,

		initialize: async () => {
			const authClient = await AuthClient.create();
			if (await authClient.isAuthenticated()) {
				const actor = createActor(authClient.getIdentity());
				store.set({
					name: 'authenticated',
					actor
				});
			} else {
				store.set({
					name: 'unauthenticated',
					authenticating: false
				});
			}
		},

		login: async () => {
			store.set({
				name: 'unauthenticated',
				authenticating: true
			});
			const authClient = await AuthClient.create();
			try {
				console.log('II_URL:', II_URL);

				await new Promise<void>((resolve, reject) => {
					authClient.login({
						identityProvider: II_URL,
						onSuccess: resolve,
						onError: reject
					});
				});

				const actor = createActor(authClient.getIdentity());

				store.set({
					name: 'authenticated',
					actor
				});
			} catch (e: unknown) {
				if (e instanceof Error) {
					store.set({
						name: 'unauthenticated',
						error: e.message,
						authenticating: false
					});
				} else {
					store.set({
						name: 'unauthenticated',
						error: 'Unknown error during login',
						authenticating: false
					});
				}
			}
		}
	};
}

export const auth = createAuthStore();
