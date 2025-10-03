<script lang="ts">
	import Icon from '@iconify/svelte'
	import { onMount } from 'svelte'
	import { goto } from '$app/navigation'
	import { supabase, marketplaceService } from '$lib/supabase'
	
	let user: any = null
	let favorites: any[] = []
	let isLoading = true
	let isUpdating = false
	
	onMount(async () => {
		await checkAuth()
		await loadFavorites()
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
	
	async function loadFavorites() {
		try {
			const { data } = await marketplaceService.getFavorites(user.id)
			favorites = data || []
		} catch (error) {
			console.error('Error loading favorites:', error)
		}
	}
	
	async function removeFromFavorites(itemId: string) {
		isUpdating = true
		try {
			await marketplaceService.removeFromFavorites(user.id, itemId)
			await loadFavorites()
		} catch (error) {
			console.error('Error removing favorite:', error)
		} finally {
			isUpdating = false
		}
	}
	
	async function addToCart(itemId: string) {
		try {
			await marketplaceService.addToCart(user.id, itemId)
			// Show success message or update UI
		} catch (error) {
			console.error('Error adding to cart:', error)
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
</script>

<svelte:head>
	<title>Избранное - Магазин Маннру</title>
</svelte:head>

<div class="min-h-screen bg-gray-50">
	<!-- Header -->
	<nav class="bg-white shadow-sm border-b">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between items-center h-16">
				<div class="flex items-center space-x-4">
					<a href="/marketplace" class="flex items-center">
						<Icon icon="mdi:arrow-left" class="w-5 h-5 text-gray-500 mr-2" />
						<span class="text-gray-500">Назад к магазину</span>
					</a>
				</div>
				<h1 class="text-lg font-medium text-gray-900">
					<Icon icon="mdi:heart" class="w-5 h-5 text-red-500 inline mr-2" />
					Избранное ({favorites.length})
				</h1>
			</div>
		</div>
	</nav>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		{#if isLoading}
			<div class="text-center py-12">
				<Icon icon="mdi:loading" class="w-12 h-12 animate-spin text-primary mx-auto mb-4" />
				<p class="text-gray-600">Загрузка избранного...</p>
			</div>
		{:else if favorites.length === 0}
			<div class="text-center py-12">
				<Icon icon="mdi:heart-outline" class="w-16 h-16 text-gray-400 mx-auto mb-4" />
				<h3 class="text-lg font-medium text-gray-900 mb-2">Нет избранных товаров</h3>
				<p class="text-gray-500 mb-4">Добавляйте товары в избранное для быстрого доступа</p>
				<a href="/marketplace" class="btn btn-primary">
					<Icon icon="mdi:store" class="w-4 h-4 mr-2" />
					Перейти в магазин
				</a>
			</div>
		{:else}
			<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
				{#each favorites as favorite}
					{@const item = favorite.marketplace_items}
					<div class="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow overflow-hidden">
						<!-- Image -->
						<div class="bg-gray-100 relative h-48 sm:h-56">
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
							
							<!-- Remove from Favorites Button -->
							<button 
								on:click={() => removeFromFavorites(item.id)}
								class="absolute top-2 right-2 btn btn-sm btn-circle btn-error bg-red-500 hover:bg-red-600 text-white border-0"
								disabled={isUpdating}
								title="Удалить из избранного"
							>
								<Icon icon="mdi:heart" class="w-4 h-4" />
							</button>
							
							<!-- Condition Badge -->
							<div class="absolute top-2 left-2">
								<span class="badge {getConditionColor(item.condition)} badge-sm">
									{formatCondition(item.condition)}
								</span>
							</div>
							
							<!-- Added Date -->
							<div class="absolute bottom-2 left-2">
								<span class="bg-black/50 text-white text-xs px-2 py-1 rounded">
									{new Date(favorite.created_at).toLocaleDateString('ru-RU')}
								</span>
							</div>
						</div>
						
						<!-- Content -->
						<div class="p-4">
							<h3 class="font-medium text-gray-900 mb-2 line-clamp-2">
								<a href="/marketplace/item/{item.id}" class="hover:text-primary">
									{item.title}
								</a>
							</h3>
							
							<p class="text-sm text-gray-500 mb-3 line-clamp-2">
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
								<span class="flex items-center">
									<Icon icon={item.marketplace_categories?.icon || 'mdi:tag'} class="w-3 h-3 mr-1" />
									{item.marketplace_categories?.name}
								</span>
							</div>
							
							<!-- Seller Info -->
							{#if item.user_profiles}
								<div class="flex items-center text-xs text-gray-500 mb-4">
									<Icon icon="mdi:account" class="w-3 h-3 mr-1" />
									<span>{item.user_profiles.first_name} {item.user_profiles.last_name}</span>
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
								{#if item.seller_id !== user?.id && item.status === 'active'}
									<button 
										on:click={() => addToCart(item.id)}
										class="btn btn-primary btn-sm"
										title="Добавить в корзину"
									>
										<Icon icon="mdi:cart-plus" class="w-4 h-4" />
									</button>
								{:else if item.status !== 'active'}
									<div class="btn btn-disabled btn-sm">
										{item.status === 'sold' ? 'Продано' : 'Недоступно'}
									</div>
								{/if}
							</div>
						</div>
					</div>
				{/each}
			</div>
			
			<!-- Actions Footer -->
			<div class="mt-8 text-center">
				<div class="bg-white rounded-lg shadow-sm p-6">
					<h3 class="text-lg font-medium text-gray-900 mb-4">
						У вас {favorites.length} товар{favorites.length === 1 ? '' : favorites.length < 5 ? 'а' : 'ов'} в избранном
					</h3>
					<div class="flex justify-center space-x-4">
						<a href="/marketplace" class="btn btn-primary">
							<Icon icon="mdi:store" class="w-4 h-4 mr-2" />
							Продолжить покупки
						</a>
						<a href="/marketplace/cart" class="btn btn-outline">
							<Icon icon="mdi:cart" class="w-4 h-4 mr-2" />
							Перейти в корзину
						</a>
					</div>
				</div>
			</div>
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
