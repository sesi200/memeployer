<script lang="ts">
	import type { AuthenticatedState } from '$lib/auth';
	import { saveDeployment } from '$lib/deployments';
	import { makeFrontendUrl } from '$lib/url';
	import { fade } from 'svelte/transition';
	import IcpBalance from './IcpBalance.svelte';
	import Switch from './Switch.svelte';
	import type { FrontendFile } from '../../../declarations/memeployer_backend/memeployer_backend.did';

	export let auth: AuthenticatedState;

	let name = '';
	let symbol = '';
	let transferFee = 0;
	let decimals: number | null = null;
	let balanceSufficient = false;
	let websiteFiles: FrontendFile[] = [];

	let createToken = true;
	let createWebsite = true;

	let formElement: HTMLFormElement;

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
				icrc_config: createToken
					? [
							{
								decimals: decimals === null ? [] : [decimals],
								token_name: name,
								token_symbol: symbol,
								transfer_fee: BigInt(transferFee)
							}
						]
					: [],
				frontend_config: createWebsite ? [websiteFiles] : []
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

	async function onWebsiteFilesChange(event: Event) {
		const target = event.target as HTMLInputElement;
		websiteFiles = await Promise.all(
			Array.from(target.files!).map(async (file) => {
				if (file.webkitRelativePath) {
					const pathWithoutBasedir = '/' + file.webkitRelativePath.split('/').slice(1).join('/');
					return {
						content: new Uint8Array(await file.arrayBuffer()),
						content_type: file.type,
						path: pathWithoutBasedir
					} satisfies FrontendFile;
				} else {
					return {
						content: new Uint8Array(await file.arrayBuffer()),
						content_type: file.type,
						path: '/' + file.name
					} satisfies FrontendFile;
				}
			})
		);

		console.log(websiteFiles);
	}

	$: formValid =
		balanceSufficient &&
		(!createToken || (createToken && name.trim() && symbol.trim() && balanceSufficient)) &&
		(!createWebsite || (createWebsite && websiteFiles.length));
</script>

<form
	action=""
	class="flex flex-col gap-6"
	on:submit|preventDefault={submit}
	bind:this={formElement}
>
	{#if state.name !== 'success'}
		<div class="flex justify-between items-center">
			<h2 class="text-3xl mb-0 {createToken ? '' : 'text-white/50'}">Create a token</h2>
			<Switch on:change={(e) => (createToken = e.detail)} defaultValue={createToken}></Switch>
		</div>
		{#if createToken}
			<div class="mb-2 flex flex-col gap-2">
				<label for="name" class="text-white text-lg uppercase"
					>Token name

					<span class="text-white/30">(required)</span>
				</label>
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
				<label for="symbol" class="text-white text-lg uppercase"
					>Symbol
					<span class="text-white/30">(required)</span>
				</label>
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
		{/if}

		<div class="flex justify-between items-center mt-8">
			<h2 class="text-3xl {createWebsite ? '' : 'text-white/50'}">Deploy a website</h2>
			<Switch on:change={(e) => (createWebsite = e.detail)} defaultValue={createWebsite}></Switch>
		</div>
		{#if createWebsite}
			<label for="website-files">Select directory to upload</label>
			<input
				type="file"
				name="website-files"
				id="website-files"
				disabled={state.name === 'working'}
				multiple
				webkitdirectory
				directory
				required
				class="rounded-lg border border-white border-solid font-lg bg-transparent text-white w-full
					file:py-4 file:border-none file:bg-white file:px-3 file:mr-6
					file:cursor-pointer
				"
				on:change={onWebsiteFilesChange}
			/>
		{/if}

		{#if createToken || createWebsite}
			<div class="mt-10">
				<IcpBalance {auth} on:balanceUpdate={(e) => (balanceSufficient = e.detail)} />
			</div>

			<div class="mb-2 flex flex-col gap-2 mt-10">
				<button class="button" disabled={state.name === 'working' || !formValid}>
					{#if state.name === 'working'}
						Working...
					{:else if createToken && createWebsite}
						Create token and website
					{:else if createToken}
						Create token
					{:else if createWebsite}
						Deploy website
					{/if}
				</button>
			</div>
			{#if state.name === 'error'}
				<div class="mb-2 flex flex-col gap-2">
					{state.error}
				</div>
			{/if}
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
