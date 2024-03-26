<script lang="ts">
	import CopyIcon from './CopyIcon.svelte';
	export let principal: string;
	export let shorten: boolean = true;
	let copied = false;

	function copyToClipboard(text: string) {
		navigator.clipboard.writeText(text);
		copied = true;

		setTimeout(() => {
			copied = false;
		}, 1000);
	}

	$: displayPrincipal = shorten ? principal.slice(0, 12) + '...' + principal.slice(-10) : principal;
</script>

<button
	class="inline-flex gap-2 items-center transition-all group {copied ? 'text-green-500' : ''}"
	on:click={() => copyToClipboard(principal)}
>
	<CopyIcon class="w-6 opacity-0 group-hover:opacity-100 transition-opacity" />
	{displayPrincipal}
</button>
