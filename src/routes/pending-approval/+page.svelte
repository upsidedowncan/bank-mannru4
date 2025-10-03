<script lang="ts">
	import Icon from '@iconify/svelte'
	import { onMount } from 'svelte'
	import { goto } from '$app/navigation'
	import { supabase, adminService } from '$lib/supabase'
	
	let user: any = null
	let approvalStatus: any = null
	let isLoading = true
	let checkingStatus = false
	
	onMount(async () => {
		await checkAuth()
		if (user) {
			await checkApprovalStatus()
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
	
	async function checkApprovalStatus() {
		checkingStatus = true
		try {
			const { data, error } = await adminService.getUserApprovalStatus(user.id)
			
			if (error && error.code !== 'PGRST116') {
				console.error('Error checking approval status:', error)
				return
			}
			
			approvalStatus = data
			
			// If approved, redirect to dashboard
			if (data?.status === 'approved') {
				goto('/dashboard')
			}
		} catch (error) {
			console.error('Error checking approval status:', error)
		} finally {
			checkingStatus = false
		}
	}
	
	async function signOut() {
		await supabase.auth.signOut()
		goto('/')
	}
	
	function getStatusColor(status: string) {
		switch (status) {
			case 'pending': return 'text-yellow-600 bg-yellow-100'
			case 'approved': return 'text-green-600 bg-green-100'
			case 'rejected': return 'text-red-600 bg-red-100'
			default: return 'text-gray-600 bg-gray-100'
		}
	}
	
	function getStatusText(status: string) {
		switch (status) {
			case 'pending': return 'Ожидает рассмотрения'
			case 'approved': return 'Одобрено'
			case 'rejected': return 'Отклонено'
			default: return 'Неизвестно'
		}
	}
</script>

<svelte:head>
	<title>Ожидание одобрения - Банк Маннру</title>
</svelte:head>

<div class="min-h-screen bg-gray-50">
	<!-- Header -->
	<nav class="bg-white shadow-sm border-b">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between h-16">
				<div class="flex items-center">
					<Icon icon="mdi:bank" class="w-8 h-8 text-primary mr-3" />
					<h1 class="text-2xl font-light text-primary tracking-tight">Маннру</h1>
				</div>
				<div class="flex items-center">
					<button on:click={signOut} class="btn btn-ghost btn-sm">
						<Icon icon="mdi:logout" class="w-4 h-4 mr-1" />
						Выйти
					</button>
				</div>
			</div>
		</div>
	</nav>

	<div class="max-w-2xl mx-auto px-4 py-12">
		{#if isLoading}
			<div class="text-center">
				<Icon icon="mdi:loading" class="w-12 h-12 animate-spin text-primary mx-auto mb-4" />
				<p class="text-gray-600">Загрузка...</p>
			</div>
		{:else}
			<div class="bg-white rounded-lg shadow-sm p-8">
				<div class="text-center mb-8">
					<div class="w-16 h-16 bg-yellow-100 rounded-full flex items-center justify-center mx-auto mb-4">
						<Icon icon="mdi:clock-outline" class="w-8 h-8 text-yellow-600" />
					</div>
					<h1 class="text-2xl font-light text-gray-900 mb-2">Ваша заявка на рассмотрении</h1>
					<p class="text-gray-600">
						Спасибо за регистрацию в банке Маннру! Ваша заявка отправлена на рассмотрение администратору.
					</p>
				</div>

				{#if approvalStatus}
					<div class="bg-gray-50 rounded-lg p-6 mb-6">
						<div class="flex items-center justify-between mb-4">
							<span class="font-medium text-gray-700">Статус заявки:</span>
							<span class="px-3 py-1 rounded-full text-sm font-medium {getStatusColor(approvalStatus.status)}">
								{getStatusText(approvalStatus.status)}
							</span>
						</div>
						
						<div class="space-y-3 text-sm text-gray-600">
							<div class="flex justify-between">
								<span>Email:</span>
								<span class="font-medium">{user?.email}</span>
							</div>
							<div class="flex justify-between">
								<span>Имя:</span>
								<span class="font-medium">{user?.user_metadata?.full_name}</span>
							</div>
							<div class="flex justify-between">
								<span>Дата подачи:</span>
								<span class="font-medium">
									{new Date(approvalStatus.created_at).toLocaleDateString('ru-RU')}
								</span>
							</div>
						</div>

						{#if approvalStatus.status === 'rejected' && approvalStatus.rejection_reason}
							<div class="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg">
								<p class="text-sm text-red-700">
									<strong>Причина отклонения:</strong> {approvalStatus.rejection_reason}
								</p>
							</div>
						{/if}
					</div>
				{/if}

				<div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
					<div class="flex">
						<Icon icon="mdi:information" class="w-5 h-5 text-blue-600 mt-0.5 mr-3 flex-shrink-0" />
						<div class="text-sm text-blue-700">
							<p class="font-medium mb-1">Что происходит дальше?</p>
							<ul class="space-y-1 list-disc list-inside">
								<li>Администратор рассмотрит вашу заявку в течение 1-2 рабочих дней</li>
								<li>Вы получите уведомление на email о статусе заявки</li>
								<li>После одобрения вы сможете войти в систему и пользоваться услугами банка</li>
							</ul>
						</div>
					</div>
				</div>

				<div class="flex justify-center space-x-4">
					<button 
						on:click={checkApprovalStatus}
						class="btn btn-primary"
						disabled={checkingStatus}
					>
						{#if checkingStatus}
							<Icon icon="mdi:loading" class="w-4 h-4 animate-spin mr-2" />
							Проверка...
						{:else}
							<Icon icon="mdi:refresh" class="w-4 h-4 mr-2" />
							Обновить статус
						{/if}
					</button>
					
					<button on:click={signOut} class="btn btn-ghost">
						<Icon icon="mdi:logout" class="w-4 h-4 mr-2" />
						Выйти из системы
					</button>
				</div>
			</div>
		{/if}
	</div>
</div>
