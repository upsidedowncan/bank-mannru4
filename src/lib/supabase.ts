import { createClient } from '@supabase/supabase-js'
import { env } from '$env/dynamic/public'

// These should be set in your .env file
const supabaseUrl = env.PUBLIC_SUPABASE_URL || 'https://ubebsdujyyvhzbiisdmu.supabase.co'
const supabaseKey = env.PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InViZWJzZHVqeXl2aHpiaWlzZG11Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkzOTMyNjUsImV4cCI6MjA3NDk2OTI2NX0.8r7CG8SK-eLBXa5gf2ekjnmPVsjqwhjAbnbB_teoE58'

export const supabase = createClient(supabaseUrl, supabaseKey)

// Bank-specific database operations
export const bankService = {
  // Example: Get bank products/services
  async getProducts() {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (error) {
      console.error('Error fetching products:', error)
      return []
    }
    
    return data || []
  },

  // Submit contact form
  async submitContactForm(formData: {
    name: string
    email: string
    phone?: string
    message: string
  }) {
    const { data, error } = await supabase
      .from('contact_requests')
      .insert([formData])
      .select()
    
    if (error) {
      console.error('Error submitting contact form:', error)
      throw error
    }
    
    return data
  },

  // Subscribe to newsletter
  async subscribeNewsletter(email: string) {
    const { data, error } = await supabase
      .from('newsletter_subscribers')
      .insert([{ email, subscribed_at: new Date().toISOString() }])
      .select()
    
    if (error) {
      console.error('Error subscribing to newsletter:', error)
      throw error
    }
    
    return data
  },

  // Card Management
  async getUserCards(userId: string) {
    const { data, error } = await supabase
      .from('bank_cards')
      .select('*')
      .eq('user_id', userId)
      .eq('is_active', true)
      .order('created_at', { ascending: false })
    
    if (error) {
      console.error('Error fetching cards:', error)
      throw error
    }
    
    return data || []
  },

  async createCard(cardData: {
    user_id: string
    card_name: string
    card_type: 'debit' | 'credit' | 'savings'
    currency: string
  }) {
    // Generate card number (for demo purposes)
    const cardNumber = '4' + Math.random().toString().slice(2, 15).padStart(15, '0')
    const expiryDate = new Date()
    expiryDate.setFullYear(expiryDate.getFullYear() + 3)
    
    const { data, error } = await supabase
      .from('bank_cards')
      .insert([{
        ...cardData,
        card_number: cardNumber,
		balance: 0, // All cards start with 0 balance
		credit_limit: cardData.card_type === 'credit' ? 50000 : null,
        expiry_date: expiryDate.toISOString(),
        is_active: true
      }])
      .select()
    
    if (error) {
      console.error('Error creating card:', error)
      throw error
    }
    
    return data
  },

  async updateCardBalance(cardId: string, newBalance: number) {
    const { data, error } = await supabase
      .from('bank_cards')
      .update({ balance: newBalance })
      .eq('id', cardId)
      .select()
    
    if (error) {
      console.error('Error updating card balance:', error)
      throw error
    }
    
    return data
  },

  // Transaction Management
  async getUserTransactions(userId: string, limit = 10) {
    const { data, error } = await supabase
      .from('transactions')
      .select(`
        *,
        from_card:bank_cards!transactions_from_card_id_fkey(card_number, card_name),
        to_card:bank_cards!transactions_to_card_id_fkey(card_number, card_name)
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(limit)
    
    if (error) {
      console.error('Error fetching transactions:', error)
      throw error
    }
    
    return data || []
  },

  async createTransaction(transactionData: {
    user_id: string
    from_card_id?: string
    to_card_id?: string
    amount: number
    transaction_type: 'debit' | 'credit' | 'transfer'
    description?: string
    recipient_account?: string
  }) {
    const { data, error } = await supabase
      .from('transactions')
      .insert([{
        ...transactionData,
        status: 'completed'
      }])
      .select()
    
    if (error) {
      console.error('Error creating transaction:', error)
      throw error
    }
    
    return data
  },

  // User Profile Management
  async getUserProfile(userId: string) {
    const { data, error } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('user_id', userId)
      .single()
    
    if (error && error.code !== 'PGRST116') { // Not found error
      console.error('Error fetching user profile:', error)
      throw error
    }
    
    return data
  },

  async createUserProfile(profileData: any) {
    const { data, error } = await supabase
      .from('user_profiles')
      .insert([profileData])
      .select()
    
    if (error) {
      console.error('Error creating user profile:', error)
      throw error
    }
    
    return data
  },

  async updateUserProfile(userId: string, profileData: any) {
    const { data, error } = await supabase
      .from('user_profiles')
      .update(profileData)
      .eq('user_id', userId)
      .select()
    
    if (error) {
      console.error('Error updating user profile:', error)
      throw error
    }
    
    return data
  },

  // Account Management
  async getUserAccounts(userId: string) {
    const { data, error } = await supabase
      .from('accounts')
      .select('*')
      .eq('user_id', userId)
      .eq('is_active', true)
      .order('created_at', { ascending: false })
    
    if (error) {
      console.error('Error fetching accounts:', error)
      throw error
    }
    
    return data || []
  },

  // Loan Applications
  async getUserLoanApplications(userId: string) {
    const { data, error } = await supabase
      .from('loan_applications')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
    
    if (error) {
      console.error('Error fetching loan applications:', error)
      throw error
    }
    
    return data || []
  },

  async createLoanApplication(loanData: any) {
    const { data, error } = await supabase
      .from('loan_applications')
      .insert([loanData])
      .select()
    
    if (error) {
      console.error('Error creating loan application:', error)
      throw error
    }
    
    return data
  }
}

// Admin Service
export const adminService = {
  // Check if user is admin
  async isAdmin(userId: string) {
    const { data, error } = await supabase
      .from('admin_users')
      .select('role')
      .eq('user_id', userId)
      .single()
    return { isAdmin: !!data && !error, role: data?.role, error }
  },

  // Get admin settings
  async getSettings() {
    const { data, error } = await supabase
      .from('admin_settings')
      .select('*')
      .order('setting_key')
    return { data, error }
  },

  // Update admin setting
  async updateSetting(settingKey: string, value: boolean) {
    const { data, error } = await supabase
      .from('admin_settings')
      .update({ setting_value: value, updated_at: new Date().toISOString() })
      .eq('setting_key', settingKey)
      .select()
    return { data, error }
  },

  // Get all users with their approval status
  async getAllUsers() {
    // Get users from auth.users and left join with profiles and approvals
    const { data: users, error: usersError } = await supabase
      .rpc('get_all_users_with_profiles')

    if (usersError) {
      // Fallback: basic list from user_profiles if RPC doesn't exist or fails
      const { data: profileUsers, error: profileError } = await supabase
        .from('user_profiles')
        .select(`*`)
        .order('created_at', { ascending: false })
      
      return { data: profileUsers, error: profileError }
    }

    return { data: users, error: usersError }
  },

  // Get pending user approvals
  async getPendingApprovals() {
    const { data, error } = await supabase
      .from('user_approvals')
      .select('*')
      .order('created_at', { ascending: false })
    return { data, error }
  },

  // Approve user
  async approveUser(approvalId: string, adminId: string) {
    const { data, error } = await supabase
      .from('user_approvals')
      .update({
        status: 'approved',
        approved_by: adminId,
        approved_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', approvalId)
      .select()
    return { data, error }
  },

  // Reject user
  async rejectUser(approvalId: string, adminId: string, reason: string) {
    const { data, error } = await supabase
      .from('user_approvals')
      .update({
        status: 'rejected',
        approved_by: adminId,
        rejection_reason: reason,
        updated_at: new Date().toISOString()
      })
      .eq('id', approvalId)
      .select()
    return { data, error }
  },

  // Get all cards for admin management
  async getAllCards() {
    const { data, error } = await supabase
      .from('bank_cards')
      .select(`*`)
      .order('created_at', { ascending: false })
    return { data, error }
  },

  // Admin card actions
  async adminUpdateCard(cardId: string, updates: any) {
    const { data, error } = await supabase
      .from('bank_cards')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', cardId)
      .select()
    return { data, error }
  },

  // Delete card (admin only)
  async adminDeleteCard(cardId: string) {
    const { data, error } = await supabase
      .from('bank_cards')
      .delete()
      .eq('id', cardId)
    return { data, error }
  },

  // Create user approval request
  async createApprovalRequest(userData: any) {
    const { data, error } = await supabase
      .from('user_approvals')
      .insert([{
        user_id: userData.user_id,
        email: userData.email,
        first_name: userData.first_name,
        last_name: userData.last_name,
        phone: userData.phone,
        status: 'pending'
      }])
      .select()
    return { data, error }
  },

  // Check if invite-only mode is enabled
  async isInviteOnlyMode() {
    const { data, error } = await supabase
      .from('admin_settings')
      .select('setting_value')
      .eq('setting_key', 'invite_only_mode')
      .single()
    return { isInviteOnly: data?.setting_value || false, error }
  },

  // Check user approval status
  async getUserApprovalStatus(userId: string) {
    const { data, error } = await supabase
      .from('user_approvals')
      .select('status, rejection_reason')
      .eq('user_id', userId)
      .maybeSingle()
    return { data, error }
  }
}

// Marketplace Service
export const marketplaceService = {
  // Upload an image to storage and return public URL
  async uploadItemImage(file: File, userId: string) {
    const fileExt = file.name.split('.').pop()
    const fileName = `${userId}/${Date.now()}-${Math.random().toString(36).slice(2)}.${fileExt}`
    const { data, error } = await supabase.storage.from('marketplace').upload(fileName, file, {
      cacheControl: '3600',
      upsert: false,
      contentType: file.type || 'application/octet-stream'
    })
    if (error) {
      console.error('Storage upload error', error)
      return { url: null, error }
    }
    const { data: publicUrl } = supabase.storage.from('marketplace').getPublicUrl(data.path)
    return { url: publicUrl.publicUrl, error: null }
  },
  // Categories
  async getCategories() {
    const { data, error } = await supabase
      .from('marketplace_categories')
      .select('*')
      .eq('is_active', true)
      .order('sort_order')
    return { data, error }
  },

  // Items
  async getItems(filters: any = {}) {
    let query = supabase
      .from('marketplace_items')
      .select(`
        *,
        marketplace_item_images(image_url, is_primary)
      `)
      .or('status.is.null,status.eq.active')

    if (filters.category_id) {
      query = query.eq('category_id', filters.category_id)
    }
    if (filters.search) {
      query = query.or(`title.ilike.%${filters.search}%,description.ilike.%${filters.search}%`)
    }
    if (filters.min_price) {
      query = query.gte('price', filters.min_price)
    }
    if (filters.max_price) {
      query = query.lte('price', filters.max_price)
    }
    if (filters.condition) {
      query = query.eq('condition', filters.condition)
    }
    if (filters.location) {
      query = query.ilike('location', `%${filters.location}%`)
    }

    const { data, error } = await query
      .order('created_at', { ascending: false })
      .limit(filters.limit || 20)

    return { data, error }
  },

  async getItem(itemId: string) {
    // Increment view count
    await supabase.rpc('increment_item_views', { item_uuid: itemId })

    const { data, error } = await supabase
      .from('marketplace_items')
      .select(`
        *,
        marketplace_item_images(image_url, is_primary)
      `)
      .eq('id', itemId)
      .single()

    return { data, error }
  },

  async createItem(itemData: any) {
    const { data, error } = await supabase
      .from('marketplace_items')
      .insert([itemData])
      .select()
    if (error || !data || !data[0]) return { data, error }

    const created = data[0]
    const images: string[] = Array.isArray(itemData.images) ? itemData.images : []
    let imageInsertError: any = null
    if (images.length > 0) {
      const rows = images.map((url, index) => ({
        item_id: created.id,
        image_url: url,
        is_primary: index === 0,
        sort_order: index
      }))
      const { error: imgError } = await supabase
        .from('marketplace_item_images')
        .insert(rows)
      if (imgError) {
        console.error('Failed to insert item images', imgError)
        imageInsertError = imgError
      }
    }

    // Re-fetch item with images for immediate UI display
    const { data: itemWithImages } = await supabase
      .from('marketplace_items')
      .select(`
        *,
        marketplace_item_images(image_url, is_primary)
      `)
      .eq('id', created.id)
      .single()

    return { data: [itemWithImages || created], error, imageInsertError }
  },

  async updateItem(itemId: string, updates: any) {
    const { data, error } = await supabase
      .from('marketplace_items')
      .update(updates)
      .eq('id', itemId)
      .select()
    return { data, error }
  },

  async deleteItem(itemId: string) {
    const { data, error } = await supabase
      .from('marketplace_items')
      .delete()
      .eq('id', itemId)
    return { data, error }
  },

  // User's items
  async getUserItems(userId: string) {
    const { data, error } = await supabase
      .from('marketplace_items')
      .select(`
        *,
        marketplace_categories(name, icon),
        marketplace_item_images(image_url, is_primary)
      `)
      .eq('seller_id', userId)
      .order('created_at', { ascending: false })
    return { data, error }
  },

  // Favorites
  async getFavorites(userId: string) {
    const { data, error } = await supabase
      .from('marketplace_favorites')
      .select(`*, marketplace_items(*, marketplace_item_images(image_url, is_primary))`)
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
    return { data, error }
  },

  async addToFavorites(userId: string, itemId: string) {
    const { data, error } = await supabase
      .from('marketplace_favorites')
      .insert([{ user_id: userId, item_id: itemId }])
      .select()
    return { data, error }
  },

  async removeFromFavorites(userId: string, itemId: string) {
    const { data, error } = await supabase
      .from('marketplace_favorites')
      .delete()
      .eq('user_id', userId)
      .eq('item_id', itemId)
    return { data, error }
  },

  async isFavorite(userId: string, itemId: string) {
    const { data, error } = await supabase
      .from('marketplace_favorites')
      .select('id')
      .eq('user_id', userId)
      .eq('item_id', itemId)
      .maybeSingle()
    return { isFavorite: !!data, error: error || null }
  },

  // Shopping Cart
  async getCart(userId: string) {
    const { data, error } = await supabase
      .from('marketplace_cart')
      .select(`*, marketplace_items(*, marketplace_item_images(image_url, is_primary))`)
      .eq('user_id', userId)
      .order('added_at', { ascending: false })
    return { data, error }
  },

  async addToCart(userId: string, itemId: string, quantity: number = 1) {
    const { data, error } = await supabase
      .from('marketplace_cart')
      .upsert([{ 
        user_id: userId, 
        item_id: itemId, 
        quantity: quantity 
      }])
      .select()
    return { data, error }
  },

  async updateCartQuantity(userId: string, itemId: string, quantity: number) {
    const { data, error } = await supabase
      .from('marketplace_cart')
      .update({ quantity })
      .eq('user_id', userId)
      .eq('item_id', itemId)
      .select()
    return { data, error }
  },

  async removeFromCart(userId: string, itemId: string) {
    const { data, error } = await supabase
      .from('marketplace_cart')
      .delete()
      .eq('user_id', userId)
      .eq('item_id', itemId)
    return { data, error }
  },

  async clearCart(userId: string) {
    const { data, error } = await supabase
      .from('marketplace_cart')
      .delete()
      .eq('user_id', userId)
    return { data, error }
  },

  // Orders
  async createOrder(orderData: any, cartItems: any[]) {
    try {
      // Create order
      const orderNumber = await supabase.rpc('generate_order_number')
      
      const { data: order, error: orderError } = await supabase
        .from('marketplace_orders')
        .insert([{
          ...orderData,
          order_number: orderNumber.data
        }])
        .select()
        .single()

      if (orderError) return { data: null, error: orderError }

      // Create order items
      const orderItems = cartItems.map(item => ({
        order_id: order.id,
        item_id: item.marketplace_items.id,
        quantity: item.quantity,
        unit_price: item.marketplace_items.price,
        total_price: item.marketplace_items.price * item.quantity,
        item_snapshot: item.marketplace_items
      }))

      const { error: itemsError } = await supabase
        .from('marketplace_order_items')
        .insert(orderItems)

      if (itemsError) return { data: null, error: itemsError }

      return { data: order, error: null }
    } catch (error) {
      return { data: null, error }
    }
  },

  async getUserOrders(userId: string) {
    const { data, error } = await supabase
      .from('marketplace_orders')
      .select(`
        *,
        marketplace_order_items(
          *,
          marketplace_items(title, images)
        )
      `)
      .or(`buyer_id.eq.${userId},seller_id.eq.${userId}`)
      .order('created_at', { ascending: false })
    return { data, error }
  },

  async updateOrderStatus(orderId: string, status: string) {
    const { data, error } = await supabase
      .from('marketplace_orders')
      .update({ status })
      .eq('id', orderId)
      .select()
    return { data, error }
  },

  // Reviews
  async getItemReviews(itemId: string) {
    const { data, error } = await supabase
      .from('marketplace_reviews')
      .select('*')
      .eq('item_id', itemId)
      .order('id', { ascending: false })
    return { data, error }
  },

  async createReview(reviewData: any) {
    const { data, error } = await supabase
      .from('marketplace_reviews')
      .insert([reviewData])
      .select()
    return { data, error }
  },

  // Messages
  async getItemMessages(itemId: string, userId: string) {
    const { data, error } = await supabase
      .from('marketplace_messages')
      .select(`
        *,
        sender:user_profiles!marketplace_messages_sender_id_fkey(first_name, last_name),
        recipient:user_profiles!marketplace_messages_recipient_id_fkey(first_name, last_name)
      `)
      .eq('item_id', itemId)
      .or(`sender_id.eq.${userId},recipient_id.eq.${userId}`)
      .order('created_at', { ascending: true })
    return { data, error }
  },

  async sendMessage(messageData: any) {
    const { data, error } = await supabase
      .from('marketplace_messages')
      .insert([messageData])
      .select()
    return { data, error }
  },

  async markMessagesAsRead(itemId: string, userId: string) {
    const { data, error } = await supabase
      .from('marketplace_messages')
      .update({ is_read: true })
      .eq('item_id', itemId)
      .eq('recipient_id', userId)
    return { data, error }
  }
}
