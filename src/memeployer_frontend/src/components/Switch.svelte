<script lang="ts">
	import { createEventDispatcher } from 'svelte';

	export let defaultValue = false;
	export let disabled = false;

	let classNames: string = '';
	export { classNames as class };

	const dispatcher = createEventDispatcher<{ change: boolean }>();
	let checked = defaultValue;

	$: dispatcher('change', checked);

	let containerClassNames = '';
	let dotClassNames = '';

	$: {
		if (disabled) {
			containerClassNames = 'bg-black/40 border-transparent';
			dotClassNames = checked ? 'left-[27px] bg-white/64' : 'left-[3px] bg-white/64';
		} else {
			containerClassNames = checked
				? 'border-white'
				: 'border-white/30 hover:border-white/50 group';
			dotClassNames = checked
				? 'left-[27px] bg-white'
				: 'left-[3px] bg-white/30 group-hover:bg-white/50';
		}
	}
</script>

<label
	class="inline-flex items-center cursor-pointer {classNames} rounded-full"
	tabindex="0"
	role="checkbox"
	aria-checked={checked}
	on:keydown={(e) => {
		if (e.key === 'Enter' || e.key === ' ') {
			checked = !checked;
		}
	}}
>
	<input type="checkbox" bind:checked class="hidden" {disabled} />

	<span
		class="inline-flex h-[30px] w-14 rounded-full box-border border
      transition-all
      {containerClassNames}
    "
	>
		<span
			class="
        block rounded-full w-[24px] h-[24px]
        relative
        {dotClassNames}
        transition-all
        top-[2px]
      "
		/>
	</span>
	<slot />
</label>
