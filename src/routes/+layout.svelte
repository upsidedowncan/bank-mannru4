<script lang="ts">
  import "../app.css";
  import favicon from "$lib/assets/favicon.svg";
  import Icon from "@iconify/svelte";
  import { goto } from "$app/navigation";
  import { supabase } from "$lib/supabase";
  let { children } = $props();
  let user: any = $state(null);

  async function checkAuth() {
    const {
      data: { user: currentUser },
    } = await supabase.auth.getUser();
    user = currentUser;
  }

  checkAuth();
  async function logout() {
    await supabase.auth.signOut();
    goto("/login");
  }
</script>

<svelte:head>
  <link rel="icon" href={favicon} />
</svelte:head>

<div class="flex flex-col min-h-screen">
  <nav
    class="navbar bg-white/70 backdrop-blur-xl sticky top-0 z-50 border-b border-gray-200/50 shadow-lg"
    style="position: sticky !important; top: 0 !important; backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px);"
  >
    <div class="flex-1 min-w-0">
      <a
        href="/"
        class="btn btn-ghost text-xl font-medium tracking-tight hover:bg-primary/10 transition-colors"
        >Маннбанк</a
      >
    </div>
    <div class="flex-none gap-2">
      <a
        href="/marketplace"
        class="btn btn-ghost btn-sm hover:bg-primary/10 transition-all"
        ><Icon icon="mdi:store" class="w-4 h-4 mr-1" />Маркет</a
      >
      <a
        href="/dashboard"
        class="btn btn-ghost btn-sm hover:bg-primary/10 transition-all"
        ><Icon icon="mdi:credit-card" class="w-4 h-4 mr-1" />Кабинет</a
      >
      <a
        href="/games"
        class="btn btn-ghost btn-sm hover:bg-primary/10 transition-all"
        ><Icon icon="mdi:gamepad-variant" class="w-4 h-4 mr-1" />Игры</a
      >
      <a
        href="/mangpt"
        class="btn btn-ghost btn-sm hover:bg-primary/10 transition-all"
        ><Icon icon="mdi:robot" class="w-4 h-4 mr-1" />ManGPT</a
      >
      {#if user}
        <button
          class="btn btn-outline btn-sm hover:bg-red-50 hover:text-red-600 hover:border-red-600 transition-all"
          onclick={logout}>Выйти</button
        >
      {:else}
        <a
          href="/login"
          class="btn btn-primary btn-sm shadow-md hover:shadow-lg transition-all"
          >Войти</a
        >
      {/if}
    </div>
  </nav>

  <main class="flex-1">
    {@render children?.()}
  </main>
</div>
