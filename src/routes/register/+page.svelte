<script lang="ts">
	import Icon from '@iconify/svelte'
	import { goto } from '$app/navigation'
	import { supabase, adminService, bankService } from '$lib/supabase'
	
	let registerForm = {
		firstName: '',
		lastName: '',
		phone: '',
		email: '',
		password: '',
		confirmPassword: '',
		agreeToTerms: false
	}
	
	let isLoading = false
	let errorMessage = ''
	let showPassword = false
	let showConfirmPassword = false
	
	async function handleRegister() {
		if (!registerForm.firstName || !registerForm.lastName || !registerForm.phone || 
			!registerForm.email || !registerForm.password || !registerForm.confirmPassword) {
			errorMessage = 'Пожалуйста, заполните все поля'
			return
		}
		
		if (registerForm.password !== registerForm.confirmPassword) {
			errorMessage = 'Пароли не совпадают'
			return
		}
		
		if (registerForm.password.length < 6) {
			errorMessage = 'Пароль должен содержать минимум 6 символов'
			return
		}
		
		if (!registerForm.agreeToTerms) {
			errorMessage = 'Необходимо согласиться с условиями обслуживания'
			return
		}
		
		isLoading = true
		errorMessage = ''
		
		try {
			// Check if invite-only mode is enabled
			const { isInviteOnly } = await adminService.isInviteOnlyMode()
			
			// Register user with Supabase Auth
			const { data, error } = await supabase.auth.signUp({
				email: registerForm.email,
				password: registerForm.password,
				options: {
					data: {
						first_name: registerForm.firstName,
						last_name: registerForm.lastName,
						phone: registerForm.phone,
						full_name: `${registerForm.firstName} ${registerForm.lastName}`
					}
				}
			})
			
			if (error) {
				if (error.message.includes('User already registered')) {
					errorMessage = 'Пользователь с таким email уже существует'
				} else if (error.message.includes('Password should be at least')) {
					errorMessage = 'Пароль слишком короткий'
				} else {
					errorMessage = 'Ошибка регистрации: ' + error.message
				}
				return
			}
			
			if (data.user) {
				// Create user profile
				try {
					await bankService.createUserProfile({
						user_id: data.user.id,
						email: registerForm.email,
						first_name: registerForm.firstName,
						last_name: registerForm.lastName,
						phone: registerForm.phone
					})
				} catch (profileError) {
					console.error('Error creating user profile:', profileError)
					// Continue with registration even if profile creation fails
				}
				
				// If invite-only mode is enabled, create approval request
				if (isInviteOnly) {
					await adminService.createApprovalRequest({
						user_id: data.user.id,
						email: registerForm.email,
						first_name: registerForm.firstName,
						last_name: registerForm.lastName,
						phone: registerForm.phone
					})
					
					// Redirect to pending approval page
					goto('/pending-approval')
				} else {
					// Normal registration flow
					goto('/login?message=registration_success')
				}
			}
		} catch (error) {
			errorMessage = 'Произошла ошибка при регистрации. Попробуйте позже.'
		} finally {
			isLoading = false
		}
	}
</script>

