<script lang="ts">
	import Icon from '@iconify/svelte'
	import { onMount } from 'svelte'
	import { goto } from '$app/navigation'
	import { supabase, marketplaceService } from '$lib/supabase'
	
	let user: any = null
	let orders: any[] = []
	let isLoading = true
	let activeTab = 'all' // all, buying, selling
	
	onMount(async () => {
		await checkAuth()
		await loadOrders()
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
	
	async function loadOrders() {
		try {
			const { data } = await marketplaceService.getUserOrders(user.id)
			orders = data || []
		} catch (error) {
			console.error('Error loading orders:', error)
		}
	}
	
	async function updateOrderStatus(orderId: string, status: string) {
		try {
			await marketplaceService.updateOrderStatus(orderId, status)
			await loadOrders()
		} catch (error) {
			console.error('Error updating order status:', error)
		}
	}
	
	function formatPrice(price: number) {
		return new Intl.NumberFormat('ru-RU').format(price) + ' МР'
	}
	
	function getStatusColor(status: string) {
		const colors = {
			'pending': 'badge-warning',
			'confirmed': 'badge-info',
			'shipped': 'badge-primary',
			'delivered': 'badge-success',
			'cancelled': 'badge-error',
			'refunded': 'badge-neutral'
		}
		return colors[status] || 'badge-ghost'
	}
	
	function getStatusText(status: string) {
		const statuses = {
			'pending': 'Ожидает подтверждения',
			'confirmed': 'Подтвержден',
			'shipped': 'Отправлен',
			'delivered': 'Доставлен',
			'cancelled': 'Отменен',
			'refunded': 'Возвращен'
		}
		return statuses[status] || status
	}
	
	function getFilteredOrders() {
		if (activeTab === 'buying') {
			return orders.filter(order => order.buyer_id === user.id)
		} else if (activeTab === 'selling') {
			return orders.filter(order => order.seller_id === user.id)
		}
		return orders
	}
	
	function canUpdateStatus(order: any, newStatus: string) {
		if (order.seller_id !== user.id) return false
		
		const currentStatus = order.status
		const allowedTransitions = {
			'pending': ['confirmed', 'cancelled'],
			'confirmed': ['shipped', 'cancelled'],
			'shipped': ['delivered'],
			'delivered': [],
			'cancelled': [],
			'refunded': []
		}
		
		return allowedTransitions[currentStatus]?.includes(newStatus) || false
	}
</script>

<svelte:head>
	<title>Мои заказы - Магазин Маннру</title>
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
					<Icon icon="mdi:package-variant" class="w-5 h-5 inline mr-2" />
					Мои заказы
				</h1>
			</div>
		</div>
	</nav>

	<div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		{#if isLoading}
			<div class="text-center py-12">
				<Icon icon="mdi:loading" class="w-12 h-12 animate-spin text-primary mx-auto mb-4" />
				<p class="text-gray-600">Загрузка заказов...</p>
			</div>
		{:else}
			<!-- Tabs -->
			<div class="bg-white rounded-lg shadow-sm mb-6">
				<div class="border-b border-gray-200">
					<nav class="flex space-x-8 px-6" aria-label="Tabs">
						<button
							class="py-4 px-1 border-b-2 font-medium text-sm {activeTab === 'all' ? 'border-primary text-primary' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}"
							on:click={() => activeTab = 'all'}
						>
							Все заказы ({orders.length})
						</button>
						<button
							class="py-4 px-1 border-b-2 font-medium text-sm {activeTab === 'buying' ? 'border-primary text-primary' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}"
							on:click={() => activeTab = 'buying'}
						>
							Мои покупки ({orders.filter(o => o.buyer_id === user.id).length})
						</button>
						<button
							class="py-4 px-1 border-b-2 font-medium text-sm {activeTab === 'selling' ? 'border-primary text-primary' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}"
							on:click={() => activeTab = 'selling'}
						>
							Мои продажи ({orders.filter(o => o.seller_id === user.id).length})
						</button>
					</nav>
				</div>
			</div>

			{#if getFilteredOrders().length === 0}
				<div class="text-center py-12">
					<Icon icon="mdi:package-variant-closed" class="w-16 h-16 text-gray-400 mx-auto mb-4" />
					<h3 class="text-lg font-medium text-gray-900 mb-2">Нет заказов</h3>
					<p class="text-gray-500 mb-4">
						{#if activeTab === 'buying'}
							Вы еще не делали покупок в магазине
						{:else if activeTab === 'selling'}
							У вас пока нет продаж
						{:else}
							У вас пока нет заказов
						{/if}
					</p>
					<a href="/marketplace" class="btn btn-primary">
						<Icon icon="mdi:store" class="w-4 h-4 mr-2" />
						Перейти в магазин
					</a>
				</div>
			{:else}
				<div class="space-y-6">
					{#each getFilteredOrders() as order}
						<div class="bg-white rounded-lg shadow-sm overflow-hidden">
							<!-- Order Header -->
							<div class="px-6 py-4 bg-gray-50 border-b border-gray-200">
								<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between">
									<div class="flex items-center space-x-4">
										<div>
											<h3 class="text-lg font-medium text-gray-900">
												Заказ #{order.order_number}
											</h3>
											<p class="text-sm text-gray-500">
												{new Date(order.created_at).toLocaleDateString('ru-RU', {
													year: 'numeric',
													month: 'long',
													day: 'numeric',
													hour: '2-digit',
													minute: '2-digit'
												})}
											</p>
										</div>
										<div class="flex items-center space-x-2">
											<span class="badge {getStatusColor(order.status)}">
												{getStatusText(order.status)}
											</span>
											{#if order.buyer_id === user.id}
												<span class="badge badge-outline">Покупка</span>
											{:else}
												<span class="badge badge-outline">Продажа</span>
											{/if}
										</div>
									</div>
									<div class="mt-4 sm:mt-0 text-right">
										<div class="text-2xl font-semibold text-primary">
											{formatPrice(order.total_amount)}
										</div>
										<div class="text-sm text-gray-500">
											{order.payment_method === 'card' ? 'Картой' : 'Наличными'}
										</div>
									</div>
								</div>
							</div>
							
							<!-- Order Items -->
							<div class="px-6 py-4">
								<div class="space-y-4">
									{#each order.marketplace_order_items as orderItem}
										<div class="flex items-center space-x-4">
											<div class="w-16 h-16 bg-gray-100 rounded-lg flex-shrink-0">
												{#if orderItem.marketplace_items?.images?.length > 0}
													<img 
														src={orderItem.marketplace_items.images[0]} 
														alt={orderItem.item_snapshot?.title}
														class="w-full h-full object-cover rounded-lg"
													/>
												{:else}
													<div class="w-full h-full flex items-center justify-center">
														<Icon icon="mdi:image" class="w-6 h-6 text-gray-400" />
													</div>
												{/if}
											</div>
											<div class="flex-1 min-w-0">
												<h4 class="font-medium text-gray-900">
													{orderItem.item_snapshot?.title || 'Товар удален'}
												</h4>
												<p class="text-sm text-gray-500">
													Количество: {orderItem.quantity} × {formatPrice(orderItem.unit_price)}
												</p>
											</div>
											<div class="text-right">
												<div class="font-semibold text-gray-900">
													{formatPrice(orderItem.total_price)}
												</div>
											</div>
										</div>
									{/each}
								</div>
							</div>
							
							<!-- Order Details -->
							<div class="px-6 py-4 bg-gray-50 border-t border-gray-200">
								<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
									<!-- Shipping Address -->
									{#if order.shipping_address}
										<div>
											<h4 class="font-medium text-gray-900 mb-2">Адрес доставки</h4>
											<div class="text-sm text-gray-600">
												<p>{order.shipping_address.street}</p>
												<p>{order.shipping_address.city}</p>
												{#if order.shipping_address.postal_code}
													<p>{order.shipping_address.postal_code}</p>
												{/if}
											</div>
										</div>
									{/if}
									
									<!-- Order Summary -->
									<div>
										<h4 class="font-medium text-gray-900 mb-2">Детали заказа</h4>
										<div class="text-sm text-gray-600 space-y-1">
											<div class="flex justify-between">
												<span>Товары:</span>
												<span>{formatPrice(order.total_amount - (order.shipping_cost || 0))}</span>
											</div>
											{#if order.shipping_cost > 0}
												<div class="flex justify-between">
													<span>Доставка:</span>
													<span>{formatPrice(order.shipping_cost)}</span>
												</div>
											{/if}
											<div class="flex justify-between font-semibold border-t pt-1">
												<span>Итого:</span>
												<span>{formatPrice(order.total_amount)}</span>
											</div>
										</div>
									</div>
								</div>
								
								{#if order.notes}
									<div class="mt-4">
										<h4 class="font-medium text-gray-900 mb-2">Комментарий</h4>
										<p class="text-sm text-gray-600">{order.notes}</p>
									</div>
								{/if}
							</div>
							
							<!-- Order Actions -->
							{#if order.seller_id === user.id}
								<div class="px-6 py-4 border-t border-gray-200">
									<div class="flex space-x-2">
										{#if canUpdateStatus(order, 'confirmed')}
											<button 
												on:click={() => updateOrderStatus(order.id, 'confirmed')}
												class="btn btn-success btn-sm"
											>
												<Icon icon="mdi:check" class="w-4 h-4 mr-1" />
												Подтвердить
											</button>
										{/if}
										{#if canUpdateStatus(order, 'shipped')}
											<button 
												on:click={() => updateOrderStatus(order.id, 'shipped')}
												class="btn btn-primary btn-sm"
											>
												<Icon icon="mdi:truck" class="w-4 h-4 mr-1" />
												Отправить
											</button>
										{/if}
										{#if canUpdateStatus(order, 'delivered')}
											<button 
												on:click={() => updateOrderStatus(order.id, 'delivered')}
												class="btn btn-success btn-sm"
											>
												<Icon icon="mdi:package-check" class="w-4 h-4 mr-1" />
												Доставлен
											</button>
										{/if}
										{#if canUpdateStatus(order, 'cancelled')}
											<button 
												on:click={() => updateOrderStatus(order.id, 'cancelled')}
												class="btn btn-error btn-sm"
											>
												<Icon icon="mdi:close" class="w-4 h-4 mr-1" />
												Отменить
											</button>
										{/if}
									</div>
								</div>
							{/if}
						</div>
					{/each}
				</div>
			{/if}
		{/if}
	</div>
</div>
