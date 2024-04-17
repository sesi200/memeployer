import { sveltekit } from '@sveltejs/kit/vite';
import { join } from 'path';
import { defineConfig } from 'vite';
import { readCanisterIds } from './utils/canisterIds';
import { Networks } from './utils/network';

const networks = new Networks({
	local: {
		canisterIds: () =>
			readCanisterIds(
				join(process.cwd(), '..', '..', '.dfx', 'local', 'canister_ids.json'),
				'local'
			),
		host: 'http://localhost:4943',
		internetIdentity: 'http://rdmx6-jaaaa-aaaaa-aaadq-cai.localhost:4943'
	},

	ic: {
		canisterIds: () => readCanisterIds(join(process.cwd(), '..', 'canister_ids.json'), 'ic'),
		host: 'https://icp0.io',
		internetIdentity: 'https://identity.ic0.app'
	}
});

const network = process.env.DFX_NETWORK ?? 'local';

if (!networks.isValidNetwork(network)) {
	throw Error(`Invalid network: ${network}`);
}

const { canisterIds, host, internetIdentity } = networks.getConfig(network);

export default defineConfig(() => {
	process.env = {
		...process.env,
		VITE_DFX_NETWORK: network,
		VITE_HOST: host,
		VITE_II_URL: internetIdentity,
		VITE_MEMEPLOYER_BACKEND_CANISTER_ID: canisterIds['memeployer_backend']
	};

	return {
		plugins: [sveltekit()],
		build: {
			target: 'es2020',
			rollupOptions: {}
		},
		optimizeDeps: {
			esbuildOptions: {
				// Node.js global to browser globalThis
				define: {
					global: 'globalThis'
				}
			}
		}
	};
});
