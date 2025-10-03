<script lang="ts">
	import Icon from '@iconify/svelte'
	import { onMount } from 'svelte'
	import { goto } from '$app/navigation'
	import { supabase, marketplaceService } from '$lib/supabase'
	
	let user: any = null
	let categories: any[] = []
	let items: any[] = []
	let cartCount = 0
	let isLoading = true
	let searchQuery = ''
	let selectedCategory = ''
	let priceRange = { min: '', max: '' }
	let selectedCondition = ''
	let locationFilter = ''
	
	// Filters
	let showFilters = false
	let sortBy = 'newest'
	
	onMount(async () => {
		await checkAuth()
		await Promise.all([
			loadCategories(),
			loadItems(),
			loadCartCount()
		])
		isLoading = false
	})
	
	async function checkAuth() {
		const { data: { user: currentUser } } = await supabase.auth.getUser()
		if (!currentUser) {
			goto('/login')
			return
		}
		user = currentUser
	}
	
	async function loadCategories() {
		try {
			const { data } = await marketplaceService.getCategories()
			categories = data || []
		} catch (error) {
			console.error('Error loading categories:', error)
		}
	}
	
	async function loadItems() {
		try {
			const filters = {
				search: searchQuery,
				category_id: selectedCategory,
				min_price: priceRange.min ? parseFloat(priceRange.min) : undefined,
				max_price: priceRange.max ? parseFloat(priceRange.max) : undefined,
				condition: selectedCondition,
				location: locationFilter,
				limit: 50
			}
			
			const { data } = await marketplaceService.getItems(filters)
			items = data || []
			
			// Apply sorting
			if (sortBy === 'price_low') {
				items.sort((a, b) => a.price - b.price)
			} else if (sortBy === 'price_high') {
				items.sort((a, b) => b.price - a.price)
			} else if (sortBy === 'popular') {
				items.sort((a, b) => b.views_count - a.views_count)
			}
		} catch (error) {
			console.error('Error loading items:', error)
		}
	}
	
	async function loadCartCount() {
		if (!user) return
		try {
			const { data } = await marketplaceService.getCart(user.id)
			cartCount = data?.length || 0
		} catch (error) {
			console.error('Error loading cart count:', error)
		}
	}
	
	async function addToCart(itemId: string) {
		if (!user) return
		try {
			await marketplaceService.addToCart(user.id, itemId)
			await loadCartCount()
		} catch (error) {
			console.error('Error adding to cart:', error)
		}
	}
	
	async function toggleFavorite(itemId: string) {
		if (!user) return
		try {
			const { isFavorite } = await marketplaceService.isFavorite(user.id, itemId)
			if (isFavorite) {
				await marketplaceService.removeFromFavorites(user.id, itemId)
			} else {
				await marketplaceService.addToFavorites(user.id, itemId)
			}
			// Reload items to update favorite status
			await loadItems()
		} catch (error) {
			console.error('Error toggling favorite:', error)
		}
	}
	
	function formatPrice(price: number) {
		return new Intl.NumberFormat('ru-RU').format(price) + ' МР'
	}
	
	function formatCondition(condition: string) {
		const conditions = {
			'new': 'Новое',
			'like_new': 'Как новое',
			'good': 'Хорошее',
			'fair': 'Удовлетворительное',
			'poor': 'Плохое'
		}
		return conditions[condition] || condition
	}
	
	function getConditionColor(condition: string) {
		const colors = {
			'new': 'badge-success',
			'like_new': 'badge-info',
			'good': 'badge-primary',
			'fair': 'badge-warning',
			'poor': 'badge-error'
		}
		return colors[condition] || 'badge-ghost'
	}
	
	function clearFilters() {
		searchQuery = ''
		selectedCategory = ''
		priceRange = { min: '', max: '' }
		selectedCondition = ''
		locationFilter = ''
		loadItems()
	}
	
	// Watch for filter changes
	$: if (searchQuery !== undefined) {
		loadItems()
	}
	$: if (selectedCategory !== undefined) {
		loadItems()
	}
	$: if (sortBy !== undefined) {
		loadItems()
	}
</script>

<svelte:head>
	<title>Магазин - Банк Маннру</title>
</svelte:head>

