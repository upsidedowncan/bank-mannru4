<script lang="ts">
  import "../app.css";
  import favicon from "$lib/assets/favicon.svg";
  import Icon from "@iconify/svelte";
  import { goto } from "$app/navigation";
  import { supabase } from "$lib/supabase";
  import { fly, fade } from "svelte/transition";
  import { page } from "$app/stores";
  import { browser } from "$app/environment";
  let { children } = $props();
  let user: any = $state(null);
  let isMobileMenuOpen = $state(false);

  let isSubRoute = $derived(
    $page.url.pathname.split("/").filter((p) => p).length > 1,
  );

  function goBack() {
    if (browser) {
      history.back();
    }
  }

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
    <div class="flex-1 min-w-0 flex items-center">
      {#if isSubRoute}
        <button onclick={goBack} class="btn btn-ghost btn-square mr-2">
          <Icon icon="mdi:arrow-left" class="h-6 w-6" />
        </button>
      {/if}
      <a
        href="/"
        class="btn btn-ghost text-xl font-medium tracking-tight hover:bg-primary/10 transition-colors"
        >Маннбанк</a
      >
    </div>
    <div class="hidden flex-none gap-2 md:flex">
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
    <div class="flex-none md:hidden">
      <button
        class="btn btn-square btn-ghost"
        onclick={() => (isMobileMenuOpen = !isMobileMenuOpen)}
      >
        <Icon icon="mdi:menu" class="h-6 w-6" />
      </button>
    </div>
  </nav>

  <main class="flex-1 relative overflow-hidden bg-gray-50">
    {#key $page.url.pathname}
      <div class="absolute w-full h-full overflow-y-auto">
        {@render children?.()}
      </div>
    {/key}
  </main>

  <!-- Mobile Menu -->
  {#if isMobileMenuOpen}
    <div
      class="fixed inset-0 z-40 bg-black/20 backdrop-blur-sm md:hidden"
      onclick={() => (isMobileMenuOpen = false)}
      role="presentation"
      transition:fade={{ duration: 150 }}
    />
    <div
      class="fixed inset-y-0 right-0 z-50 w-72 bg-white p-4 md:hidden"
      transition:fly={{ x: 288, duration: 200 }}
    >
      <div class="flex items-center justify-between">
        <h2 class="text-lg font-semibold">Меню</h2>
        <button
          class="btn btn-sm btn-circle btn-ghost"
          onclick={() => (isMobileMenuOpen = false)}
        >
          <Icon icon="mdi:close" class="h-5 w-5" />
        </button>
      </div>
      <div class="mt-6 flex flex-col space-y-2">
        <a
          href="/marketplace"
          onclick={() => (isMobileMenuOpen = false)}
          class="btn btn-ghost justify-start text-base"
        >
          <Icon icon="mdi:store" class="mr-2 h-5 w-5" />
          <span>Маркет</span>
        </a>
        <a
          href="/dashboard"
          onclick={() => (isMobileMenuOpen = false)}
          class="btn btn-ghost justify-start text-base"
        >
          <Icon icon="mdi:credit-card" class="mr-2 h-5 w-5" />
          <span>Кабинет</span>
        </a>
        <a
          href="/games"
          onclick={() => (isMobileMenuOpen = false)}
          class="btn btn-ghost justify-start text-base"
        >
          <Icon icon="mdi:gamepad-variant" class="mr-2 h-5 w-5" />
          <span>Игры</span>
        </a>
        <a
          href="/mangpt"
          onclick={() => (isMobileMenuOpen = false)}
          class="btn btn-ghost justify-start text-base"
        >
          <Icon icon="mdi:robot" class="mr-2 h-5 w-5" />
          <span>ManGPT</span>
        </a>

        <div class="!my-4 border-t" />

        {#if user}
          <button
            class="btn btn-ghost justify-start text-base"
            onclick={() => {
              logout();
              isMobileMenuOpen = false;
            }}
          >
            <Icon icon="mdi:logout" class="mr-2 h-5 w-5" />
            <span>Выйти</span>
          </button>
        {:else}
          <a
            href="/login"
            onclick={() => (isMobileMenuOpen = false)}
            class="btn btn-ghost justify-start text-base"
          >
            <Icon icon="mdi:login" class="mr-2 h-5 w-5" />
            <span>Войти</span>
          </a>
        {/if}
      </div>
    </div>
  {/if}
</div>
