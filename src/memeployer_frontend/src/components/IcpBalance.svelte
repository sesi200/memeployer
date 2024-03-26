<script lang="ts">
	import type { AuthenticatedState } from '$lib/auth';
	import { onDestroy, onMount, createEventDispatcher } from 'svelte';
	import { Principal } from '@dfinity/principal';
	import type {
		AccountIdentifier,
		Subaccount
	} from '../../../declarations/memeployer_backend/memeployer_backend.did';
	import { unreachable } from '$lib/unreachable';

	export let auth: AuthenticatedState;

	const MIN_BALANCE = BigInt(100_000_000);

	const dispatch = createEventDispatcher<{
		balanceUpdate: boolean;
	}>();

	let state:
		| {
				name: 'idle';
		  }
		| {
				name: 'getting-address';
		  }
		| {
				name: 'getting-balance';
				balance_e8s: BigInt | null;
				address: AccountIdentifier;
				addressText: string;
				addressPrincipal: Principal;
				addressSubaccount: Subaccount;
		  }
		| {
				name: 'error';
				error: string;
		  } = {
		name: 'idle'
	};

	let unmounted = false;

	async function getAddress() {
		const response = await auth.actor.getDepositAddress([]);

		if (unmounted) {
			return;
		}

		function extendUint8ArrayTo32Bytes(originalArray: Uint8Array) {
			const extendedArray = new Uint8Array(32);
			extendedArray.set(originalArray);
			return extendedArray;
		}

		console.log(
			`dfx canister call icp_ledger icrc1_transfer 'record { to = record { owner = principal "bd3sg-teaaa-aaaaa-qaaba-cai"; subaccount = opt vec {${extendUint8ArrayTo32Bytes(
				Uint8Array.from(response.subaccount)
			).join(
				';'
			)}}; }; amount = 100_000_000; memo = null;fee = opt 10_000; created_at_time = null; from_subaccount = null }'`
		);

		state = {
			name: 'getting-balance',
			address: response.deposit_address,
			addressText: (response.deposit_address instanceof Uint8Array
				? Array.from(response.deposit_address)
				: response.deposit_address
			)
				.map((x) => x.toString(16))
				.join(''),
			balance_e8s: null,
			addressPrincipal: response.principal,
			addressSubaccount: response.subaccount
		};

		getBalance();
	}

	async function getBalance() {
		if (state.name !== 'getting-balance') {
			return;
		}

		const balance = await auth.ledgerActor.icrc1_balance_of({
			owner: state.addressPrincipal,
			subaccount: [state.addressSubaccount]
		});

		state = {
			...state,
			name: 'getting-balance',
			balance_e8s: balance
		};

		dispatch('balanceUpdate', balance >= MIN_BALANCE);
	}

	onMount(() => {
		getAddress();
	});

	onDestroy(() => {
		unmounted = true;
	});

	function formatE8s(e8s: BigInt): number {
		return Number(e8s) / 100_000_000;
	}
</script>

{#if state.name === 'idle' || state.name === 'getting-address'}
	<div class="">Loading ICP balance check...</div>
{:else if state.name === 'getting-balance'}
	<div class="">
		To create your token and website and top the canister smart contracts up with plenty of cycles,
		please send <code class="bg-white/20 px-2 py-1 rounded-md">1 ICP</code>
		to

		<div class="mt-3">
			<code class="bg-white/20 px-2 py-1 rounded-md">{state.addressText}</code>
		</div>
	</div>
	<div class="text-white text-4xl mt-6 animate-pulse">
		{#if state.balance_e8s === null}
			Checking balance...
		{:else}
			Balance: {formatE8s(state.balance_e8s).toFixed(8)} ICP
		{/if}
	</div>
{:else if state.name === 'error'}{:else}
	{unreachable(state)}
{/if}