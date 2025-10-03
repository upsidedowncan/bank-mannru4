<script lang="ts">
  import { onMount } from 'svelte'
  import Icon from '@iconify/svelte'
  import { supabase, bankService } from '$lib/supabase'

  // Tabs: 'tictactoe' | 'snake'
  let activeTab: string = 'tictactoe'
  type Difficulty = 'easy' | 'normal' | 'hard'
  let difficulty: Difficulty = 'normal'

  // Common UI
  function setTab(tab: string) {
    activeTab = tab
  }

  // Tic Tac Toe state
  type Cell = 'X' | 'O' | ''
  let board: Cell[] = Array(9).fill('')
  let currentPlayer: Cell = 'X'
  let winner: Cell | 'draw' | '' = ''
  let tttScore = { X: 0, O: 0 }
  let payoutMessage = ''
  let isPaying = false
  let user: any = null
  let userCards: any[] = []
  let payoutCardId = ''

  function resetTicTacToe(full = false) {
    board = Array(9).fill('')
    currentPlayer = 'X'
    winner = ''
    if (full) tttScore = { X: 0, O: 0 }
  }

  function checkWinner(b: Cell[]): Cell | 'draw' | '' {
    const wins = [
      [0,1,2],[3,4,5],[6,7,8],
      [0,3,6],[1,4,7],[2,5,8],
      [0,4,8],[2,4,6]
    ]
    for (const [a,b2,c] of wins) {
      if (b[a] && b[a] === b[b2] && b[a] === b[c]) return b[a]
    }
    if (b.every(c => c)) return 'draw'
    return ''
  }

  function play(index: number) {
    if (winner || board[index]) return
    board[index] = currentPlayer
    const res = checkWinner(board)
    if (res) {
      winner = res
      if (res === 'X') tttScore.X += 1
      if (res === 'O') tttScore.O += 1
      handleTttPayout(res)
    } else {
      currentPlayer = currentPlayer === 'X' ? 'O' : 'X'
      if (currentPlayer === 'O') {
        // Bot move
        const move = chooseBotMove(board)
        if (move !== -1) {
          board[move] = 'O'
          currentPlayer = 'X'
          const after = checkWinner(board)
          if (after) {
            winner = after
            if (after === 'X') tttScore.X += 1
            if (after === 'O') tttScore.O += 1
            handleTttPayout(after)
          }
        }
      }
    }
  }

  // Bot move by difficulty
  function chooseBotMove(b: Cell[]): number {
    if (difficulty === 'easy') {
      const empties = b.map((c, i) => (c ? -1 : i)).filter(i => i !== -1)
      return empties.length ? empties[Math.floor(Math.random() * empties.length)] : -1
    }
    if (difficulty === 'normal') {
      return bestMoveForO(b, 2) // shallow search, more human-friendly
    }
    return bestMoveForO(b, Infinity) // hard
  }

  // Minimax with optional depth cap
  function bestMoveForO(b: Cell[], depthCap: number): number {
    let bestScore = Infinity
    let move = -1
    for (let i = 0; i < 9; i++) {
      if (!b[i]) {
        b[i] = 'O'
        const score = minimax(b, 0, true, depthCap)
        b[i] = ''
        if (score < bestScore) {
          bestScore = score
          move = i
        }
      }
    }
    return move
  }

  function minimax(b: Cell[], depth: number, isMaximizing: boolean, depthCap: number): number {
    if (depth >= depthCap) return 0
    const res = checkWinner(b)
    if (res === 'X') return 10 - depth
    if (res === 'O') return depth - 10
    if (res === 'draw') return 0
    if (isMaximizing) {
      let best = -Infinity
      for (let i = 0; i < 9; i++) {
        if (!b[i]) {
          b[i] = 'X'
          best = Math.max(best, minimax(b, depth + 1, false, depthCap))
          b[i] = ''
        }
      }
      return best
    } else {
      let best = Infinity
      for (let i = 0; i < 9; i++) {
        if (!b[i]) {
          b[i] = 'O'
          best = Math.min(best, minimax(b, depth + 1, true, depthCap))
          b[i] = ''
        }
      }
      return best
    }
  }

  // Snake
  let canvasEl: HTMLCanvasElement | null = null
  let ctx: CanvasRenderingContext2D | null = null
  const tileSize = 16
  let cols = 20
  let rows = 20
  let snake: { x: number; y: number }[] = []
  let dir = { x: 1, y: 0 }
  let food = { x: 10, y: 10 }
  let snakeRunning = false
  let snakeScore = 0
  let loopId: number | null = null

  function randomFood() {
    food = { x: Math.floor(Math.random() * cols), y: Math.floor(Math.random() * rows) }
  }

  function resetSnake() {
    snake = [{ x: 5, y: 10 }]
    dir = { x: 1, y: 0 }
    randomFood()
    snakeScore = 0
  }

  function startSnake() {
    if (!ctx) return
    snakeRunning = true
    if (loopId) cancelAnimationFrame(loopId)
    loop()
  }

  function stopSnake() {
    snakeRunning = false
    if (loopId) cancelAnimationFrame(loopId)
  }

  function loop() {
    loopId = requestAnimationFrame(() => {
      if (!snakeRunning) return
      updateSnake()
      drawSnake()
      loop()
    })
  }

  function updateSnake() {
    const head = { x: snake[0].x + dir.x, y: snake[0].y + dir.y }
    // wrap
    head.x = (head.x + cols) % cols
    head.y = (head.y + rows) % rows

    // self-collision
    if (snake.some((s, i) => i !== 0 && s.x === head.x && s.y === head.y)) {
      resetSnake()
      return
    }

    snake.unshift(head)
    if (head.x === food.x && head.y === food.y) {
      snakeScore += 10
      randomFood()
    } else {
      snake.pop()
    }
  }

  function drawSnake() {
    if (!ctx || !canvasEl) return
    ctx.clearRect(0, 0, canvasEl.width, canvasEl.height)
    // grid bg
    ctx.fillStyle = '#f3f4f6'
    ctx.fillRect(0, 0, canvasEl.width, canvasEl.height)
    // food
    ctx.fillStyle = '#ef4444'
    ctx.fillRect(food.x * tileSize, food.y * tileSize, tileSize, tileSize)
    // snake
    ctx.fillStyle = '#10b981'
    for (const part of snake) {
      ctx.fillRect(part.x * tileSize, part.y * tileSize, tileSize, tileSize)
    }
  }

  function handleKey(e: KeyboardEvent) {
    if (activeTab !== 'snake') return
    if (e.key === 'ArrowUp' && dir.y !== 1) dir = { x: 0, y: -1 }
    if (e.key === 'ArrowDown' && dir.y !== -1) dir = { x: 0, y: 1 }
    if (e.key === 'ArrowLeft' && dir.x !== 1) dir = { x: -1, y: 0 }
    if (e.key === 'ArrowRight' && dir.x !== -1) dir = { x: 1, y: 0 }
  }

  onMount(() => {
    // auth & cards
    (async () => {
      const { data: { user: currentUser } } = await supabase.auth.getUser()
      user = currentUser
      if (user) {
        userCards = await bankService.getUserCards(user.id)
      }
    })()
    // Prepare snake canvas
    setTimeout(() => {
      if (canvasEl) {
        // responsive canvas based on container width
        const width = Math.min(480, canvasEl.parentElement?.clientWidth || 320)
        cols = Math.floor(width / tileSize)
        rows = cols
        canvasEl.width = cols * tileSize
        canvasEl.height = rows * tileSize
        ctx = canvasEl.getContext('2d')
        resetSnake()
        drawSnake()
      }
    })
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  })

  async function handleTttPayout(result: Cell | 'draw') {
    if (!user || !payoutCardId) return
    try {
      isPaying = true
      let amount = 0
      if (result === 'X') amount = 10
      else if (result === 'draw') amount = 2
      if (amount <= 0) return
      await awardBalance(amount, 'TicTacToe reward')
      payoutMessage = `+${amount} МР за игру в Крестики‑нолики`
    } finally {
      isPaying = false
    }
  }

  async function awardBalance(amount: number, description: string) {
    // find card
    const card = userCards.find((c) => c.id === payoutCardId)
    if (!card) return
    const newBalance = (card.balance || 0) + amount
    await bankService.updateCardBalance(card.id, newBalance)
    await bankService.createTransaction({
      user_id: user.id,
      to_card_id: card.id,
      amount,
      transaction_type: 'credit',
      description
    })
    // refresh local
    userCards = await bankService.getUserCards(user.id)
  }
