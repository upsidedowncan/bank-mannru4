<script lang="ts">
	import Icon from '@iconify/svelte'
	import { goto } from '$app/navigation'
	import { page } from '$app/stores'
	import { supabase, adminService } from '$lib/supabase'
	import { onMount } from 'svelte'
	
	let loginForm = {
		email: '',
		password: '',
		remember: false
	}
	
	let isLoading = false
	let errorMessage = ''
	let successMessage = ''
	let showPassword = false
	
	onMount(() => {
		const message = $page.url.searchParams.get('message')
		if (message === 'registration_success') {
			successMessage = 'Регистрация успешна! Теперь войдите в свой аккаунт.'
		}
	})
	
	async function handleLogin() {
		if (!loginForm.email || !loginForm.password) {
			errorMessage = 'Пожалуйста, заполните все поля'
			return
		}
		
		isLoading = true
		errorMessage = ''
		
		try {
			const { data, error } = await supabase.auth.signInWithPassword({
				email: loginForm.email,
				password: loginForm.password,
			})
			
			if (error) {
				if (error.message.includes('Invalid login credentials')) {
					errorMessage = 'Неверный email или пароль'
				} else if (error.message.includes('Email not confirmed')) {
					errorMessage = 'Подтвердите email адрес'
				} else {
					errorMessage = 'Ошибка входа: ' + error.message
				}
				return
			}
			
			if (data.user) {
				// Check if invite-only mode is enabled and user approval status
				const { isInviteOnly } = await adminService.isInviteOnlyMode()
				
				if (isInviteOnly) {
					const { data: approvalData } = await adminService.getUserApprovalStatus(data.user.id)
					
					if (approvalData?.status === 'pending') {
						goto('/pending-approval')
						return
					} else if (approvalData?.status === 'rejected') {
						errorMessage = 'Ваша заявка была отклонена. Обратитесь к администратору.'
						await supabase.auth.signOut()
						return
					}
				}
				
				// Check if user is admin
				const { isAdmin } = await adminService.isAdmin(data.user.id)
				
				// Successfully logged in - redirect appropriately
				if (isAdmin) {
					goto('/admin')
				} else {
					goto('/dashboard')
				}
			}
		} catch (error) {
			errorMessage = 'Произошла ошибка при входе. Попробуйте позже.'
		} finally {
			isLoading = false
		}
	}
	
	function togglePasswordVisibility() {
		showPassword = !showPassword
	}
</script>

