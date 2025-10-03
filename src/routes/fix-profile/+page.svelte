<script lang="ts">
	import { onMount } from 'svelte'
	import { supabase, bankService } from '$lib/supabase'
	
	let user: any = null
	let profileExists = false
	let isLoading = true
	let isCreating = false
	let message = ''
	
	onMount(async () => {
		await checkUserProfile()
		isLoading = false
	})
	
	async function checkUserProfile() {
		const { data: { user: currentUser } } = await supabase.auth.getUser()
		user = currentUser
		
		if (user) {
			const profile = await bankService.getUserProfile(user.id)
			profileExists = !!profile
		}
	}
	
	async function createProfile() {
		if (!user) return
		
		isCreating = true
		try {
			await bankService.createUserProfile({
				user_id: user.id,
				email: user.email,
				first_name: user.user_metadata?.first_name || 'Ахмед',
				last_name: user.user_metadata?.last_name || 'Шайхилов',
				phone: user.user_metadata?.phone || '+7 (926) 891-16-29'
			})
			
			message = 'Profile created successfully!'
			profileExists = true
		} catch (error) {
			message = 'Error creating profile: ' + error
		} finally {
			isCreating = false
		}
	}
</script>

<div class="p-8">
	<h1 class="text-2xl font-bold mb-6">Fix User Profile</h1>
	
	{#if isLoading}
		<p>Loading...</p>
	{:else if user}
		<div class="space-y-4">
			<div class="bg-white p-4 rounded border">
				<h2 class="font-bold mb-2">Current User</h2>
				<p><strong>ID:</strong> {user.id}</p>
				<p><strong>Email:</strong> {user.email}</p>
				<p><strong>First Name:</strong> {user.user_metadata?.first_name || 'N/A'}</p>
				<p><strong>Last Name:</strong> {user.user_metadata?.last_name || 'N/A'}</p>
				<p><strong>Phone:</strong> {user.user_metadata?.phone || 'N/A'}</p>
			</div>
			
			<div class="bg-white p-4 rounded border">
				<h2 class="font-bold mb-2">Profile Status</h2>
				<p class="mb-4">
					<strong>Profile Exists:</strong> 
					<span class="px-2 py-1 rounded text-xs {profileExists ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}">
						{profileExists ? 'YES' : 'NO'}
					</span>
				</p>
				
				{#if !profileExists}
					<button 
						on:click={createProfile}
						class="btn btn-primary"
						disabled={isCreating}
					>
						{#if isCreating}
							Creating...
						{:else}
							Create Profile
						{/if}
					</button>
				{:else}
					<p class="text-green-600">✅ Profile exists! Admin panel should work now.</p>
					<a href="/admin" class="btn btn-primary mt-2">Go to Admin Panel</a>
				{/if}
				
				{#if message}
					<p class="mt-4 p-2 bg-blue-50 rounded">{message}</p>
				{/if}
			</div>
		</div>
	{:else}
		<p>No user logged in</p>
	{/if}
</div>
