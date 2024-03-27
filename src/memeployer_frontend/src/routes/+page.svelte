<script>
	import { auth } from '$lib/auth';
	import CreationForm from '../components/CreationForm.svelte';
	import GithubIcon from '../components/GithubIcon.svelte';
	import Login from '../components/Login.svelte';
	import PreviousDeployments from '../components/PreviousDeployments.svelte';
	import Uninitialized from '../components/Uninitialized.svelte';
	import UserPrincipal from '../components/UserPrincipal.svelte';
</script>

<svelte:head>
	<title>Memeployer</title>
	<meta name="description" content="Easily deploy new memecoins with associated NFTs." />
</svelte:head>

<div class="absolute right-8 top-8 flex gap-6 items-center">
	{#if $auth.name === 'authenticated'}
		<UserPrincipal principal={$auth.principal}></UserPrincipal>
	{/if}
	<a href="https://github.com/sesi200/memeployer" class=" hover:text-white/90 transition-colors"
		><GithubIcon /></a
	>
</div>

<div class="mx-auto max-w-3xl px-6 py-24">
	<div class="bg-white/0 px-8 py-16">
		<h1 class="text-6xl mb-6">Memeployer</h1>
		<p class="text-xl text-white/80">Easily deploy new memecoins with associated NFTs.</p>
	</div>
	{#if $auth.name === 'unknown'}
		<div class="px-8">
			<Uninitialized />
		</div>
	{:else if $auth.name === 'unauthenticated'}
		<div class="px-8">
			<Login auth={$auth} on:login={() => auth.login()} />
		</div>
	{:else if $auth.name === 'authenticated'}
		<div class="bg-white/10 px-8 py-12">
			<CreationForm auth={$auth} />
			<!-- <WebsiteUpload auth={$auth} /> -->
			<PreviousDeployments />
		</div>
	{/if}
</div>
