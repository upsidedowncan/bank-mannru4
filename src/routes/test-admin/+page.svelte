<script lang="ts">
	import { onMount } from 'svelte'
	import { supabase, adminService } from '$lib/supabase'
	
	let results: any = {}
	let loading = true
	
	onMount(async () => {
		await runTests()
		loading = false
	})
	
	async function runTests() {
		const { data: { user } } = await supabase.auth.getUser()
		results.currentUser = user
		
		// Test 1: Direct Supabase query for admin_settings
		try {
			const { data, error } = await supabase
				.from('admin_settings')
				.select('*')
			results.directSettings = { data, error }
		} catch (err) {
			results.directSettings = { error: err }
		}
		
		// Test 2: Direct Supabase query for admin_users
		try {
			const { data, error } = await supabase
				.from('admin_users')
				.select('*')
				.eq('user_id', user?.id)
			results.directAdmin = { data, error }
		} catch (err) {
			results.directAdmin = { error: err }
		}
		
		// Test 3: AdminService calls
		try {
			results.adminServiceSettings = await adminService.getSettings()
		} catch (err) {
			results.adminServiceSettings = { error: err }
		}
		
		try {
			results.adminServiceIsAdmin = await adminService.isAdmin(user?.id || '')
		} catch (err) {
			results.adminServiceIsAdmin = { error: err }
		}
		
		try {
			results.adminServiceInviteOnly = await adminService.isInviteOnlyMode()
		} catch (err) {
			results.adminServiceInviteOnly = { error: err }
		}
	}
</script>

<div class="p-8">
	<h1 class="text-2xl font-bold mb-6">Admin API Test Results</h1>
	
	{#if loading}
		<p>Running tests...</p>
	{:else}
		<div class="space-y-6">
			<div class="bg-white p-4 rounded border">
				<h2 class="font-bold mb-2">Current User</h2>
				<pre class="text-xs overflow-auto">{JSON.stringify(results.currentUser, null, 2)}</pre>
			</div>
			
			<div class="bg-white p-4 rounded border">
				<h2 class="font-bold mb-2">Direct Settings Query</h2>
				<pre class="text-xs overflow-auto">{JSON.stringify(results.directSettings, null, 2)}</pre>
			</div>
			
			<div class="bg-white p-4 rounded border">
				<h2 class="font-bold mb-2">Direct Admin Query</h2>
				<pre class="text-xs overflow-auto">{JSON.stringify(results.directAdmin, null, 2)}</pre>
			</div>
			
			<div class="bg-white p-4 rounded border">
				<h2 class="font-bold mb-2">AdminService.getSettings()</h2>
				<pre class="text-xs overflow-auto">{JSON.stringify(results.adminServiceSettings, null, 2)}</pre>
			</div>
			
			<div class="bg-white p-4 rounded border">
				<h2 class="font-bold mb-2">AdminService.isAdmin()</h2>
				<pre class="text-xs overflow-auto">{JSON.stringify(results.adminServiceIsAdmin, null, 2)}</pre>
			</div>
			
			<div class="bg-white p-4 rounded border">
				<h2 class="font-bold mb-2">AdminService.isInviteOnlyMode()</h2>
				<pre class="text-xs overflow-auto">{JSON.stringify(results.adminServiceInviteOnly, null, 2)}</pre>
			</div>
		</div>
	{/if}
</div>
