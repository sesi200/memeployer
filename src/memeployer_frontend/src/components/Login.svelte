<script lang="ts">
	import type { UnauthenticatedState } from '$lib/auth';
	import { createEventDispatcher } from 'svelte';

	export let auth: UnauthenticatedState;

	const dispatch = createEventDispatcher<{
		login: void;
	}>();
</script>

<button on:click={() => dispatch('login')} disabled={auth.authenticating} class="button">
	{#if auth.authenticating}
		Please wait...
	{:else}
		Log in and get the party started
	{/if}
</button>

{#if auth.error}
	<p class="mt-10">{auth.error}</p>
{/if}
