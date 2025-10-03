<script lang="ts">
	import Icon from '@iconify/svelte'
	import { onMount } from 'svelte'
	import { supabase, adminService } from '$lib/supabase'
	
	let user: any = null
	let isInviteOnly = false
	let approvalStatus: any = null
	let isAdmin = false
	let adminRole = ''
	let settings: any[] = []
	let isLoading = true
	
	onMount(async () => {
		await loadDebugInfo()
		isLoading = false
	})
	
	async function loadDebugInfo() {
		// Get current user
		const { data: { user: currentUser } } = await supabase.auth.getUser()
		user = currentUser
		
		// Check invite-only mode
		const inviteOnlyResult = await adminService.isInviteOnlyMode()
		isInviteOnly = inviteOnlyResult.isInviteOnly
		
		// Check admin status
		if (user) {
			const adminResult = await adminService.isAdmin(user.id)
			isAdmin = adminResult.isAdmin
			adminRole = adminResult.role
			
			// Check approval status
			const approvalResult = await adminService.getUserApprovalStatus(user.id)
			approvalStatus = approvalResult.data
		}
		
		// Get all settings
		const settingsResult = await adminService.getSettings()
		settings = settingsResult.data || []
	}
	
	async function createTestApproval() {
		if (!user) return
		
		try {
			const result = await adminService.createApprovalRequest({
				user_id: user.id,
				email: user.email,
				first_name: user.user_metadata?.first_name || 'Test',
				last_name: user.user_metadata?.last_name || 'User',
				phone: user.user_metadata?.phone || ''
			})
			
			console.log('Test approval created:', result)
			await loadDebugInfo()
		} catch (error) {
			console.error('Error creating test approval:', error)
		}
	}
</script>

<svelte:head>
	<title>Debug Info - Банк Маннру</title>
</svelte:head>