<svelte:head>
	<title>Вход в систему - Банк Маннру</title>
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-primary via-blue-600 to-indigo-700 flex overflow-x-hidden">
	<!-- Left Side - Branding -->
	<div class="hidden lg:flex lg:w-1/2 flex-col justify-center items-center text-white p-12">
		<div class="max-w-md text-center">
			<h1 class="text-5xl font-light mb-6 tracking-tight">Маннру</h1>
			<p class="text-xl font-light mb-8 opacity-90">
				Современный банкинг для современной жизни
			</p>
			<div class="space-y-4 text-left">
				<div class="flex items-center space-x-3">
					<Icon icon="mdi:shield-check" class="w-6 h-6 text-accent" />
					<span class="font-light">Надежная защита данных</span>
				</div>
				<div class="flex items-center space-x-3">
					<Icon icon="mdi:lightning-bolt" class="w-6 h-6 text-accent" />
					<span class="font-light">Мгновенные переводы</span>
				</div>
				<div class="flex items-center space-x-3">
					<Icon icon="mdi:cellphone" class="w-6 h-6 text-accent" />
					<span class="font-light">Мобильное приложение</span>
				</div>
			</div>
		</div>
	</div>
	
	<!-- Right Side - Login Form -->
	<div class="w-full lg:w-1/2 bg-white flex flex-col justify-center p-8 lg:p-12 overflow-x-hidden">
		<!-- Mobile Logo -->
		<div class="lg:hidden text-center mb-8">
			<h1 class="text-3xl font-light text-primary mb-2 tracking-tight">Маннру</h1>
			<p class="text-gray-600 font-light">Интернет-банкинг</p>
		</div>
		
		<div class="max-w-md mx-auto w-full max-w-full">
			<div class="mb-8">
				<h2 class="text-3xl font-light text-gray-900 mb-2 tracking-tight">Добро пожаловать</h2>
				<p class="text-gray-600 font-light">Войдите в свой аккаунт</p>
			</div>
			
			<form on:submit|preventDefault={handleLogin} class="space-y-6">
				<!-- Email Field -->
				<div class="form-control">
					<label class="label" for="email">
						<span class="label-text font-medium text-gray-700">Email</span>
					</label>
					<div class="relative">
						<input 
							type="email" 
							id="email"
							bind:value={loginForm.email}
							placeholder="your@email.com"
							class="input input-bordered w-full pl-12 bg-gray-50 border-gray-200 focus:bg-white focus:border-primary transition-colors text-base"
							required
						/>
						<Icon icon="mdi:email" class="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
					</div>
				</div>
				
				<!-- Password Field -->
				<div class="form-control">
					<label class="label" for="password">
						<span class="label-text font-medium text-gray-700">Пароль</span>
					</label>
					<div class="relative">
						<input 
							type={showPassword ? 'text' : 'password'}
							id="password"
							bind:value={loginForm.password}
							placeholder="Введите пароль"
							class="input input-bordered w-full pl-12 pr-12 bg-gray-50 border-gray-200 focus:bg-white focus:border-primary transition-colors text-base"
							required
						/>
						<Icon icon="mdi:lock" class="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
						<button 
							type="button"
							on:click={togglePasswordVisibility}
							class="absolute right-4 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
						>
							<Icon icon={showPassword ? 'mdi:eye-off' : 'mdi:eye'} class="w-5 h-5" />
						</button>
					</div>
				</div>
				
				<!-- Remember Me and Forgot Password -->
				<div class="flex items-center justify-between">
					<label class="label cursor-pointer flex items-center space-x-2">
						<input 
							type="checkbox" 
							bind:checked={loginForm.remember}
							class="checkbox checkbox-primary checkbox-sm" 
						/>
						<span class="label-text text-sm text-gray-600 font-light">Запомнить меня</span>
					</label>
					<a href="/forgot-password" class="text-sm text-primary hover:text-primary-focus font-medium transition-colors">
						Забыли пароль?
					</a>
				</div>
				
				<!-- Success Message -->
				{#if successMessage}
					<div class="bg-green-50 border border-green-200 rounded-lg p-4">
						<div class="flex items-center space-x-2">
							<Icon icon="mdi:check-circle" class="w-5 h-5 text-green-600" />
							<span class="text-sm text-green-700">{successMessage}</span>
						</div>
					</div>
				{/if}
				
				<!-- Error Message -->
				{#if errorMessage}
					<div class="bg-red-50 border border-red-200 rounded-lg p-4">
						<div class="flex items-center space-x-2">
							<Icon icon="mdi:alert-circle" class="w-5 h-5 text-red-600" />
							<span class="text-sm text-red-700">{errorMessage}</span>
						</div>
					</div>
				{/if}
				
				<!-- Login Button -->
				<button 
					type="submit" 
					class="btn btn-primary w-full h-12 text-base"
					disabled={isLoading}
				>
					{#if isLoading}
						<Icon icon="mdi:loading" class="w-5 h-5 animate-spin" />
						Вход в систему...
					{:else}
						<Icon icon="mdi:login" class="w-5 h-5" />
						Войти в систему
					{/if}
				</button>
			</form>
			
			<!-- Register Link -->
			<div class="mt-8 pt-6 border-t border-gray-100 text-center">
				<p class="text-sm text-gray-600 font-light mb-4">Нет аккаунта?</p>
				<a href="/register" class="btn btn-outline w-full h-12 text-base">
					<Icon icon="mdi:account-plus" class="w-5 h-5" />
					Открыть банковский счет
				</a>
			</div>
			
			<!-- Footer Links -->
			<div class="mt-8 text-center space-y-2">
				<div class="flex justify-center space-x-6 text-sm">
					<a href="/support" class="text-gray-500 hover:text-gray-700 font-light transition-colors">Поддержка</a>
					<a href="/mobile-app" class="text-gray-500 hover:text-gray-700 font-light transition-colors">Приложение</a>
				</div>
				<p class="text-xs text-gray-400 font-light">© 2024 Банк Маннру</p>
			</div>
		</div>
	</div>
</div>