</script>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 overflow-x-hidden">
  <div class="flex items-center justify-between mb-6">
    <h1 class="text-2xl font-light tracking-tight">Игры</h1>
    <a class="btn btn-ghost btn-sm" href="/">
      <Icon icon="mdi:home" class="w-4 h-4 mr-1" /> На главную
    </a>
  </div>

  <div class="tabs tabs-boxed w-full overflow-x-auto">
    <button class={`tab tab-lifted ${activeTab === 'tictactoe' ? 'tab-active' : ''}`} on:click={() => setTab('tictactoe')}>Крестики‑нолики</button>
    <button class={`tab tab-lifted ${activeTab === 'snake' ? 'tab-active' : ''}`} on:click={() => setTab('snake')}>Змейка</button>
  </div>

  {#if activeTab === 'tictactoe'}
    <div class="mt-6 bg-white rounded-lg shadow-sm p-6">
      <div class="flex items-center justify-between mb-4">
        <div class="text-sm text-gray-600">Ход: <span class="font-medium">{currentPlayer}</span></div>
        <div class="text-sm text-gray-600">Счет — X: <span class="font-medium">{tttScore.X}</span> · O: <span class="font-medium">{tttScore.O}</span></div>
      </div>
      <div class="flex items-center gap-3 mb-4">
        <label class="text-sm text-gray-600">Сложность:</label>
        <div class="join">
          <button class={`btn btn-xs join-item ${difficulty === 'easy' ? 'btn-active' : ''}`} on:click={() => difficulty = 'easy'}>Легко</button>
          <button class={`btn btn-xs join-item ${difficulty === 'normal' ? 'btn-active' : ''}`} on:click={() => difficulty = 'normal'}>Норма</button>
          <button class={`btn btn-xs join-item ${difficulty === 'hard' ? 'btn-active' : ''}`} on:click={() => difficulty = 'hard'}>Сложно</button>
        </div>
      </div>
      {#if user}
        <div class="form-control mb-4">
          <label class="label">
            <span class="label-text">Карта для начислений</span>
          </label>
          <select class="select select-bordered max-w-md" bind:value={payoutCardId}>
            <option value="">Выберите карту</option>
            {#each userCards as c}
              <option value={c.id}>{c.card_name} (**** {c.card_number?.slice(-4)})</option>
            {/each}
          </select>
        </div>
      {/if}
      <div class="grid grid-cols-3 gap-2 max-w-xs sm:max-w-sm mx-auto">
        {#each board as cell, i}
          <button class="btn h-20 sm:h-24 text-2xl" on:click={() => play(i)} disabled={!!winner || !!cell}>
            {cell}
          </button>
        {/each}
      </div>
      <div class="mt-4 text-center min-h-[1.5rem]">
        {#if winner === 'draw'}
          <div class="text-gray-700">Ничья</div>
        {:else if winner}
          <div class="text-gray-900">Победитель: <span class="font-semibold">{winner}</span></div>
        {/if}
        {#if payoutMessage}
          <div class="text-green-600 mt-2">{payoutMessage}</div>
        {/if}
      </div>
      <div class="mt-4 flex justify-center gap-3">
        <button class="btn btn-primary btn-sm" on:click={() => resetTicTacToe(false)} disabled={isPaying}>Новая партия</button>
        <button class="btn btn-ghost btn-sm" on:click={() => resetTicTacToe(true)} disabled={isPaying}>Сбросить счет</button>
      </div>
    </div>
  {/if}

  {#if activeTab === 'snake'}
    <div class="mt-6 bg-white rounded-lg shadow-sm p-6">
      <div class="flex items-center justify-between mb-4">
        <div class="text-sm text-gray-600">Счет: <span class="font-medium">{snakeScore}</span></div>
        <div class="flex gap-2">
          <button class="btn btn-primary btn-sm" on:click={startSnake} disabled={snakeRunning}><Icon icon="mdi:play" class="w-4 h-4 mr-1"/>Старт</button>
          <button class="btn btn-ghost btn-sm" on:click={stopSnake} disabled={!snakeRunning}><Icon icon="mdi:pause" class="w-4 h-4 mr-1"/>Пауза</button>
          <button class="btn btn-ghost btn-sm" on:click={() => { stopSnake(); resetSnake(); drawSnake(); }}><Icon icon="mdi:reload" class="w-4 h-4 mr-1"/>Сброс</button>
        </div>
      </div>
      <div class="flex justify-center">
        <canvas bind:this={canvasEl} class="border border-gray-200 rounded"></canvas>
      </div>
      <p class="text-xs text-gray-500 text-center mt-3">Управление стрелками на клавиатуре</p>
    </div>
  {/if}
</div>

<style>
  .tabs :global(.tab) {
    min-width: 8rem;
  }
</style>


