<script lang="ts">
	import Icon from '@iconify/svelte'
	import { onMount } from 'svelte'
	import { goto } from '$app/navigation'
	import { supabase, marketplaceService } from '$lib/supabase'
	
	let user: any = null
	let categories: any[] = []
	let isLoading = false
  let isSubmitting = false
  let uploading = false
	
  let itemForm = {
		title: '',
		description: '',
		price: '',
		category_id: '',
		condition: 'new',
		location: '',
		shipping_available: true,
		shipping_cost: '0',
		pickup_available: true,
		tags: '',
    images: []
	}

  // payout card
  let payoutCardId = ''
  let userCards: any[] = []
	
	let errorMessage = ''
	let successMessage = ''
	
	onMount(async () => {
		await checkAuth()
		await loadCategories()
    await loadUserCards()
	})
	
	async function checkAuth() {
		const { data: { user: currentUser } } = await supabase.auth.getUser()
		if (!currentUser) {
			goto('/login')
			return
		}
		user = currentUser
	}

  async function loadUserCards() {
    try {
      const { data, error } = await supabase
        .from('bank_cards')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })
      if (!error) userCards = data || []
    } catch (e) {
      console.error('Error loading cards', e)
    }
  }
	
	async function loadCategories() {
		try {
			const { data } = await marketplaceService.getCategories()
			categories = data || []
		} catch (error) {
			console.error('Error loading categories:', error)
		}
	}
	
	async function handleSubmit() {
		if (!validateForm()) return
		
		isSubmitting = true
		errorMessage = ''
		successMessage = ''
		
    try {
			const itemData = {
				seller_id: user.id,
				title: itemForm.title,
				description: itemForm.description,
				price: parseFloat(itemForm.price),
				category_id: itemForm.category_id,
				condition: itemForm.condition,
				location: itemForm.location,
				shipping_available: itemForm.shipping_available,
				shipping_cost: parseFloat(itemForm.shipping_cost),
				pickup_available: itemForm.pickup_available,
				tags: itemForm.tags.split(',').map(tag => tag.trim()).filter(tag => tag),
				status: 'active',
        currency: 'МР',
        payout_card_id: payoutCardId,
        images: itemForm.images
			}
			
      const { data, error } = await marketplaceService.createItem(itemData)
			
			if (error) {
				errorMessage = 'Ошибка создания объявления: ' + error.message
				return
			}
			
      successMessage = 'Объявление успешно создано!'
			
			// Redirect to item page after 2 seconds
			setTimeout(() => {
				goto(`/marketplace/item/${data[0].id}`)
			}, 2000)
			
		} catch (error: any) {
			errorMessage = error.message || 'Произошла ошибка при создании объявления'
		} finally {
			isSubmitting = false
		}
	}
	
	function validateForm() {
		if (!itemForm.title.trim()) {
			errorMessage = 'Укажите название товара'
			return false
		}
		if (!itemForm.description.trim()) {
			errorMessage = 'Добавьте описание товара'
			return false
		}
		if (!itemForm.price || parseFloat(itemForm.price) <= 0) {
			errorMessage = 'Укажите корректную цену'
			return false
		}
		if (!itemForm.category_id) {
			errorMessage = 'Выберите категорию'
			return false
		}
    if (!payoutCardId) {
      errorMessage = 'Выберите карту для выплат'
      return false
    }
		return true
	}

  async function onFilesSelected(event: Event) {
    const input = event.target as HTMLInputElement
    if (!input.files || input.files.length === 0) return
    const files = Array.from(input.files)
    uploading = true
    try {
      // Ensure authenticated session exists before uploading
      const { data: sessionData, error: sessionError } = await supabase.auth.getSession()
      if (sessionError || !sessionData.session) {
        errorMessage = 'Нужно войти в систему для загрузки изображений'
        return
      }
      for (const file of files) {
        const { url, error } = await marketplaceService.uploadItemImage(file as File, user.id)
        if (!error && url) {
          itemForm.images = [...itemForm.images, url]
        } else if (error) {
          console.error('Upload error', error)
          errorMessage = `Ошибка загрузки: ${error.message || 'Bad Request'}`
        }
      }
    } catch (e) {
      console.error('Upload error', e)
      errorMessage = 'Ошибка загрузки изображений'
    } finally {
      uploading = false
    }
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
</script>

<svelte:head>
	<title>Продать товар - Магазин Маннру</title>
</svelte:head>

<div class="min-h-screen bg-gray-50 overflow-x-hidden">
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
				<h1 class="text-lg font-medium text-gray-900">Продать товар</h1>
			</div>
		</div>
	</nav>

	<div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-8 max-w-full">
		<div class="bg-white rounded-lg shadow-sm p-6">
			<h2 class="text-2xl font-light text-gray-900 mb-6">Создать объявление</h2>
			
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
			
			<form on:submit|preventDefault={handleSubmit} class="space-y-6 max-w-full">
				<!-- Title -->
				<div class="form-control">
					<label class="label" for="title">
						<span class="label-text font-medium">Название товара *</span>
					</label>
					<input 
						id="title"
						type="text" 
						bind:value={itemForm.title}
						placeholder="Например: iPhone 15 Pro Max 256GB"
						class="input input-bordered"
						required
					/>
				</div>
				
				<!-- Description -->
				<div class="form-control">
					<label class="label" for="description">
						<span class="label-text font-medium">Описание *</span>
					</label>
					<textarea 
						id="description"
						bind:value={itemForm.description}
						placeholder="Подробное описание товара, его состояния, особенностей..."
						class="textarea textarea-bordered h-32 max-w-full"
						required
					></textarea>
				</div>
				
				<!-- Price and Category Row -->
				<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
					<div class="form-control">
						<label class="label" for="price">
							<span class="label-text font-medium">Цена (МР) *</span>
						</label>
						<input 
							id="price"
							type="number" 
							step="0.01"
							bind:value={itemForm.price}
							placeholder="0.00"
							class="input input-bordered"
							required
						/>
					</div>
					
					<div class="form-control">
						<label class="label" for="category">
							<span class="label-text font-medium">Категория *</span>
						</label>
						<select 
							id="category"
							bind:value={itemForm.category_id}
							class="select select-bordered"
							required
						>
							<option value="">Выберите категорию</option>
							{#each categories as category}
								<option value={category.id}>{category.name}</option>
							{/each}
						</select>
					</div>
				</div>
				
				<!-- Condition and Location Row -->
				<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
					<div class="form-control">
						<label class="label" for="condition">
							<span class="label-text font-medium">Состояние</span>
						</label>
						<select 
							id="condition"
							bind:value={itemForm.condition}
							class="select select-bordered"
						>
							<option value="new">Новое</option>
							<option value="like_new">Как новое</option>
							<option value="good">Хорошее</option>
							<option value="fair">Удовлетворительное</option>
							<option value="poor">Плохое</option>
						</select>
					</div>
					
					<div class="form-control">
						<label class="label" for="location">
							<span class="label-text font-medium">Местоположение</span>
						</label>
						<input 
							id="location"
							type="text" 
							bind:value={itemForm.location}
							placeholder="Город, район"
							class="input input-bordered"
						/>
					</div>
				</div>
				
				<!-- Tags -->
				<div class="form-control">
					<label class="label" for="tags">
						<span class="label-text font-medium">Теги</span>
					</label>
					<input 
						id="tags"
						type="text" 
						bind:value={itemForm.tags}
						placeholder="телефон, apple, смартфон (через запятую)"
						class="input input-bordered"
					/>
					<label class="label">
						<span class="label-text-alt text-gray-500">Добавьте ключевые слова через запятую для лучшего поиска</span>
					</label>
				</div>
				
        <!-- Images Upload -->
        <div class="form-control">
          <label class="label" for="images">
            <span class="label-text font-medium">Фотографии товара</span>
          </label>
          <input id="images" type="file" accept="image/*" multiple class="file-input file-input-bordered w-full max-w-full" on:change={onFilesSelected} />
          <label class="label">
            <span class="label-text-alt text-gray-500">Можно загрузить несколько изображений</span>
          </label>
          {#if uploading}
            <div class="text-sm text-gray-500">Загрузка изображений...</div>
          {/if}
          {#if itemForm.images.length > 0}
            <div class="grid grid-cols-3 sm:grid-cols-4 gap-2 mt-3">
              {#each itemForm.images as url}
                <div class="aspect-square bg-gray-100 rounded overflow-hidden">
                  <img src={url} alt="Фото" class="w-full h-full object-cover" />
                </div>
              {/each}
            </div>
          {/if}
        </div>

        <!-- Payout card selection -->
        <div class="form-control">
          <label class="label" for="payout-card">
            <span class="label-text font-medium">Куда зачислять оплату (карта)</span>
          </label>
          <select id="payout-card" class="select select-bordered" bind:value={payoutCardId} required>
            <option value="">Выберите карту</option>
            {#each userCards as card}
              <option value={card.id}>{card.card_name} (**** {card.card_number?.slice(-4)})</option>
            {/each}
          </select>
        </div>

				<!-- Shipping Options -->
				<div class="card bg-gray-50 p-4">
					<h3 class="font-medium text-gray-900 mb-4">Варианты получения</h3>
					
					<div class="space-y-4">
						<!-- Pickup -->
						<div class="form-control">
							<label class="cursor-pointer label justify-start">
								<input 
									type="checkbox" 
									bind:checked={itemForm.pickup_available}
									class="checkbox checkbox-primary mr-3"
								/>
								<span class="label-text">Самовывоз</span>
							</label>
						</div>
						
						<!-- Shipping -->
						<div class="form-control">
							<label class="cursor-pointer label justify-start">
								<input 
									type="checkbox" 
									bind:checked={itemForm.shipping_available}
									class="checkbox checkbox-primary mr-3"
								/>
								<span class="label-text">Доставка</span>
							</label>
						</div>
						
						{#if itemForm.shipping_available}
							<div class="form-control ml-8">
								<label class="label" for="shipping-cost">
									<span class="label-text">Стоимость доставки (МР)</span>
								</label>
								<input 
									id="shipping-cost"
									type="number" 
									step="0.01"
									bind:value={itemForm.shipping_cost}
									placeholder="0.00"
									class="input input-bordered input-sm max-w-xs"
								/>
							</div>
						{/if}
					</div>
				</div>
				
				<!-- Submit Buttons -->
				<div class="flex justify-end space-x-4 pt-6 border-t">
					<a href="/marketplace" class="btn btn-ghost">
						Отмена
					</a>
					<button 
						type="submit" 
						class="btn btn-primary"
						disabled={isSubmitting}
					>
						{#if isSubmitting}
							<Icon icon="mdi:loading" class="w-4 h-4 animate-spin mr-2" />
							Создание...
						{:else}
							<Icon icon="mdi:plus" class="w-4 h-4 mr-2" />
							Создать объявление
						{/if}
					</button>
				</div>
			</form>
		</div>
	</div>
</div>