<div class="min-h-screen bg-gray-50 overflow-x-hidden">
	<!-- Header -->
    <nav class="sticky top-0 z-40 bg-white shadow-sm border-b">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between items-center h-16">
                <!-- Left: Brand -->
                <div class="flex items-center space-x-3 min-w-0">
                    <a href="/dashboard" class="flex items-center">
                        <Icon icon="mdi:bank" class="w-6 h-6 text-primary mr-2" />
                        <span class="text-lg font-light text-primary truncate">Маннру</span>
                    </a>
                    <span class="text-gray-300 hidden sm:inline">|</span>
                    <h1 class="text-lg font-medium text-gray-900 truncate">Магазин</h1>
                </div>

                <!-- Right: Actions with hamburger on mobile -->
                <div class="hidden md:flex items-center space-x-3">
                    <a href="/marketplace/sell" class="btn btn-primary btn-sm">
                        <Icon icon="mdi:plus" class="w-4 h-4 mr-1" />
                        Продать
                    </a>
                    <a href="/marketplace/favorites" class="btn btn-ghost btn-sm">
                        <Icon icon="mdi:heart" class="w-4 h-4" />
                    </a>
                    <a href="/marketplace/cart" class="btn btn-ghost btn-sm relative">
                        <Icon icon="mdi:cart" class="w-4 h-4" />
                        {#if cartCount > 0}
                            <span class="absolute -top-2 -right-2 bg-primary text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
                                {cartCount}
                            </span>
                        {/if}
                    </a>
                    <a href="/marketplace/orders" class="btn btn-ghost btn-sm">
                        <Icon icon="mdi:package-variant" class="w-4 h-4" />
                    </a>
                </div>

                <!-- Mobile hamburger -->
                <div class="md:hidden dropdown dropdown-end">
                    <label tabindex="0" class="btn btn-ghost btn-circle">
                        <Icon icon="mdi:menu" class="w-6 h-6" />
                    </label>
                    <ul tabindex="0" class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52">
                        <li><a href="/marketplace/sell"><Icon icon="mdi:plus" class="w-4 h-4" />Продать</a></li>
                        <li><a href="/marketplace/favorites"><Icon icon="mdi:heart" class="w-4 h-4" />Избранное</a></li>
                        <li><a href="/marketplace/cart"><Icon icon="mdi:cart" class="w-4 h-4" />Корзина {#if cartCount > 0}<span class="badge badge-primary ml-2">{cartCount}</span>{/if}</a></li>
                        <li><a href="/marketplace/orders"><Icon icon="mdi:package-variant" class="w-4 h-4" />Заказы</a></li>
                    </ul>
                </div>
            </div>
		</div>
	</nav>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
		{#if isLoading}
			<div class="text-center py-12">
				<Icon icon="mdi:loading" class="w-12 h-12 animate-spin text-primary mx-auto mb-4" />
				<p class="text-gray-600">Загрузка товаров...</p>
			</div>
		{:else}
			<!-- Search and Filters -->
            <div class="bg-white rounded-lg shadow-sm p-6 mb-6 overflow-hidden">
				<!-- Search Bar -->
				<div class="flex flex-col sm:flex-row gap-4 mb-4">
					<div class="flex-1">
						<div class="relative">
							<Icon icon="mdi:magnify" class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                            <input 
								type="text" 
								bind:value={searchQuery}
								placeholder="Поиск товаров..."
                                class="input input-bordered w-full pl-10 truncate"
							/>
						</div>
					</div>
					<button 
						on:click={() => showFilters = !showFilters}
						class="btn btn-outline"
					>
						<Icon icon="mdi:filter-variant" class="w-4 h-4 mr-2" />
						Фильтры
					</button>
					<select bind:value={sortBy} class="select select-bordered">
						<option value="newest">Сначала новые</option>
						<option value="price_low">Дешевле</option>
						<option value="price_high">Дороже</option>
						<option value="popular">Популярные</option>
					</select>
				</div>

				<!-- Categories -->
                <div class="flex flex-wrap gap-2 mb-4">
					<button 
						on:click={() => selectedCategory = ''}
						class="btn btn-sm {selectedCategory === '' ? 'btn-primary' : 'btn-ghost'}"
					>
						Все категории
					</button>
					{#each categories as category}
						<button 
							on:click={() => selectedCategory = category.id}
							class="btn btn-sm {selectedCategory === category.id ? 'btn-primary' : 'btn-ghost'}"
                        >
                            <Icon icon={category.icon} class="w-4 h-4 mr-1 flex-shrink-0" />
                            <span class="truncate max-w-[10rem] sm:max-w-none">{category.name}</span>
						</button>
					{/each}
				</div>

				<!-- Advanced Filters -->
				{#if showFilters}
					<div class="border-t pt-4 grid grid-cols-1 md:grid-cols-3 gap-4">
						<div>
							<label class="label">
								<span class="label-text">Цена от</span>
							</label>
							<input 
								type="number" 
								bind:value={priceRange.min}
								placeholder="0"
								class="input input-bordered input-sm"
							/>
						</div>
						<div>
							<label class="label">
								<span class="label-text">Цена до</span>
							</label>
							<input 
								type="number" 
								bind:value={priceRange.max}
								placeholder="Любая"
								class="input input-bordered input-sm"
							/>
						</div>
						<div>
							<label class="label">
								<span class="label-text">Состояние</span>
							</label>
							<select bind:value={selectedCondition} class="select select-bordered select-sm">
								<option value="">Любое</option>
								<option value="new">Новое</option>
								<option value="like_new">Как новое</option>
								<option value="good">Хорошее</option>
								<option value="fair">Удовлетворительное</option>
								<option value="poor">Плохое</option>
							</select>
						</div>
						<div>
							<label class="label">
								<span class="label-text">Местоположение</span>
							</label>
							<input 
								type="text" 
								bind:value={locationFilter}
								placeholder="Город, регион"
								class="input input-bordered input-sm"
							/>
						</div>
						<div class="flex items-end">
							<button on:click={clearFilters} class="btn btn-ghost btn-sm">
								<Icon icon="mdi:filter-off" class="w-4 h-4 mr-1" />
								Сбросить
							</button>
						</div>
					</div>
				{/if}
			</div>

			<!-- Items Grid -->
			{#if items.length === 0}
				<div class="text-center py-12">
					<Icon icon="mdi:package-variant-closed" class="w-16 h-16 text-gray-400 mx-auto mb-4" />
					<h3 class="text-lg font-medium text-gray-900 mb-2">Товары не найдены</h3>
					<p class="text-gray-500">Попробуйте изменить параметры поиска</p>
				</div>
			{:else}
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
					{#each items as item}
                        <div class="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow overflow-hidden">
							<!-- Image -->
						<div class="bg-gray-100 relative h-56 sm:h-64">
								{#if item.marketplace_item_images?.length > 0}
									<img 
										src={item.marketplace_item_images.find(img => img.is_primary)?.image_url || item.marketplace_item_images[0]?.image_url} 
										alt={item.title}
										class="w-full h-full object-cover"
									/>
								{:else}
									<div class="w-full h-full flex items-center justify-center">
										<Icon icon="mdi:image" class="w-12 h-12 text-gray-400" />
									</div>
								{/if}
								
								<!-- Favorite Button -->
								<button 
									on:click={() => toggleFavorite(item.id)}
									class="absolute top-2 right-2 btn btn-sm btn-circle btn-ghost bg-white/80 hover:bg-white"
								>
									<Icon icon="mdi:heart" class="w-4 h-4 text-red-500" />
								</button>
								
								<!-- Condition Badge -->
								<div class="absolute top-2 left-2">
									<span class="badge {getConditionColor(item.condition)} badge-sm">
										{formatCondition(item.condition)}
									</span>
								</div>
							</div>
							
							<!-- Content -->
                            <div class="p-4">
                                <h3 class="font-medium text-gray-900 mb-2 line-clamp-2 break-words">
									<a href="/marketplace/item/{item.id}" class="hover:text-primary">
										{item.title}
									</a>
								</h3>
								
                                <p class="text-sm text-gray-500 mb-3 line-clamp-2 break-words">
									{item.description}
								</p>
								
								<div class="flex items-center justify-between mb-3">
									<span class="text-lg font-semibold text-primary">
										{formatPrice(item.price)}
									</span>
									{#if item.location}
										<span class="text-xs text-gray-500 flex items-center">
											<Icon icon="mdi:map-marker" class="w-3 h-3 mr-1" />
											{item.location}
										</span>
									{/if}
								</div>
								
								<div class="flex items-center justify-between text-xs text-gray-500 mb-3">
									<span class="flex items-center">
										<Icon icon="mdi:eye" class="w-3 h-3 mr-1" />
										{item.views_count}
									</span>
									<span>
										{new Date(item.created_at).toLocaleDateString('ru-RU')}
									</span>
								</div>
								
								<!-- Seller Info -->
								{#if item.user_profiles}
									<div class="flex items-center justify-between text-xs text-gray-500 mb-4">
										<span class="flex items-center">
											<Icon icon="mdi:account" class="w-3 h-3 mr-1" />
											{item.user_profiles.first_name} {item.user_profiles.last_name}
										</span>
									</div>
								{/if}
								
								<!-- Actions -->
								<div class="flex space-x-2">
									<a 
										href="/marketplace/item/{item.id}"
										class="btn btn-outline btn-sm flex-1"
									>
										Подробнее
									</a>
									{#if item.seller_id !== user?.id}
										<button 
											on:click={() => addToCart(item.id)}
											class="btn btn-primary btn-sm"
											title="Добавить в корзину"
										>
											<Icon icon="mdi:cart-plus" class="w-4 h-4" />
										</button>
									{/if}
								</div>
							</div>
						</div>
					{/each}
				</div>
			{/if}
		{/if}
	</div>
</div>

<style>
	.line-clamp-2 {
		display: -webkit-box;
		-webkit-line-clamp: 2;
		-webkit-box-orient: vertical;
		overflow: hidden;
	}
</style>