<svelte:head>
	<title>Регистрация - Банк Маннру</title>
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-primary via-blue-600 to-indigo-700 flex overflow-x-hidden">
	<!-- Left Side - Branding -->
	<div class="hidden lg:flex lg:w-1/2 flex-col justify-center items-center text-white p-12">
		<div class="max-w-md text-center">
			<h1 class="text-5xl font-light mb-6 tracking-tight">Маннру</h1>
			<p class="text-xl font-light mb-8 opacity-90">
				Присоединяйтесь к миллионам довольных клиентов
			</p>
			<div class="space-y-4 text-left">
				<div class="flex items-center space-x-3">
					<Icon icon="mdi:account-check" class="w-6 h-6 text-accent" />
					<span class="font-light">Быстрая регистрация</span>
				</div>
				<div class="flex items-center space-x-3">
					<Icon icon="mdi:credit-card" class="w-6 h-6 text-accent" />
					<span class="font-light">Бесплатная карта</span>
				</div>
				<div class="flex items-center space-x-3">
					<Icon icon="mdi:percent" class="w-6 h-6 text-accent" />
					<span class="font-light">Выгодные условия</span>
				</div>
			</div>
		</div>
	</div>
	
	<!-- Right Side - Registration Form -->
	<div class="w-full lg:w-1/2 bg-white flex flex-col justify-center p-8 lg:p-12 overflow-y-auto overflow-x-hidden">
		<!-- Mobile Logo -->
		<div class="lg:hidden text-center mb-8">
			<h1 class="text-3xl font-light text-primary mb-2 tracking-tight">Маннру</h1>
			<p class="text-gray-600 font-light">Регистрация</p>
		</div>
		
		<div class="max-w-md mx-auto w-full max-w-full">
			<div class="mb-8">
				<h2 class="text-3xl font-light text-gray-900 mb-2 tracking-tight">Создать аккаунт</h2>
				<p class="text-gray-600 font-light">Откройте банковский счет за несколько минут</p>
			</div>
			
			<form on:submit|preventDefault={handleRegister} class="space-y-5">
				<!-- Name Fields -->
				<div class="grid grid-cols-2 gap-4">
					<div class="form-control">
						<label class="label" for="firstName">
							<span class="label-text font-medium text-gray-700">Имя</span>
						</label>
						<input 
							type="text" 
							id="firstName"
							bind:value={registerForm.firstName}
							placeholder="Имя"
							class="input input-bordered bg-gray-50 border-gray-200 focus:bg-white focus:border-primary transition-colors text-base"
							required
						/>
					</div>
					
					<div class="form-control">
						<label class="label" for="lastName">
							<span class="label-text font-medium text-gray-700">Фамилия</span>
						</label>
						<input 
							type="text" 
							id="lastName"
							bind:value={registerForm.lastName}
							placeholder="Фамилия"
							class="input input-bordered bg-gray-50 border-gray-200 focus:bg-white focus:border-primary transition-colors text-base"
							required
						/>
					</div>
				</div>
				
				<!-- Phone Field -->
				<div class="form-control">
					<label class="label" for="phone">
						<span class="label-text font-medium text-gray-700">Номер телефона</span>
					</label>
					<div class="relative">
						<input 
							type="tel" 
							id="phone"
							bind:value={registerForm.phone}
							placeholder="+7 (900) 123-45-67"
							class="input input-bordered w-full pl-12 bg-gray-50 border-gray-200 focus:bg-white focus:border-primary transition-colors text-base"
							required
						/>
						<Icon icon="mdi:phone" class="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
					</div>
				</div>
				
				<!-- Email Field -->
				<div class="form-control">
					<label class="label" for="email">
						<span class="label-text font-medium text-gray-700">Email</span>
					</label>
					<div class="relative">
						<input 
							type="email" 
							id="email"
							bind:value={registerForm.email}
							placeholder="your@email.com"
							class="input input-bordered w-full pl-12 bg-gray-50 border-gray-200 focus:bg-white focus:border-primary transition-colors text-base"
							required
						/>
						<Icon icon="mdi:email" class="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
					</div>
				</div>
				
				<!-- Password Fields -->
				<div class="space-y-4">
					<div class="form-control">
						<label class="label" for="password">
							<span class="label-text font-medium text-gray-700">Пароль</span>
						</label>
						<div class="relative">
							<input 
								type={showPassword ? 'text' : 'password'}
								id="password"
								bind:value={registerForm.password}
								placeholder="Минимум 6 символов"
								class="input input-bordered w-full pl-12 pr-12 bg-gray-50 border-gray-200 focus:bg-white focus:border-primary transition-colors text-base"
								required
							/>
							<Icon icon="mdi:lock" class="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
							<button 
								type="button"
								on:click={() => showPassword = !showPassword}
								class="absolute right-4 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
							>
								<Icon icon={showPassword ? 'mdi:eye-off' : 'mdi:eye'} class="w-5 h-5" />
							</button>
						</div>
					</div>
					
					<div class="form-control">
						<label class="label" for="confirmPassword">
							<span class="label-text font-medium text-gray-700">Подтвердите пароль</span>
						</label>
						<div class="relative">
							<input 
								type={showConfirmPassword ? 'text' : 'password'}
								id="confirmPassword"
								bind:value={registerForm.confirmPassword}
								placeholder="Повторите пароль"
								class="input input-bordered w-full pl-12 pr-12 bg-gray-50 border-gray-200 focus:bg-white focus:border-primary transition-colors text-base"
								required
							/>
							<Icon icon="mdi:lock-check" class="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
							<button 
								type="button"
								on:click={() => showConfirmPassword = !showConfirmPassword}
								class="absolute right-4 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
							>
								<Icon icon={showConfirmPassword ? 'mdi:eye-off' : 'mdi:eye'} class="w-5 h-5" />
							</button>
						</div>
					</div>
				</div>
				
				<!-- Terms Agreement -->
				<div class="form-control">
					<label class="label cursor-pointer justify-start space-x-3">
						<input 
							type="checkbox" 
							bind:checked={registerForm.agreeToTerms}
							class="checkbox checkbox-primary checkbox-sm" 
							required
						/>
						<span class="label-text text-sm text-gray-600 leading-relaxed font-light">
							Я согласен с <a href="/terms" class="text-primary hover:text-primary-focus font-medium">условиями обслуживания</a> 
							и <a href="/privacy" class="text-primary hover:text-primary-focus font-medium">политикой конфиденциальности</a>
						</span>
					</label>
				</div>
				
				<!-- Error Message -->
				{#if errorMessage}
					<div class="bg-red-50 border border-red-200 rounded-lg p-4">
						<div class="flex items-center space-x-2">
							<Icon icon="mdi:alert-circle" class="w-5 h-5 text-red-600" />
							<span class="text-sm text-red-700">{errorMessage}</span>
						</div>
					</div>
				{/if}
				
				<!-- Register Button -->
				<button 
					type="submit" 
					class="btn btn-primary w-full h-12 text-base"
					disabled={isLoading}
				>
					{#if isLoading}
						<Icon icon="mdi:loading" class="w-5 h-5 animate-spin" />
						Создание аккаунта...
					{:else}
						<Icon icon="mdi:account-plus" class="w-5 h-5" />
						Создать аккаунт
					{/if}
				</button>
			</form>
			
			<!-- Login Link -->
			<div class="mt-8 pt-6 border-t border-gray-100 text-center">
				<p class="text-sm text-gray-600 font-light mb-4">Уже есть аккаунт?</p>
				<a href="/login" class="btn btn-outline w-full h-12 text-base">
					<Icon icon="mdi:login" class="w-5 h-5" />
					Войти в систему
				</a>
			</div>
			
			<!-- Footer -->
			<div class="mt-8 text-center">
				<p class="text-xs text-gray-400 font-light">© 2024 Банк Маннру</p>
			</div>
		</div>
	</div>
</div>
