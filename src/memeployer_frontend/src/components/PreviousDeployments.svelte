<script lang="ts">
	import { loadDeployments, type Deployment } from '$lib/deployments';
	import { makeFrontendUrl } from '$lib/url';
	import { onMount } from 'svelte';

	let deployments: Deployment[] | null = null;

	onMount(() => {
		deployments = loadDeployments();
	});
</script>

{#if deployments !== null && deployments.length > 0}
	<div class="border-t border-solid pt-4 mt-8">
		<h2>You previously deployed:</h2>
		<ul class="list-none">
			{#each deployments as deployment}
				<li class="mb-4">
					<a
						href={makeFrontendUrl(deployment.canisterId)}
						class="text-white/80 hover:text-white transition-colors"
						target="_blank"
						rel="noopener noreferrer
        "
					>
						{deployment.canisterId} -
						{deployment.type}
						{#if deployment.type === 'icrc'}
							- {deployment.name}
						{/if}
					</a>
				</li>
			{/each}
		</ul>
	</div>
{/if}
