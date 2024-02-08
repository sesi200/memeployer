<script>
	import { onMount } from 'svelte';
	import './styles.css';
	import { auth } from '$lib/auth';

	onMount(() => {
		auth.initialize();
	});
</script>

<div class="text-white min-h-full font-mono">
	<main>
		<slot />
	</main>
</div>
