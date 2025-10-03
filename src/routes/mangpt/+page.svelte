<script lang="ts">
  import { onMount } from 'svelte'
  import Icon from '@iconify/svelte'
  import { supabase, bankService, marketplaceService } from '$lib/supabase'

  type Message = { role: 'user' | 'assistant' | 'system'; content: string }
  let messages: Message[] = [
    { role: 'assistant', content: 'Привет! Я ManGPT. Введи текст или команды: /addcard, /deposit, /withdraw, /balance, /sell' }
  ]
  let input = ''
  // Use environment-backed key by default but allow override
  // Replace with your Groq key or ensure PUBLIC_GROQ_API_KEY is set
  let apiKey = "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"
  let user: any = null

  onMount(async () => {
    const { data: { user: currentUser } } = await supabase.auth.getUser()
    user = currentUser
  })

  async function send() {
    const text = input.trim()
    if (!text) return
    messages = [...messages, { role: 'user', content: text }]
    input = ''

    // Commands
    if (text.startsWith('/')) {
      await handleCommand(text)
      return
    }

    // Chat with Groq (OpenAI compatible)
    if (!apiKey) {
      messages = [...messages, { role: 'assistant', content: 'Укажите API ключ Groq' }]
      return
    }
    try {
      const resp = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`
        },
        body: JSON.stringify({
          // Prefer a Groq model that supports tool calls
          model: 'llama-3.1-70b-versatile',
          messages: buildToolAwareMessages(),
          temperature: 0.4,
          max_tokens: 400,
          tool_choice: 'auto',
          tools: [
            {
              type: 'function',
              function: {
                name: 'get_balance',
                description: 'Получить балансы всех карт текущего пользователя',
                parameters: { type: 'object', properties: {} }
              }
            },
            {
              type: 'function',
              function: {
                name: 'add_card',
                description: 'Создать карту для пользователя',
                parameters: {
                  type: 'object',
                  properties: {
                    card_name: { type: 'string' },
                    card_type: { type: 'string', enum: ['debit','credit','savings'] }
                  },
                  required: ['card_name','card_type']
                }
              }
            },
            {
              type: 'function',
              function: {
                name: 'deposit',
                description: 'Зачислить деньги на карту',
                parameters: {
                  type: 'object',
                  properties: { target: { type: 'string' }, amount: { type: 'number' } },
                  required: ['target','amount']
                }
              }
            },
            {
              type: 'function',
              function: {
                name: 'withdraw',
                description: 'Списать деньги с карты',
                parameters: {
                  type: 'object',
                  properties: { target: { type: 'string' }, amount: { type: 'number' } },
                  required: ['target','amount']
                }
              }
            },
            {
              type: 'function',
              function: {
                name: 'create_item',
                description: 'Создать товар в маркетплейсе',
                parameters: {
                  type: 'object',
                  properties: {
                    title: { type: 'string' },
                    description: { type: 'string' },
                    price: { type: 'number' },
                    category_id: { type: 'string' }
                  },
                  required: ['title','description','price','category_id']
                }
              }
            }
          ]
        })
      })
      const data = await resp.json()
      if (!resp.ok) {
        const errMsg = data?.error?.message || 'Bad Request'
        messages = [...messages, { role: 'assistant', content: `Ошибка Groq: ${errMsg}` }]
        // Fallback: run local intent so actions still execute
        await detectAndRunIntent(text)
        return
      }
      const choice = data?.choices?.[0]
      const tool = choice?.message?.tool_calls?.[0]
      if (tool?.function?.name) {
        await runTool(tool.function.name, JSON.parse(tool.function.arguments || '{}'))
      }
      const content = choice?.message?.content
      if (content) {
        messages = [...messages, { role: 'assistant', content }]
      }
      // Fallback: if no tool call provided, try to infer an action
      if (!tool) {
        await detectAndRunIntent(text)
      }
    } catch (e) {
      messages = [...messages, { role: 'assistant', content: 'Ошибка запроса к Groq' }]
    }
  }

  function buildToolAwareMessages() {
    const sys = { role: 'system', content: 'Ты банкинг/маркет ассистент. При необходимости вызывай функции-инструменты.' }
    return [sys, ...messages]
  }

  async function runTool(name: string, args: any) {
    switch (name) {
      case 'get_balance': {
        const cards = await bankService.getUserCards(user.id)
        const lines = cards.map(c => `${c.card_name}: ${c.balance} МР`).join('\n')
        messages = [...messages, { role: 'assistant', content: lines || 'Карт нет' }]
        break
      }
      case 'add_card': {
        await bankService.createCard({ user_id: user.id, card_name: args.card_name, card_type: args.card_type, currency: 'МР' })
        messages = [...messages, { role: 'assistant', content: 'Карта создана.' }]
        break
      }
      case 'deposit': {
        const cards = await bankService.getUserCards(user.id)
        const card = cards.find((c: any) => c.id === args.target || c.card_number?.slice(-4) === args.target)
        if (!card) { messages = [...messages, { role: 'assistant', content: 'Карта не найдена' }]; break }
        const amount = Number(args.amount || 0)
        await bankService.updateCardBalance(card.id, (card.balance || 0) + amount)
        await bankService.createTransaction({ user_id: user.id, to_card_id: card.id, amount, transaction_type: 'credit', description: 'Пополнение через ManGPT' })
        messages = [...messages, { role: 'assistant', content: `Зачислено +${amount} МР` }]
        break
      }
      case 'withdraw': {
        const cards = await bankService.getUserCards(user.id)
        const card = cards.find((c: any) => c.id === args.target || c.card_number?.slice(-4) === args.target)
        if (!card) { messages = [...messages, { role: 'assistant', content: 'Карта не найдена' }]; break }
        const amount = Number(args.amount || 0)
        await bankService.updateCardBalance(card.id, (card.balance || 0) - amount)
        await bankService.createTransaction({ user_id: user.id, from_card_id: card.id, amount, transaction_type: 'debit', description: 'Снятие через ManGPT' })
        messages = [...messages, { role: 'assistant', content: `Списано -${amount} МР` }]
        break
      }
      case 'create_item': {
        const itemData = {
          seller_id: user.id,
          title: args.title,
          description: args.description,
          price: Number(args.price || 0),
          category_id: args.category_id,
          condition: 'good',
          location: 'онлайн',
          shipping_available: false,
          shipping_cost: 0,
          pickup_available: true,
          tags: [],
          status: 'active',
          currency: 'МР'
        }
        const { error } = await marketplaceService.createItem(itemData)
        if (error) messages = [...messages, { role: 'assistant', content: 'Ошибка создания товара' }]
        else messages = [...messages, { role: 'assistant', content: 'Товар создан.' }]
        break
      }
    }
  }

  // Heuristic fallback intent handling when the model doesn't return tool calls
  async function detectAndRunIntent(userText: string) {
    const t = userText.toLowerCase()
    if (t.includes('баланс')) {
      await runTool('get_balance', {})
      return
    }
    if (t.includes('создай карту') || t.includes('создать карту')) {
      await runTool('add_card', { card_name: 'Карта ManGPT', card_type: 'debit' })
      return
    }
    const dep = t.match(/попол(ни|нить).*?(\d+[\.,]?\d*)/)
    if (dep) {
      await runTool('deposit', { target: dep[1] || '', amount: Number(dep[2].replace(',', '.')) })
      return
    }
    const wd = t.match(/сним(и|ать).*?(\d+[\.,]?\d*)/)
    if (wd) {
      await runTool('withdraw', { target: wd[1] || '', amount: Number(wd[2].replace(',', '.')) })
      return
    }
    if (t.includes('сделай сам') || t.includes('сделай товар') || t.includes('создай товар')) {
      await runTool('create_item', { title: 'Странный товар', description: 'Сделан ИИ ManGPT', price: 1, category_id: 'other' })
    }
  }

  // Minimal markdown rendering for assistant responses
  function escapeHtml(s: string) {
    return s
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
  }

  function renderMarkdown(md: string) {
    let html = escapeHtml(md)
    // headings
    html = html.replace(/^###\s+(.*)$/gm, '<h3 class="text-base font-semibold">$1</h3>')
    html = html.replace(/^##\s+(.*)$/gm, '<h2 class="text-lg font-semibold">$1</h2>')
    html = html.replace(/^#\s+(.*)$/gm, '<h1 class="text-xl font-semibold">$1</h1>')
    // bold/italic
    html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    html = html.replace(/\*(.*?)\*/g, '<em>$1</em>')
    // lists
    html = html.replace(/^(?:-\s+.*(?:\n|$))+?/gm, (block) => {
      const items = block.trim().split(/\n/).map(li => li.replace(/^-\s+/, '')).map(li => `<li>${li}</li>`).join('')
      return `<ul class="list-disc ml-5">${items}</ul>`
    })
    // line breaks
    html = html.replace(/\n/g, '<br>')
    return html
  }

  async function handleCommand(text: string) {
    if (!user) {
      messages = [...messages, { role: 'assistant', content: 'Сначала войдите в систему.' }]
      return
    }
    const [cmd, ...rest] = text.split(' ')
    try {
      switch (cmd.toLowerCase()) {
        case '/balance': {
          const cards = await bankService.getUserCards(user.id)
          if (!cards.length) {
            messages = [...messages, { role: 'assistant', content: 'Карт нет.' }]
          } else {
            const lines = cards.map(c => `${c.card_name}: ${c.balance} МР`)
            messages = [...messages, { role: 'assistant', content: lines.join('\n') }]
          }
          break
        }
        case '/addcard': {
          // /addcard <name> <debit|credit|savings>
          const name = rest[0] || 'Новая карта'
          const type = (rest[1] as any) || 'debit'
          await bankService.createCard({ user_id: user.id, card_name: name, card_type: type, currency: 'МР' })
          messages = [...messages, { role: 'assistant', content: 'Карта создана.' }]
          break
        }
        case '/deposit': {
          // /deposit <card_last4|card_id> <amount>
          const [target, amountStr] = rest
          const amount = parseFloat(amountStr)
          const cards = await bankService.getUserCards(user.id)
          const card = cards.find(c => c.id === target || c.card_number?.slice(-4) === target)
          if (!card || !amount || amount <= 0) {
            messages = [...messages, { role: 'assistant', content: 'Использование: /deposit <card_last4|card_id> <amount>' }]
            return
          }
          await bankService.updateCardBalance(card.id, (card.balance || 0) + amount)
          await bankService.createTransaction({ user_id: user.id, to_card_id: card.id, amount, transaction_type: 'credit', description: 'Пополнение через ManGPT' })
          messages = [...messages, { role: 'assistant', content: `Зачислено +${amount} МР на ${card.card_name}.` }]
          break
        }
        case '/withdraw': {
          const [target, amountStr] = rest
          const amount = parseFloat(amountStr)
          const cards = await bankService.getUserCards(user.id)
          const card = cards.find(c => c.id === target || c.card_number?.slice(-4) === target)
          if (!card || !amount || amount <= 0) {
            messages = [...messages, { role: 'assistant', content: 'Использование: /withdraw <card_last4|card_id> <amount>' }]
            return
          }
          await bankService.updateCardBalance(card.id, (card.balance || 0) - amount)
          await bankService.createTransaction({ user_id: user.id, from_card_id: card.id, amount, transaction_type: 'debit', description: 'Снятие через ManGPT' })
          messages = [...messages, { role: 'assistant', content: `Списано -${amount} МР с ${card.card_name}.` }]
          break
        }
        case '/sell': {
          // /sell title | description | price | category_id
          const joined = rest.join(' ')
          const parts = joined.split('|').map(s => s.trim())
          if (parts.length < 4) {
            messages = [...messages, { role: 'assistant', content: 'Использование: /sell title | description | price | category_id' }]
            return
          }
          const [title, description, priceStr, category_id] = parts
          const itemData: any = {
            seller_id: user.id,
            title,
            description,
            price: parseFloat(priceStr),
            category_id,
            condition: 'good',
            location: 'онлайн',
            shipping_available: false,
            shipping_cost: 0,
            pickup_available: true,
            tags: [],
            status: 'active',
            currency: 'МР'
          }
          const { data, error } = await marketplaceService.createItem(itemData)
          if (error) throw error
          messages = [...messages, { role: 'assistant', content: `Товар создан: ${title}` }]
          break
        }
        default:
          messages = [...messages, { role: 'assistant', content: 'Неизвестная команда. Доступно: /addcard, /deposit, /withdraw, /balance, /sell' }]
      }
    } catch (e) {
      messages = [...messages, { role: 'assistant', content: 'Ошибка выполнения команды.' }]
    }
  }
</script>

<div class="h-[calc(100vh-4rem)] w-full flex flex-col">
  <!-- Optional small settings bar -->
  <div class="border-b bg-base-100 px-4 py-2">
    <div class="flex items-center gap-3">
      <h1 class="text-lg font-light">ManGPT</h1>
      <div class="flex-1"></div>
      <div class="form-control max-w-sm w-full hidden sm:block">
        <label class="label"><span class="label-text">Groq API Key</span></label>
        <input class="input input-bordered input-sm" type="password" bind:value={apiKey} placeholder="sk_..." />
      </div>
    </div>
  </div>

  <!-- Messages area -->
  <div class="flex-1 overflow-y-auto px-2 sm:px-4 py-3 space-y-3">
    {#each messages as m}
      <div class={`chat ${m.role === 'user' ? 'chat-end' : 'chat-start'}`}>
        {#if m.role === 'assistant'}
          <div class={`chat-bubble whitespace-pre-wrap ${m.role === 'user' ? 'bg-primary text-primary-content' : 'bg-base-200 text-base-content'}`}>
            {@html renderMarkdown(m.content)}
          </div>
        {:else}
          <div class={`chat-bubble whitespace-pre-wrap bg-primary text-primary-content`}>{m.content}</div>
        {/if}
      </div>
    {/each}
  </div>

  <!-- Sticky input bar -->
  <div class="sticky bottom-0 bg-base-100 border-t px-2 sm:px-4 py-3">
    <div class="join w-full">
      <input class="input input-bordered join-item w-full" bind:value={input} placeholder="Напишите сообщение или команду..." on:keydown={(e) => e.key === 'Enter' && send()} />
      <button class="btn btn-primary join-item" on:click={send}><Icon icon="mdi:send" class="w-4 h-4"/></button>
    </div>
  </div>
</div>


