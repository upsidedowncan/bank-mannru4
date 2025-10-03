<script lang="ts">
	import Icon from '@iconify/svelte'
	import { onMount } from 'svelte'
	import { goto } from '$app/navigation'
	import { supabase, marketplaceService, bankService } from '$lib/supabase'
	
	let user: any = null
	let cartItems: any[] = []
	let userCards: any[] = []
	let isLoading = true
	let isUpdating = false
	let isCheckingOut = false
	
	// Checkout form
	let checkoutForm = {
		payment_card_id: '',
		shipping_address: {
			street: '',
			city: '',
			postal_code: '',
			country: 'Россия'
		},
		notes: ''
	}
	
	let showCheckout = false
	let errorMessage = ''
	let successMessage = ''
	
	onMount(async () => {
		await checkAuth()
		await Promise.all([
			loadCartItems(),
			loadUserCards()
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
	
	async function loadCartItems() {
		try {
			const { data } = await marketplaceService.getCart(user.id)
			cartItems = data || []
		} catch (error) {
			console.error('Error loading cart:', error)
		}
	}
	
	async function loadUserCards() {
		try {
			const cards = await bankService.getUserCards(user.id)
			userCards = cards || []
		} catch (error) {
			console.error('Error loading cards:', error)
		}
	}
	
	async function updateQuantity(itemId: string, quantity: number) {
		if (quantity <= 0) {
			await removeFromCart(itemId)
			return
		}
		
		isUpdating = true
		try {
			await marketplaceService.updateCartQuantity(user.id, itemId, quantity)
			await loadCartItems()
		} catch (error) {
			console.error('Error updating quantity:', error)
		} finally {
			isUpdating = false
		}
	}
	
	async function removeFromCart(itemId: string) {
		isUpdating = true
		try {
			await marketplaceService.removeFromCart(user.id, itemId)
			await loadCartItems()
		} catch (error) {
			console.error('Error removing item:', error)
		} finally {
			isUpdating = false
		}
	}
	
	async function clearCart() {
		if (!confirm('Очистить корзину?')) return
		
		isUpdating = true
		try {
			await marketplaceService.clearCart(user.id)
			await loadCartItems()
		} catch (error) {
			console.error('Error clearing cart:', error)
		} finally {
			isUpdating = false
		}
	}
	
	async function proceedToCheckout() {
		if (!validateCheckout()) return
		
		isCheckingOut = true
		errorMessage = ''
		successMessage = ''
		
		try {
			const totalAmount = getTotalPrice()
			const shippingCost = getTotalShipping()
			
			const orderData = {
				buyer_id: user.id,
				seller_id: cartItems[0].marketplace_items.seller_id, // Simplified for single seller
				total_amount: totalAmount + shippingCost,
				currency: 'МР',
				status: 'pending',
				payment_method: 'card',
				payment_card_id: checkoutForm.payment_card_id,
				shipping_address: checkoutForm.shipping_address,
				shipping_cost: shippingCost,
				notes: checkoutForm.notes
			}
			
			const { data: order, error } = await marketplaceService.createOrder(orderData, cartItems)
			
			if (error) {
				errorMessage = 'Ошибка создания заказа: ' + error.message
				return
			}
			
			// Clear cart after successful order
			await marketplaceService.clearCart(user.id)
			
			successMessage = `Заказ ${order.order_number} успешно создан!`
			
			// Redirect to orders page
			setTimeout(() => {
				goto('/marketplace/orders')
			}, 2000)
			
		} catch (error: any) {
			errorMessage = error.message || 'Произошла ошибка при оформлении заказа'
		} finally {
			isCheckingOut = false
		}
	}
	
	function validateCheckout() {
		if (!checkoutForm.payment_card_id) {
			errorMessage = 'Выберите карту для оплаты'
			return false
		}
		if (!checkoutForm.shipping_address.street || !checkoutForm.shipping_address.city) {
			errorMessage = 'Заполните адрес доставки'
			return false
		}
		return true
	}
	
	function getTotalPrice() {
		return cartItems.reduce((total, item) => {
			return total + (item.marketplace_items.price * item.quantity)
		}, 0)
	}
	
	function getTotalShipping() {
		return cartItems.reduce((total, item) => {
			return total + (item.marketplace_items.shipping_cost || 0)
		}, 0)
	}
	
	function formatPrice(price: number) {
		return new Intl.NumberFormat('ru-RU').format(price) + ' МР'
	}
</script>

<svelte:head>
	<title>Корзина - Магазин Маннру</title>
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
					Корзина ({cartItems.length})
				</h1>
			</div>
		</div>
	</nav>

	<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		{#if isLoading}
			<div class="text-center py-12">
				<Icon icon="mdi:loading" class="w-12 h-12 animate-spin text-primary mx-auto mb-4" />
				<p class="text-gray-600">Загрузка корзины...</p>
			</div>
		{:else if cartItems.length === 0}
			<div class="text-center py-12">
				<Icon icon="mdi:cart-outline" class="w-16 h-16 text-gray-400 mx-auto mb-4" />
				<h3 class="text-lg font-medium text-gray-900 mb-2">Корзина пуста</h3>
				<p class="text-gray-500 mb-4">Добавьте товары из магазина</p>
				<a href="/marketplace" class="btn btn-primary">
					<Icon icon="mdi:store" class="w-4 h-4 mr-2" />
					Перейти в магазин
				</a>
			</div>
		{:else}
			{#if errorMessage}
				<div class="alert alert-error mb-6">
					<Icon icon="mdi:alert-circle" class="w-5 h-5" />
					{errorMessage}
				</div>
			{/if}
			
			{#if successMessage}
				<div class="alert alert-success mb-6">
					<Icon icon="mdi:check-circle" class="w-5 h-5" />
					{successMessage}
				</div>
			{/if}
			
			<div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
				<!-- Cart Items -->
				<div class="lg:col-span-2">
					<div class="bg-white rounded-lg shadow-sm">
						<div class="p-6 border-b border-gray-200 flex justify-between items-center">
							<h2 class="text-lg font-medium text-gray-900">Товары в корзине</h2>
							<button 
								on:click={clearCart}
								class="btn btn-ghost btn-sm text-red-600"
								disabled={isUpdating}
							>
								<Icon icon="mdi:trash-can" class="w-4 h-4 mr-1" />
								Очистить
							</button>
						</div>
						
						<div class="divide-y divide-gray-200">
							{#each cartItems as item}
								<div class="p-6">
									<div class="flex items-start space-x-4">
										<!-- Image -->
										<div class="w-20 h-20 bg-gray-100 rounded-lg flex-shrink-0">
											{#if item.marketplace_items.marketplace_item_images?.length > 0}
												<img 
													src={item.marketplace_items.marketplace_item_images[0].image_url} 
													alt={item.marketplace_items.title}
													class="w-full h-full object-cover rounded-lg"
												/>
											{:else}
												<div class="w-full h-full flex items-center justify-center">
													<Icon icon="mdi:image" class="w-8 h-8 text-gray-400" />
												</div>
											{/if}
										</div>
										
										<!-- Details -->
										<div class="flex-1 min-w-0">
											<h3 class="font-medium text-gray-900">
												<a href="/marketplace/item/{item.marketplace_items.id}" class="hover:text-primary">
													{item.marketplace_items.title}
												</a>
											</h3>
											<p class="text-sm text-gray-500 mt-1">
												{item.marketplace_items.marketplace_categories?.name}
											</p>
											<p class="text-sm text-gray-500">
												Продавец: {item.marketplace_items.user_profiles?.first_name} {item.marketplace_items.user_profiles?.last_name}
											</p>
											
											<!-- Quantity Controls -->
											<div class="flex items-center space-x-3 mt-4">
												<button 
													on:click={() => updateQuantity(item.item_id, item.quantity - 1)}
													class="btn btn-sm btn-circle btn-outline"
													disabled={isUpdating}
												>
													<Icon icon="mdi:minus" class="w-4 h-4" />
												</button>
												<span class="font-medium">{item.quantity}</span>
												<button 
													on:click={() => updateQuantity(item.item_id, item.quantity + 1)}
													class="btn btn-sm btn-circle btn-outline"
													disabled={isUpdating}
												>
													<Icon icon="mdi:plus" class="w-4 h-4" />
												</button>
												<button 
													on:click={() => removeFromCart(item.item_id)}
													class="btn btn-sm btn-ghost text-red-600 ml-4"
													disabled={isUpdating}
												>
													<Icon icon="mdi:delete" class="w-4 h-4" />
												</button>
											</div>
										</div>
										
										<!-- Price -->
										<div class="text-right">
											<div class="text-lg font-semibold text-primary">
												{formatPrice(item.marketplace_items.price * item.quantity)}
											</div>
											<div class="text-sm text-gray-500">
												{formatPrice(item.marketplace_items.price)} за шт.
											</div>
											{#if item.marketplace_items.shipping_cost > 0}
												<div class="text-xs text-gray-500 mt-1">
													+ {formatPrice(item.marketplace_items.shipping_cost)} доставка
												</div>
											{/if}
										</div>
									</div>
								</div>
							{/each}
						</div>
					</div>
				</div>
				
				<!-- Order Summary -->
				<div class="lg:col-span-1">
					<div class="bg-white rounded-lg shadow-sm p-6 sticky top-6">
						<h2 class="text-lg font-medium text-gray-900 mb-4">Итого</h2>
						
						<div class="space-y-3">
							<div class="flex justify-between">
								<span class="text-gray-600">Товары:</span>
								<span>{formatPrice(getTotalPrice())}</span>
							</div>
							{#if getTotalShipping() > 0}
								<div class="flex justify-between">
									<span class="text-gray-600">Доставка:</span>
									<span>{formatPrice(getTotalShipping())}</span>
								</div>
							{/if}
							<div class="border-t pt-3">
								<div class="flex justify-between text-lg font-semibold">
									<span>К оплате:</span>
									<span class="text-primary">{formatPrice(getTotalPrice() + getTotalShipping())}</span>
								</div>
							</div>
						</div>
						
						{#if !showCheckout}
							<button 
								on:click={() => showCheckout = true}
								class="btn btn-primary w-full mt-6"
							>
								<Icon icon="mdi:credit-card" class="w-4 h-4 mr-2" />
								Оформить заказ
							</button>
						{:else}
							<!-- Checkout Form -->
							<div class="mt-6 space-y-4">
								<h3 class="font-medium text-gray-900">Оформление заказа</h3>
								
								<!-- Payment Card -->
								<div class="form-control">
									<label class="label">
										<span class="label-text">Карта для оплаты</span>
									</label>
									<select 
										bind:value={checkoutForm.payment_card_id}
										class="select select-bordered select-sm"
									>
										<option value="">Выберите карту</option>
										{#each userCards as card}
											<option value={card.id}>
												{card.card_name} (**** {card.card_number.slice(-4)})
											</option>
										{/each}
									</select>
								</div>
								
								<!-- Shipping Address -->
								<div class="space-y-3">
									<label class="label">
										<span class="label-text">Адрес доставки</span>
									</label>
									<input 
										type="text" 
										bind:value={checkoutForm.shipping_address.street}
										placeholder="Улица, дом, квартира"
										class="input input-bordered input-sm"
									/>
									<input 
										type="text" 
										bind:value={checkoutForm.shipping_address.city}
										placeholder="Город"
										class="input input-bordered input-sm"
									/>
									<input 
										type="text" 
										bind:value={checkoutForm.shipping_address.postal_code}
										placeholder="Почтовый индекс"
										class="input input-bordered input-sm"
									/>
								</div>
								
								<!-- Notes -->
								<div class="form-control">
									<label class="label">
										<span class="label-text">Комментарий к заказу</span>
									</label>
									<textarea 
										bind:value={checkoutForm.notes}
										placeholder="Дополнительные пожелания..."
										class="textarea textarea-bordered textarea-sm h-20"
									></textarea>
								</div>
								
								<div class="flex space-x-2">
									<button 
										on:click={() => showCheckout = false}
										class="btn btn-ghost btn-sm flex-1"
									>
										Назад
									</button>
									<button 
										on:click={proceedToCheckout}
										class="btn btn-primary btn-sm flex-1"
										disabled={isCheckingOut}
									>
										{#if isCheckingOut}
											<Icon icon="mdi:loading" class="w-4 h-4 animate-spin mr-1" />
											Оформление...
										{:else}
											Оплатить
										{/if}
									</button>
								</div>
							</div>
						{/if}
					</div>
				</div>
			</div>
		{/if}
	</div>
</div>