<div class="min-h-screen bg-gray-50 p-8">
	<div class="max-w-4xl mx-auto">
		<h1 class="text-3xl font-light text-gray-900 mb-8">
			<Icon icon="mdi:bug" class="inline w-8 h-8 mr-3" />
			Debug Information
		</h1>
		
		{#if isLoading}
			<div class="text-center py-12">
				<Icon icon="mdi:loading" class="w-12 h-12 animate-spin text-primary mx-auto mb-4" />
				<p class="text-gray-600">Загрузка данных...</p>
			</div>
		{:else}
			<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
				<!-- Current User -->
				<div class="bg-white rounded-lg shadow-sm p-6">
					<h2 class="text-xl font-medium text-gray-900 mb-4">
						<Icon icon="mdi:account" class="inline w-5 h-5 mr-2" />
						Current User
					</h2>
					{#if user}
						<div class="space-y-2 text-sm">
							<div><strong>ID:</strong> {user.id}</div>
							<div><strong>Email:</strong> {user.email}</div>
							<div><strong>First Name:</strong> {user.user_metadata?.first_name || 'N/A'}</div>
							<div><strong>Last Name:</strong> {user.user_metadata?.last_name || 'N/A'}</div>
							<div><strong>Phone:</strong> {user.user_metadata?.phone || 'N/A'}</div>
							<div><strong>Created:</strong> {new Date(user.created_at).toLocaleString()}</div>
						</div>
					{:else}
						<p class="text-gray-500">No user logged in</p>
					{/if}
				</div>

				<!-- Admin Status -->
				<div class="bg-white rounded-lg shadow-sm p-6">
					<h2 class="text-xl font-medium text-gray-900 mb-4">
						<Icon icon="mdi:shield-crown" class="inline w-5 h-5 mr-2" />
						Admin Status
					</h2>
					<div class="space-y-2 text-sm">
						<div class="flex items-center">
							<strong>Is Admin:</strong>
							<span class="ml-2 px-2 py-1 rounded text-xs {isAdmin ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}">
								{isAdmin ? 'YES' : 'NO'}
							</span>
						</div>
						{#if isAdmin}
							<div><strong>Role:</strong> {adminRole}</div>
						{/if}
						{#if isAdmin}
							<div class="mt-4">
								<a href="/admin" class="btn btn-primary btn-sm">
									<Icon icon="mdi:shield-crown" class="w-4 h-4 mr-1" />
									Go to Admin Panel
								</a>
							</div>
						{/if}
					</div>
				</div>

				<!-- Invite-Only Status -->
				<div class="bg-white rounded-lg shadow-sm p-6">
					<h2 class="text-xl font-medium text-gray-900 mb-4">
						<Icon icon="mdi:account-lock" class="inline w-5 h-5 mr-2" />
						Invite-Only Mode
					</h2>
					<div class="space-y-2 text-sm">
						<div class="flex items-center">
							<strong>Invite-Only Mode:</strong>
							<span class="ml-2 px-2 py-1 rounded text-xs {isInviteOnly ? 'bg-yellow-100 text-yellow-800' : 'bg-green-100 text-green-800'}">
								{isInviteOnly ? 'ENABLED' : 'DISABLED'}
							</span>
						</div>
						{#if isInviteOnly}
							<p class="text-yellow-700 bg-yellow-50 p-2 rounded text-xs">
								New registrations require admin approval
							</p>
						{/if}
					</div>
				</div>

				<!-- Approval Status -->
				<div class="bg-white rounded-lg shadow-sm p-6">
					<h2 class="text-xl font-medium text-gray-900 mb-4">
						<Icon icon="mdi:account-clock" class="inline w-5 h-5 mr-2" />
						Approval Status
					</h2>
					{#if approvalStatus}
						<div class="space-y-2 text-sm">
							<div class="flex items-center">
								<strong>Status:</strong>
								<span class="ml-2 px-2 py-1 rounded text-xs {
									approvalStatus.status === 'approved' ? 'bg-green-100 text-green-800' :
									approvalStatus.status === 'rejected' ? 'bg-red-100 text-red-800' :
									'bg-yellow-100 text-yellow-800'
								}">
									{approvalStatus.status.toUpperCase()}
								</span>
							</div>
							{#if approvalStatus.rejection_reason}
								<div><strong>Rejection Reason:</strong> {approvalStatus.rejection_reason}</div>
							{/if}
						</div>
					{:else}
						<div class="space-y-2 text-sm">
							<p class="text-gray-500">No approval record found</p>
							{#if user && isInviteOnly}
								<button on:click={createTestApproval} class="btn btn-warning btn-sm">
									<Icon icon="mdi:plus" class="w-4 h-4 mr-1" />
									Create Test Approval
								</button>
							{/if}
						</div>
					{/if}
				</div>

				<!-- System Settings -->
				<div class="bg-white rounded-lg shadow-sm p-6 md:col-span-2">
					<h2 class="text-xl font-medium text-gray-900 mb-4">
						<Icon icon="mdi:cog" class="inline w-5 h-5 mr-2" />
						System Settings
					</h2>
					{#if settings.length > 0}
						<div class="overflow-x-auto">
							<table class="table table-zebra w-full">
								<thead>
									<tr>
										<th>Setting Key</th>
										<th>Value</th>
										<th>Description</th>
										<th>Updated</th>
									</tr>
								</thead>
								<tbody>
									{#each settings as setting}
										<tr>
											<td><code class="bg-gray-100 px-1 rounded text-xs">{setting.setting_key}</code></td>
											<td>
												<span class="px-2 py-1 rounded text-xs {setting.setting_value ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}">
													{setting.setting_value ? 'TRUE' : 'FALSE'}
												</span>
											</td>
											<td class="text-sm">{setting.description}</td>
											<td class="text-xs text-gray-500">
												{new Date(setting.updated_at).toLocaleString()}
											</td>
										</tr>
									{/each}
								</tbody>
							</table>
						</div>
					{:else}
						<p class="text-gray-500">No settings found</p>
					{/if}
				</div>

				<!-- Quick Actions -->
				<div class="bg-white rounded-lg shadow-sm p-6 md:col-span-2">
					<h2 class="text-xl font-medium text-gray-900 mb-4">
						<Icon icon="mdi:lightning-bolt" class="inline w-5 h-5 mr-2" />
						Quick Actions
					</h2>
					<div class="flex flex-wrap gap-3">
						<a href="/dashboard" class="btn btn-primary btn-sm">
							<Icon icon="mdi:view-dashboard" class="w-4 h-4 mr-1" />
							Dashboard
						</a>
						{#if isAdmin}
							<a href="/admin" class="btn btn-secondary btn-sm">
								<Icon icon="mdi:shield-crown" class="w-4 h-4 mr-1" />
								Admin Panel
							</a>
						{/if}
						<a href="/pending-approval" class="btn btn-warning btn-sm">
							<Icon icon="mdi:clock" class="w-4 h-4 mr-1" />
							Pending Approval
						</a>
						<a href="/login" class="btn btn-ghost btn-sm">
							<Icon icon="mdi:login" class="w-4 h-4 mr-1" />
							Login
						</a>
						<a href="/register" class="btn btn-ghost btn-sm">
							<Icon icon="mdi:account-plus" class="w-4 h-4 mr-1" />
							Register
						</a>
					</div>
				</div>
			</div>
		{/if}
	</div>
</div>
