<script lang="ts">
	import '../app.css';
	import favicon from '$lib/assets/favicon.svg';
  import Icon from '@iconify/svelte';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';

	let { children } = $props();
  let user: any = null;

  async function checkAuth() {
    const { data: { user: currentUser } } = await supabase.auth.getUser();
    user = currentUser;
  }

  checkAuth();
  async function logout() {
    await supabase.auth.signOut();
    goto('/login');
  }
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

<div class="w-full">
  <div class="navbar bg-base-100 sticky top-0 z-40 border-b border-base-200">
    <div class="flex-1 min-w-0">
      <a href="/" class="btn btn-ghost text-lg font-light tracking-tight">Маннбанк</a>
    </div>
    <div class="flex-none gap-1">
      <a href="/marketplace" class="btn btn-ghost btn-sm"><Icon icon="mdi:store" class="w-4 h-4 mr-1"/>Маркет</a>
      <a href="/dashboard" class="btn btn-ghost btn-sm"><Icon icon="mdi:credit-card" class="w-4 h-4 mr-1"/>Кабинет</a>
      <a href="/games" class="btn btn-ghost btn-sm"><Icon icon="mdi:gamepad-variant" class="w-4 h-4 mr-1"/>Игры</a>
      <a href="/mangpt" class="btn btn-ghost btn-sm"><Icon icon="mdi:robot" class="w-4 h-4 mr-1"/>ManGPT</a>
      {#if user}
        <button class="btn btn-outline btn-sm" on:click={logout}>Выйти</button>
      {:else}
        <a href="/login" class="btn btn-primary btn-sm">Войти</a>
      {/if}
    </div>
  </div>

  {@render children?.()}
</div>
