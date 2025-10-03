<script lang="ts">
	import Icon from '@iconify/svelte'
	import { onMount } from 'svelte'
	import { page } from '$app/stores'
	import { goto } from '$app/navigation'
	import { supabase, marketplaceService } from '$lib/supabase'
	
	let user: any = null
	let item: any = null
	let reviews: any[] = []
	let messages: any[] = []
	let isFavorite = false
	let isLoading = true
	let isLoadingMessages = false
	let currentImageIndex = 0
	
	// Forms
	let messageText = ''
	let reviewForm = {
		rating: 5,
		title: '',
		comment: ''
	}
	
	// Modal states
	let showMessageModal = false
	let showReviewModal = false
	let showImageModal = false
	
	let errorMessage = ''
	let successMessage = ''
	
	$: itemId = $page.params.id
	
	onMount(async () => {
		await checkAuth()
		await loadItem()
		if (item) {
			await Promise.all([
				loadReviews(),
				checkFavoriteStatus()
			])
		}
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
	
	async function loadItem() {
		try {
			const { data, error } = await marketplaceService.getItem(itemId)
			if (error) {
				console.error('Error loading item:', error)
				goto('/marketplace')
				return
			}
			item = data
		} catch (error) {
			console.error('Error loading item:', error)
			goto('/marketplace')
		}
	}
	
	async function loadReviews() {
		try {
			const { data } = await marketplaceService.getItemReviews(itemId)
			reviews = data || []
		} catch (error) {
			console.error('Error loading reviews:', error)
		}
	}
	
	async function checkFavoriteStatus() {
		try {
			const { isFavorite: favorite } = await marketplaceService.isFavorite(user.id, itemId)
			isFavorite = favorite
		} catch (error) {
			console.error('Error checking favorite status:', error)
		}
	}
	
	async function toggleFavorite() {
		try {
			if (isFavorite) {
				await marketplaceService.removeFromFavorites(user.id, itemId)
			} else {
				await marketplaceService.addToFavorites(user.id, itemId)
			}
			isFavorite = !isFavorite
		} catch (error) {
			console.error('Error toggling favorite:', error)
		}
	}
	
	async function addToCart() {
		try {
			await marketplaceService.addToCart(user.id, itemId)
			successMessage = 'Товар добавлен в корзину!'
			setTimeout(() => successMessage = '', 3000)
		} catch (error) {
			console.error('Error adding to cart:', error)
			errorMessage = 'Ошибка добавления в корзину'
		}
	}
	
	async function loadMessages() {
		if (!showMessageModal) return
		
		isLoadingMessages = true
		try {
			const { data } = await marketplaceService.getItemMessages(itemId, user.id)
			messages = data || []
			// Mark messages as read
			await marketplaceService.markMessagesAsRead(itemId, user.id)
		} catch (error) {
			console.error('Error loading messages:', error)
		} finally {
			isLoadingMessages = false
		}
	}
	
	async function sendMessage() {
		if (!messageText.trim()) return
		
		try {
			await marketplaceService.sendMessage({
				item_id: itemId,
				sender_id: user.id,
				recipient_id: item.seller_id,
				message: messageText.trim()
			})
			
			messageText = ''
			await loadMessages()
		} catch (error) {
			console.error('Error sending message:', error)
		}
	}
	
	async function submitReview() {
		if (!reviewForm.comment.trim()) return
		
		try {
			// This would typically require an order to review
			const { data, error } = await marketplaceService.createReview({
				item_id: itemId,
				reviewer_id: user.id,
				reviewee_id: item.seller_id,
				rating: reviewForm.rating,
				title: reviewForm.title,
				comment: reviewForm.comment,
				is_seller_review: false
			})
			if (error) throw error
			// Optimistically update the list without a full reload
			if (data && data.length > 0) {
				reviews = [data[0], ...reviews]
			} else {
				// fallback: ensure it appears even if select() returns nothing
				reviews = [{
					id: crypto?.randomUUID?.() || Math.random().toString(36).slice(2),
					item_id: itemId,
					reviewer_id: user.id,
					reviewee_id: item.seller_id,
					rating: reviewForm.rating,
					title: reviewForm.title,
					comment: reviewForm.comment,
					created_at: new Date().toISOString()
				}, ...reviews]
			}
			
			showReviewModal = false
			reviewForm = { rating: 5, title: '', comment: '' }
			successMessage = 'Отзыв добавлен!'
		} catch (error) {
			console.error('Error submitting review:', error)
			errorMessage = 'Ошибка добавления отзыва'
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
	
	function getAverageRating() {
		if (reviews.length === 0) return 0
		const sum = reviews.reduce((acc, review) => acc + review.rating, 0)
		return sum / reviews.length
	}
	
	$: if (showMessageModal) {
		loadMessages()
	}
</script>

<svelte:head>
	<title>{item?.title || 'Товар'} - Магазин Маннру</title>
</svelte:head>

<div class="min-h-screen bg-gray-50">
	{#if isLoading}
		<div class="text-center py-12">
			<Icon icon="mdi:loading" class="w-12 h-12 animate-spin text-primary mx-auto mb-4" />
			<p class="text-gray-600">Загрузка товара...</p>
		</div>
	{:else if !item}
		<div class="text-center py-12">
			<Icon icon="mdi:alert-circle" class="w-16 h-16 text-gray-400 mx-auto mb-4" />
			<h3 class="text-lg font-medium text-gray-900 mb-2">Товар не найден</h3>
			<a href="/marketplace" class="btn btn-primary">Вернуться в магазин</a>
		</div>
	{:else}
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
					<div class="flex items-center space-x-3">
						<button 
							on:click={toggleFavorite}
							class="btn btn-ghost btn-sm"
							title={isFavorite ? 'Удалить из избранного' : 'Добавить в избранное'}
						>
							<Icon icon="mdi:heart" class="w-4 h-4 {isFavorite ? 'text-red-500' : 'text-gray-400'}" />
						</button>
						<a href="/marketplace/cart" class="btn btn-ghost btn-sm">
							<Icon icon="mdi:cart" class="w-4 h-4" />
						</a>
					</div>
				</div>
			</div>
		</nav>

		{#if errorMessage}
			<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-4">
				<div class="alert alert-error">
					<Icon icon="mdi:alert-circle" class="w-5 h-5" />
					{errorMessage}
				</div>
			</div>
		{/if}
		
		{#if successMessage}
			<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-4">
				<div class="alert alert-success">
					<Icon icon="mdi:check-circle" class="w-5 h-5" />
					{successMessage}
				</div>
			</div>
		{/if}

		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
			<div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
				<!-- Images -->
				<div class="space-y-4">
					<div class="bg-gray-100 rounded-lg overflow-hidden relative h-80 sm:h-[28rem]">
						{#if item.marketplace_item_images?.length > 0}
							<img 
								src={item.marketplace_item_images[currentImageIndex]?.image_url || item.marketplace_item_images[0]?.image_url} 
								alt={item.title}
								class="w-full h-full object-cover cursor-pointer"
								on:click={() => showImageModal = true}
							/>
							{#if item.marketplace_item_images.length > 1}
								<div class="absolute bottom-4 left-1/2 transform -translate-x-1/2 flex space-x-2">
									{#each item.marketplace_item_images as _, index}
										<button 
											on:click={() => currentImageIndex = index}
											class="w-2 h-2 rounded-full {index === currentImageIndex ? 'bg-white' : 'bg-white/50'}"
										></button>
									{/each}
								</div>
							{/if}
						{:else}
							<div class="w-full h-full flex items-center justify-center">
								<Icon icon="mdi:image" class="w-16 h-16 text-gray-400" />
							</div>
						{/if}
					</div>
					
					<!-- Thumbnail Images -->
					{#if item.marketplace_item_images?.length > 1}
						<div class="grid grid-cols-4 gap-2">
							{#each item.marketplace_item_images as image, index}
								<button 
									on:click={() => currentImageIndex = index}
									class="aspect-square bg-gray-100 rounded-lg overflow-hidden {index === currentImageIndex ? 'ring-2 ring-primary' : ''}"
								>
									<img 
										src={image.image_url} 
										alt={item.title}
										class="w-full h-full object-cover"
									/>
								</button>
							{/each}
						</div>
					{/if}
				</div>
				
				<!-- Item Details -->
				<div class="space-y-6">
					<div>
						<div class="flex items-start justify-between mb-4">
							<div class="flex-1">
								<h1 class="text-3xl font-light text-gray-900 mb-2">{item.title}</h1>
								<div class="flex items-center space-x-3">
									<span class="badge {getConditionColor(item.condition)}">
										{formatCondition(item.condition)}
									</span>
									{#if item.marketplace_categories}
										<span class="flex items-center text-sm text-gray-500">
											<Icon icon={item.marketplace_categories.icon} class="w-4 h-4 mr-1" />
											{item.marketplace_categories.name}
										</span>
									{/if}
								</div>
							</div>
						</div>
						
						<div class="text-4xl font-semibold text-primary mb-4">
							{formatPrice(item.price)}
						</div>
						
						<div class="flex items-center space-x-4 text-sm text-gray-500 mb-6">
							<span class="flex items-center">
								<Icon icon="mdi:eye" class="w-4 h-4 mr-1" />
								{item.views_count} просмотров
							</span>
							<span class="flex items-center">
								<Icon icon="mdi:clock" class="w-4 h-4 mr-1" />
								{new Date(item.created_at).toLocaleDateString('ru-RU')}
							</span>
							{#if item.location}
								<span class="flex items-center">
									<Icon icon="mdi:map-marker" class="w-4 h-4 mr-1" />
									{item.location}
								</span>
							{/if}
						</div>
					</div>
					
					<!-- Description -->
					<div>
						<h3 class="text-lg font-medium text-gray-900 mb-3">Описание</h3>
						<p class="text-gray-700 whitespace-pre-line">{item.description}</p>
					</div>
					
					<!-- Tags -->
					{#if item.tags?.length > 0}
						<div>
							<h3 class="text-lg font-medium text-gray-900 mb-3">Теги</h3>
							<div class="flex flex-wrap gap-2">
								{#each item.tags as tag}
									<span class="badge badge-outline">{tag}</span>
								{/each}
							</div>
						</div>
					{/if}
					
					<!-- Seller Info -->
					{#if item.user_profiles}
						<div class="bg-gray-50 rounded-lg p-4">
							<h3 class="text-lg font-medium text-gray-900 mb-3">Продавец</h3>
							<div class="flex items-center space-x-3">
								<div class="w-12 h-12 bg-primary rounded-full flex items-center justify-center">
									<Icon icon="mdi:account" class="w-6 h-6 text-white" />
								</div>
								<div>
									<p class="font-medium text-gray-900">
										{item.user_profiles.first_name} {item.user_profiles.last_name}
									</p>
									<p class="text-sm text-gray-500">
										На сайте с {new Date(item.user_profiles.created_at).toLocaleDateString('ru-RU')}
									</p>
								</div>
							</div>
						</div>
					{/if}
					
					<!-- Shipping Options -->
					<div class="bg-gray-50 rounded-lg p-4">
						<h3 class="text-lg font-medium text-gray-900 mb-3">Способы получения</h3>
						<div class="space-y-2">
							{#if item.pickup_available}
								<div class="flex items-center">
									<Icon icon="mdi:check-circle" class="w-5 h-5 text-green-500 mr-2" />
									<span>Самовывоз</span>
								</div>
							{/if}
							{#if item.shipping_available}
								<div class="flex items-center justify-between">
									<div class="flex items-center">
										<Icon icon="mdi:check-circle" class="w-5 h-5 text-green-500 mr-2" />
										<span>Доставка</span>
									</div>
									{#if item.shipping_cost > 0}
										<span class="text-sm text-gray-600">
											{formatPrice(item.shipping_cost)}
										</span>
									{:else}
										<span class="text-sm text-green-600">Бесплатно</span>
									{/if}
								</div>
							{/if}
						</div>
					</div>
					
					<!-- Actions -->
					{#if item.seller_id !== user?.id && item.status === 'active'}
						<div class="space-y-3">
							<button 
								on:click={addToCart}
								class="btn btn-primary w-full"
							>
								<Icon icon="mdi:cart-plus" class="w-5 h-5 mr-2" />
								Добавить в корзину
							</button>
							<button 
								on:click={() => showMessageModal = true}
								class="btn btn-outline w-full"
							>
								<Icon icon="mdi:message" class="w-5 h-5 mr-2" />
								Написать продавцу
							</button>
						</div>
					{:else if item.seller_id === user?.id}
						<div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
							<p class="text-blue-700 font-medium">Это ваше объявление</p>
							<p class="text-blue-600 text-sm mt-1">Вы можете редактировать его в личном кабинете</p>
						</div>
					{:else}
						<div class="bg-gray-50 border border-gray-200 rounded-lg p-4">
							<p class="text-gray-700 font-medium">Товар недоступен</p>
							<p class="text-gray-600 text-sm mt-1">Этот товар больше не продается</p>
						</div>
					{/if}
				</div>
			</div>
			
			<!-- Reviews Section -->
			<div class="mt-12">
				<div class="bg-white rounded-lg shadow-sm p-6">
					<div class="flex items-center justify-between mb-6">
						<h2 class="text-2xl font-light text-gray-900">
							Отзывы ({reviews.length})
						</h2>
						{#if reviews.length > 0}
							<div class="flex items-center space-x-2">
								<div class="flex">
									{#each Array(5) as _, i}
										<Icon 
											icon="mdi:star" 
											class="w-5 h-5 {i < Math.round(getAverageRating()) ? 'text-yellow-400' : 'text-gray-300'}" 
										/>
									{/each}
								</div>
								<span class="text-sm text-gray-600">
									{getAverageRating().toFixed(1)} из 5
								</span>
							</div>
						{/if}
					</div>
					
					{#if reviews.length === 0}
						<div class="text-center py-8">
							<Icon icon="mdi:comment-outline" class="w-12 h-12 text-gray-400 mx-auto mb-4" />
							<p class="text-gray-500">Пока нет отзывов</p>
							<button 
								on:click={() => showReviewModal = true}
								class="btn btn-primary btn-sm mt-4"
							>
								Оставить первый отзыв
							</button>
						</div>
					{:else}
						<div class="space-y-4">
							{#each reviews as review}
								<div class="border-b border-gray-200 pb-4">
									<div class="flex items-start justify-between mb-2">
										<div>
											<h4 class="font-medium text-gray-900">
												{review.user_profiles?.first_name} {review.user_profiles?.last_name}
											</h4>
											{#if review.title}
												<p class="text-sm font-medium text-gray-700">{review.title}</p>
											{/if}
										</div>
										<div class="flex items-center space-x-2">
											<div class="flex">
												{#each Array(5) as _, i}
													<Icon 
														icon="mdi:star" 
														class="w-4 h-4 {i < review.rating ? 'text-yellow-400' : 'text-gray-300'}" 
													/>
												{/each}
											</div>
											<span class="text-xs text-gray-500">
												{new Date(review.created_at).toLocaleDateString('ru-RU')}
											</span>
										</div>
									</div>
									<p class="text-gray-700">{review.comment}</p>
								</div>
							{/each}
						</div>
						<button 
							on:click={() => showReviewModal = true}
							class="btn btn-outline btn-sm mt-4"
						>
							<Icon icon="mdi:plus" class="w-4 h-4 mr-2" />
							Добавить отзыв
						</button>
					{/if}
				</div>
			</div>
		</div>
	{/if}
</div>

<!-- Message Modal -->
{#if showMessageModal}
	<div class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 animate-in fade-in duration-200">
		<div class="modal-container bg-white rounded-lg w-full max-w-2xl max-h-[90vh] overflow-y-auto p-6 animate-in zoom-in-95 duration-200 slide-in-from-bottom-4 m-4">
			<div class="flex justify-between items-center mb-6">
				<h3 class="text-xl font-light text-gray-900">Сообщения с продавцом</h3>
				<button 
					on:click={() => showMessageModal = false}
					class="text-gray-400 hover:text-gray-600"
				>
					<Icon icon="mdi:close" class="w-6 h-6" />
				</button>
			</div>
			
			{#if isLoadingMessages}
				<div class="text-center py-8">
					<Icon icon="mdi:loading" class="w-8 h-8 animate-spin text-primary mx-auto mb-2" />
					<p class="text-gray-500">Загрузка сообщений...</p>
				</div>
			{:else}
				<div class="max-h-96 overflow-y-auto mb-4 space-y-4">
					{#each messages as message}
						<div class="flex {message.sender_id === user.id ? 'justify-end' : 'justify-start'}">
							<div class="max-w-xs lg:max-w-md px-4 py-2 rounded-lg {message.sender_id === user.id ? 'bg-primary text-white' : 'bg-gray-100 text-gray-900'}">
								<p class="text-sm">{message.message}</p>
								<p class="text-xs {message.sender_id === user.id ? 'text-primary-content/70' : 'text-gray-500'} mt-1">
									{new Date(message.created_at).toLocaleString('ru-RU')}
								</p>
							</div>
						</div>
					{/each}
				</div>
				
				<div class="flex space-x-2">
					<input 
						type="text" 
						bind:value={messageText}
						placeholder="Написать сообщение..."
						class="input input-bordered flex-1"
						on:keydown={(e) => e.key === 'Enter' && sendMessage()}
					/>
					<button 
						on:click={sendMessage}
						class="btn btn-primary"
						disabled={!messageText.trim()}
					>
						<Icon icon="mdi:send" class="w-4 h-4" />
					</button>
				</div>
			{/if}
		</div>
	</div>
{/if}

<!-- Review Modal -->
{#if showReviewModal}
	<div class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 animate-in fade-in duration-200">
		<div class="modal-container bg-white rounded-lg w-full max-w-md max-h-[90vh] overflow-y-auto p-6 animate-in zoom-in-95 duration-200 slide-in-from-bottom-4 m-4">
			<div class="flex justify-between items-center mb-6">
				<h3 class="text-xl font-light text-gray-900">Оставить отзыв</h3>
				<button 
					on:click={() => showReviewModal = false}
					class="text-gray-400 hover:text-gray-600"
				>
					<Icon icon="mdi:close" class="w-6 h-6" />
				</button>
			</div>
			
			<form on:submit|preventDefault={submitReview} class="space-y-4">
				<div class="form-control">
					<label class="label">
						<span class="label-text">Оценка</span>
					</label>
					<div class="flex space-x-1">
						{#each Array(5) as _, i}
							<button 
								type="button"
								on:click={() => reviewForm.rating = i + 1}
								class="btn btn-ghost btn-sm p-1"
							>
								<Icon 
									icon="mdi:star" 
									class="w-6 h-6 {i < reviewForm.rating ? 'text-yellow-400' : 'text-gray-300'}" 
								/>
							</button>
						{/each}
					</div>
				</div>
				
				<div class="form-control">
					<label class="label">
						<span class="label-text">Заголовок (необязательно)</span>
					</label>
					<input 
						type="text" 
						bind:value={reviewForm.title}
						placeholder="Краткое резюме"
						class="input input-bordered"
					/>
				</div>
				
				<div class="form-control">
					<label class="label">
						<span class="label-text">Комментарий</span>
					</label>
					<textarea 
						bind:value={reviewForm.comment}
						placeholder="Расскажите о своем опыте..."
						class="textarea textarea-bordered h-24"
						required
					></textarea>
				</div>
				
				<div class="flex justify-end space-x-3 mt-6">
					<button 
						type="button" 
						on:click={() => showReviewModal = false}
						class="btn btn-ghost"
					>
						Отмена
					</button>
					<button 
						type="submit"
						class="btn btn-primary"
						disabled={!reviewForm.comment.trim()}
					>
						<Icon icon="mdi:check" class="w-4 h-4 mr-2" />
						Отправить отзыв
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}

<!-- Image Modal -->
{#if showImageModal && item?.marketplace_item_images?.length > 0}
	<div class="fixed inset-0 bg-black/90 flex items-center justify-center z-50" on:click={() => showImageModal = false}>
		<div class="max-w-4xl max-h-full p-4">
			<img 
				src={item.marketplace_item_images[currentImageIndex]?.image_url} 
				alt={item.title}
				class="max-w-full max-h-full object-contain"
			/>
		</div>
		<button 
			on:click={() => showImageModal = false}
			class="absolute top-4 right-4 text-white hover:text-gray-300"
		>
			<Icon icon="mdi:close" class="w-8 h-8" />
		</button>
	</div>
{/if}
