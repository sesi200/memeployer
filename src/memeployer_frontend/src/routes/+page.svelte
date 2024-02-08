<script>
	import { auth } from '$lib/auth';
	import CreationForm from '../components/CreationForm.svelte';
	import GithubIcon from '../components/GithubIcon.svelte';
	import Login from '../components/Login.svelte';
	import PreviousDeployments from '../components/PreviousDeployments.svelte';

	$: console.log($auth);
</script>

<svelte:head>
	<title>Memeployer</title>
	<meta name="description" content="Easily deploy new memecoins with associated NFTs." />
</svelte:head>

<div class="mx-auto max-w-3xl px-6 py-24">
	<div class="bg-white/10 px-8 py-16">
		<a
			href="https://github.com/sesi200/memeployer"
			class="absolute right-8 top-8 hover:text-white/90 transition-colors"><GithubIcon /></a
		>

		<h1 class="text-6xl mb-6">Memeployer</h1>
		<p class="text-xl text-white/80">Easily deploy new memecoins with associated NFTs.</p>

		{#if $auth.name === 'unauthenticated'}
			<Login auth={$auth} on:login={() => auth.login()} />
		{:else if $auth.name === 'authenticated'}
			<CreationForm auth={$auth} />
			<PreviousDeployments />
		{/if}
	</div>
</div>
