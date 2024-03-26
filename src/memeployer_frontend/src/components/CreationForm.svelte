<script lang="ts">
	import type { AuthenticatedState } from '$lib/auth';
	import { saveDeployment } from '$lib/deployments';
	import { makeFrontendUrl } from '$lib/url';
	import { fade } from 'svelte/transition';
	import IcpBalance from './IcpBalance.svelte';

	export let auth: AuthenticatedState;

	let name = '';
	let symbol = '';
	let transferFee = 0;
	let decimals: number | null = null;
	let balanceSufficient = false;

	type State =
		| {
				name: 'idle';
		  }
		| {
				name: 'working';
		  }
		| {
				name: 'error';
				error: string;
		  }
		| {
				name: 'success';
				tokenCanisterId?: string;
				frontendCanisterId?: string;
		  };

	let state: State = {
		name: 'idle'
	};

	async function submit() {
		state = { name: 'working' };
		try {
			const result = await auth.actor.deployNewProject({
				icrc_config: [
					{
						decimals: decimals === null ? [] : [decimals],
						token_name: name,
						token_symbol: symbol,
						transfer_fee: BigInt(transferFee)
					}
				],
				frontend_config: []
			});

			state = {
				name: 'success',
				tokenCanisterId: result.token_canister[0]?.toText(),
				frontendCanisterId: result.frontend_canister[0]?.toText()
			};

			if (state.tokenCanisterId) {
				saveDeployment({
					type: 'icrc',
					canisterId: state.tokenCanisterId,
					name: name
				});
			}

			if (state.frontendCanisterId) {
				saveDeployment({
					type: 'frontend',
					canisterId: state.frontendCanisterId
				});
			}

			name = '';
			symbol = '';
			transferFee = 0;
			decimals = null;
		} catch (e: unknown) {
			if (e instanceof Error) {
				state = { name: 'error', error: e.message };
			} else {
				state = {
					name: 'error',
					error: 'Unknown error occurred during token creation. Please try again.'
				};
			}
		}
	}
</script>

<form action="" class="mt-20 flex flex-col gap-6" on:submit|preventDefault={submit}>
	{#if state.name !== 'success'}
		<div class="mb-2 flex flex-col gap-2" out:fade>
			<label for="name" class="text-white text-lg uppercase">Token name</label>
			<input
				id="name"
				bind:value={name}
				required
				type="text"
				class="rounded-lg border border-white border-solid px-3 py-4 font-lg bg-transparent text-white w-full"
				placeholder="eg. MemeCoin"
				disabled={state.name === 'working'}
			/>
		</div>

		<div class="mb-2 flex flex-col gap-2">
			<label for="symbol" class="text-white text-lg uppercase">Symbol</label>
			<input
				id="symbol"
				bind:value={symbol}
				required
				type="text"
				class="rounded-lg border border-white border-solid px-3 py-4 font-lg bg-transparent text-white w-full"
				placeholder="eg. MEME"
				disabled={state.name === 'working'}
			/>
		</div>

		<div class="mb-2 flex flex-col gap-2">
			<label for="transferFee" class="text-white text-lg uppercase">Transfer fee</label>
			<input
				id="transferFee"
				bind:value={transferFee}
				required
				type="number"
				class="rounded-lg border border-white border-solid px-3 py-4 font-lg bg-transparent text-white w-full"
				placeholder="eg. 0.1"
				disabled={state.name === 'working'}
			/>
		</div>

		<div class="mb-2 flex flex-col gap-2">
			<label for="decimals" class="text-white text-lg uppercase">Decimals</label>
			<input
				id="decimals"
				bind:value={decimals}
				type="number"
				class="rounded-lg border border-white border-solid px-3 py-4 font-lg bg-transparent text-white w-full"
				placeholder="eg. 4 (0.0001)"
				disabled={state.name === 'working'}
			/>
		</div>

		<div class="">
			<IcpBalance {auth} on:balanceUpdate={(e) => (balanceSufficient = e.detail)} />
		</div>

		<div class="mb-2 flex flex-col gap-2 mt-10">
			<button class="button" disabled={state.name === 'working' || !balanceSufficient}>
				{#if state.name === 'working'}
					Creating token...
				{:else}
					Create token
				{/if}
			</button>
		</div>
		{#if state.name === 'error'}
			<div class="mb-2 flex flex-col gap-2">
				{state.error}
			</div>
		{/if}
	{:else}
		<div class="space-y-12">
			{#if state.tokenCanisterId}
				<div class="mb-2 flex flex-col gap-2" in:fade>
					<div class="">🎉 Successfully created an ICRC1 token: {state.tokenCanisterId}</div>
					<div class="mt-2">
						What's next:
						<ul class="list-disc mt-2">
							<li class="ml-4">
								<a class="underline" href="#">See on the dashboard</a>
							</li>
							<li class="ml-4">
								<a class="underline" href="#">Deploy a website</a>
							</li>
							<li class="ml-4">
								<a class="underline" href="#">Create liquidity pool</a>
							</li>
						</ul>
					</div>
				</div>
			{/if}

			{#if state.frontendCanisterId}
				<div class="mb-2 flex flex-col gap-2" in:fade>
					<div class="">🎉 Successfully created an on-chain website!</div>
					<div class="mt-2">
						Check it out at <a
							class="underline"
							href={makeFrontendUrl(state.frontendCanisterId)}
							target="_blank">{makeFrontendUrl(state.frontendCanisterId)}</a
						>
					</div>
				</div>
			{/if}
		</div>
	{/if}
</form>
