<script lang="ts">
  import Icon from "@iconify/svelte";
  import { onMount } from "svelte";
  import { goto } from "$app/navigation";
  import { supabase, adminService } from "$lib/supabase";

  let user: any = null;
  let cards: any[] = [];
  let transactions: any[] = [];
  let isLoading = true;
  let isAdmin = false;
  let showCreateCardModal = false;
  let showTransferModal = false;
  let showBorrowModal = false;
  let showCardManagementModal = false;
  let isClosingCreateCard = false;
  let isClosingTransfer = false;
  let isClosingBorrow = false;
  let isClosingCardManagement = false;
  let selectedCard: any = null;

  // Create card form
  let createCardForm = {
    card_type: "debit",
    card_name: "",
    currency: "МР",
  };
  let isCreatingCard = false;

  // Transfer form
  let transferForm = {
    from_card: "",
    to_account: "",
    amount: "",
    description: "",
  };
  let isTransferring = false;

  // Borrow form
  let borrowForm = {
    card_id: "",
    amount: "",
  };
  let isBorrowing = false;

  // Dashboard stats
  let totalBalance = 0;
  let monthlyIncome = 0;
  let monthlyExpenses = 0;

  onMount(async () => {
    await checkAuth();
    if (user) {
      await Promise.all([loadCards(), loadTransactions()]);
    }
    isLoading = false;
  });

  async function checkAuth() {
    const {
      data: { user: currentUser },
    } = await supabase.auth.getUser();
    if (!currentUser) {
      goto("/login");
      return;
    }
    user = currentUser;

    // Check if user is admin
    const { isAdmin: userIsAdmin } = await adminService.isAdmin(user.id);
    isAdmin = userIsAdmin;
  }

  async function loadCards() {
    const { data, error } = await supabase
      .from("bank_cards")
      .select("*")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false });

    if (error) {
      console.error("Error loading cards:", error);
      return;
    }

    cards = data || [];
    calculateTotalBalance();
  }

  async function loadTransactions() {
    const { data, error } = await supabase
      .from("transactions")
      .select(
        `
				*,
				from_card:bank_cards!transactions_from_card_id_fkey(card_number, card_name),
				to_card:bank_cards!transactions_to_card_id_fkey(card_number, card_name)
			`,
      )
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(10);

    if (error) {
      console.error("Error loading transactions:", error);
      return;
    }

    transactions = data || [];
    calculateMonthlyStats();
  }

  function calculateTotalBalance() {
    totalBalance = cards.reduce((sum, card) => sum + (card.balance || 0), 0);
  }

  function calculateMonthlyStats() {
    const now = new Date();
    const currentMonth = now.getMonth();
    const currentYear = now.getFullYear();

    monthlyIncome = transactions
      .filter((t) => {
        const date = new Date(t.created_at);
        return (
          date.getMonth() === currentMonth &&
          date.getFullYear() === currentYear &&
          t.transaction_type === "credit"
        );
      })
      .reduce((sum, t) => sum + t.amount, 0);

    monthlyExpenses = transactions
      .filter((t) => {
        const date = new Date(t.created_at);
        return (
          date.getMonth() === currentMonth &&
          date.getFullYear() === currentYear &&
          t.transaction_type === "debit"
        );
      })
      .reduce((sum, t) => sum + t.amount, 0);
  }

  function closeCreateCardModal() {
    isClosingCreateCard = true;
    setTimeout(() => {
      showCreateCardModal = false;
      isClosingCreateCard = false;
    }, 200);
  }

  async function createCard() {
    if (!createCardForm.card_name.trim()) return;

    isCreatingCard = true;

    // Generate card number (for demo purposes)
    const cardNumber =
      "4" + Math.random().toString().slice(2, 15).padStart(15, "0");
    const expiryDate = new Date();
    expiryDate.setFullYear(expiryDate.getFullYear() + 3);

    const { data, error } = await supabase
      .from("bank_cards")
      .insert([
        {
          user_id: user.id,
          card_number: cardNumber,
          card_name: createCardForm.card_name,
          card_type: createCardForm.card_type,
          currency: createCardForm.currency,
          balance: createCardForm.card_type === "debit" ? 0 : 0, // All cards start with 0
          credit_limit: createCardForm.card_type === "credit" ? 50000 : null,
          expiry_date: expiryDate.toISOString(),
          is_active: true,
        },
      ])
      .select();

    if (error) {
      console.error("Error creating card:", error);
      alert("Ошибка создания карты");
    } else {
      await loadCards();
      closeCreateCardModal();
      createCardForm = { card_type: "debit", card_name: "", currency: "RUB" };
    }

    isCreatingCard = false;
  }

  function closeTransferModal() {
    isClosingTransfer = true;
    setTimeout(() => {
      showTransferModal = false;
      isClosingTransfer = false;
    }, 200);
  }

  async function makeTransfer() {
    if (
      !transferForm.from_card ||
      !transferForm.to_account ||
      !transferForm.amount
    )
      return;

    isTransferring = true;

    const amount = parseFloat(transferForm.amount);
    const fromCard = cards.find((c) => c.id === transferForm.from_card);

    if (!fromCard || fromCard.balance < amount) {
      alert("Недостаточно средств на карте");
      isTransferring = false;
      return;
    }

    // Create transaction record
    const { error: transactionError } = await supabase
      .from("transactions")
      .insert([
        {
          user_id: user.id,
          from_card_id: transferForm.from_card,
          amount: amount,
          transaction_type: "debit",
          description: transferForm.description || "Перевод",
          status: "completed",
          recipient_account: transferForm.to_account,
        },
      ]);

    if (transactionError) {
      console.error("Error creating transaction:", transactionError);
      alert("Ошибка выполнения перевода");
      isTransferring = false;
      return;
    }

    // Update card balance
    const { error: balanceError } = await supabase
      .from("bank_cards")
      .update({ balance: fromCard.balance - amount })
      .eq("id", transferForm.from_card);

    if (balanceError) {
      console.error("Error updating balance:", balanceError);
    }

    await Promise.all([loadCards(), loadTransactions()]);
    closeTransferModal();
    transferForm = {
      from_card: "",
      to_account: "",
      amount: "",
      description: "",
    };
    isTransferring = false;
  }

  function closeBorrowModal() {
    isClosingBorrow = true;
    setTimeout(() => {
      showBorrowModal = false;
      isClosingBorrow = false;
    }, 200);
  }

  async function borrowMoney() {
    if (!borrowForm.card_id || !borrowForm.amount) return;

    isBorrowing = true;

    const amount = parseFloat(borrowForm.amount);
    const card = cards.find((c) => c.id === borrowForm.card_id);

    if (!card || card.card_type !== "credit") {
      alert("Займ доступен только для кредитных карт");
      isBorrowing = false;
      return;
    }

    const availableCredit = card.credit_limit - Math.abs(card.balance);
    if (amount > availableCredit) {
      alert(
        `Недостаточно кредитного лимита. Доступно: ${formatCurrency(availableCredit)}`,
      );
      isBorrowing = false;
      return;
    }

    // Create credit transaction
    const { error: transactionError } = await supabase
      .from("transactions")
      .insert([
        {
          user_id: user.id,
          from_card_id: borrowForm.card_id,
          amount: amount,
          transaction_type: "credit",
          description: "Займ с кредитной карты",
          status: "completed",
        },
      ]);

    if (transactionError) {
      console.error("Error creating borrow transaction:", transactionError);
      alert("Ошибка выполнения займа");
      isBorrowing = false;
      return;
    }

    // Update card balance (increase balance for credit cards)
    const newBalance = card.balance + amount;
    const { error: balanceError } = await supabase
      .from("bank_cards")
      .update({ balance: newBalance })
      .eq("id", borrowForm.card_id);

    if (balanceError) {
      console.error("Error updating balance:", balanceError);
    }

    await Promise.all([loadCards(), loadTransactions()]);
    closeBorrowModal();
    borrowForm = { card_id: "", amount: "" };
    isBorrowing = false;
  }

  function openCardManagement(card: any) {
    selectedCard = card;
    showCardManagementModal = true;
  }

  function closeCardManagementModal() {
    isClosingCardManagement = true;
    setTimeout(() => {
      showCardManagementModal = false;
      isClosingCardManagement = false;
    }, 200);
  }

  async function blockCard(cardId: string) {
    const { error } = await supabase
      .from("bank_cards")
      .update({ is_blocked: true })
      .eq("id", cardId);

    if (error) {
      console.error("Error blocking card:", error);
      alert("Ошибка блокировки карты");
    } else {
      await loadCards();
      alert("Карта заблокирована");
    }
  }

  async function unblockCard(cardId: string) {
    const { error } = await supabase
      .from("bank_cards")
      .update({ is_blocked: false })
      .eq("id", cardId);

    if (error) {
      console.error("Error unblocking card:", error);
      alert("Ошибка разблокировки карты");
    } else {
      await loadCards();
      alert("Карта разблокирована");
    }
  }

  async function deactivateCard(cardId: string) {
    if (
      !confirm(
        "Вы уверены, что хотите закрыть карту? Это действие нельзя отменить.",
      )
    ) {
      return;
    }

    const { error } = await supabase
      .from("bank_cards")
      .update({ is_active: false })
      .eq("id", cardId);

    if (error) {
      console.error("Error deactivating card:", error);
      alert("Ошибка закрытия карты");
    } else {
      await loadCards();
      showCardManagementModal = false;
      alert("Карта закрыта");
    }
  }

  async function updateCardName(cardId: string, newName: string) {
    if (!newName.trim()) return;

    const { error } = await supabase
      .from("bank_cards")
      .update({ card_name: newName })
      .eq("id", cardId);

    if (error) {
      console.error("Error updating card name:", error);
      alert("Ошибка изменения названия карты");
    } else {
      await loadCards();
      alert("Название карты изменено");
    }
  }

  async function logout() {
    await supabase.auth.signOut();
    goto("/login");
  }

  function formatCurrency(amount: number) {
    return new Intl.NumberFormat("ru-RU").format(amount) + " МР";
  }

  function formatCardNumber(cardNumber: string) {
    return cardNumber.replace(/(\d{4})(?=\d)/g, "$1 ");
  }

  function getCardColor(cardType: string) {
    switch (cardType) {
      case "credit":
        return "from-purple-500 to-pink-500";
      case "debit":
        return "from-blue-500 to-indigo-500";
      case "savings":
        return "from-green-500 to-teal-500";
      default:
        return "from-gray-500 to-gray-600";
    }
  }
</script>

<svelte:head>
  <title>Панель управления - Банк Маннру</title>
</svelte:head>

{#if isLoading}
  <div class="min-h-screen bg-gray-50 flex items-center justify-center">
    <div class="text-center">
      <Icon
        icon="mdi:loading"
        class="w-12 h-12 animate-spin text-primary mx-auto mb-4"
      />
      <p class="text-gray-600">Загрузка...</p>
    </div>
  </div>
{:else}
  <div
    class="flex-1 flex flex-col w-full px-4 sm:px-6 lg:px-8 py-4 bg-gradient-to-br from-gray-50 via-blue-50/30 to-purple-50/20"
  >
      <!-- Stats Cards -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-2 mb-3 flex-shrink-0">
        <div
          class="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow duration-300 p-2 border border-gray-100"
        >
          <div class="flex items-center justify-between">
            <div>
              <p class="text-xs font-medium text-gray-600">Общий баланс</p>
              <p class="text-base md:text-lg font-light text-gray-900">
                {formatCurrency(totalBalance)}
              </p>
            </div>
            <div
              class="w-8 h-8 bg-gradient-to-br from-blue-400 to-blue-600 rounded-lg flex items-center justify-center shadow-md"
            >
              <Icon icon="mdi:wallet" class="w-4 h-4 text-white" />
            </div>
          </div>
        </div>

        <div
          class="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow duration-300 p-2 border border-gray-100"
        >
          <div class="flex items-center justify-between">
            <div>
              <p class="text-xs font-medium text-gray-600">Доходы за месяц</p>
              <p class="text-base md:text-lg font-light text-green-600">
                {formatCurrency(monthlyIncome)}
              </p>
            </div>
            <div
              class="w-8 h-8 bg-gradient-to-br from-green-400 to-green-600 rounded-lg flex items-center justify-center shadow-md"
            >
              <Icon icon="mdi:arrow-up" class="w-4 h-4 text-white" />
            </div>
          </div>
        </div>

        <div
          class="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow duration-300 p-2 border border-gray-100"
        >
          <div class="flex items-center justify-between">
            <div>
              <p class="text-xs font-medium text-gray-600">Расходы за месяц</p>
              <p class="text-base md:text-lg font-light text-red-600">
                {formatCurrency(monthlyExpenses)}
              </p>
            </div>
            <div
              class="w-8 h-8 bg-gradient-to-br from-red-400 to-red-600 rounded-lg flex items-center justify-center shadow-md"
            >
              <Icon icon="mdi:arrow-down" class="w-4 h-4 text-white" />
            </div>
          </div>
        </div>
      </div>

      <!-- Action Buttons -->
      <div
        class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2 mb-4 flex-shrink-0"
      >
        <button
          on:click={() => (showCreateCardModal = true)}
          class="btn btn-primary btn-sm justify-start shadow-md hover:shadow-lg transition-shadow"
        >
          <Icon icon="mdi:credit-card-plus" class="w-4 h-4" />
          <span class="ml-2">Заказать карту</span>
        </button>
        <button
          on:click={() => (showTransferModal = true)}
          class="btn btn-outline btn-sm justify-start shadow-sm hover:shadow-md transition-shadow"
          disabled={cards.length === 0}
        >
          <Icon icon="mdi:bank-transfer" class="w-4 h-4" />
          <span class="ml-2">Перевод</span>
        </button>
        <button
          on:click={() => (showBorrowModal = true)}
          class="btn btn-accent btn-sm justify-start shadow-md hover:shadow-lg transition-shadow"
          disabled={!cards.some((c) => c.card_type === "credit")}
        >
          <Icon icon="mdi:cash-plus" class="w-4 h-4" />
          <span class="ml-2">Взять в долг</span>
        </button>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-4 flex-1 min-h-0">
        <!-- Cards Section -->
        <div
          class="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow duration-300 border border-gray-100 flex flex-col"
        >
          <div
            class="p-3 border-b border-gray-200 bg-gradient-to-r from-gray-50 to-white flex-shrink-0"
          >
            <h2 class="text-sm font-semibold text-gray-900 flex items-center">
              <Icon
                icon="mdi:credit-card-multiple"
                class="w-4 h-4 mr-2 text-primary"
              />
              Мои карты
            </h2>
          </div>
          <div class="p-3 overflow-y-auto flex-1">
            {#if cards.length === 0}
              <div class="text-center py-4">
                <Icon
                  icon="mdi:credit-card-off"
                  class="w-12 h-12 text-gray-300 mx-auto mb-3"
                />
                <p class="text-sm text-gray-500 mb-3">У вас пока нет карт</p>
                <button
                  on:click={() => (showCreateCardModal = true)}
                  class="btn btn-primary btn-sm shadow-md hover:shadow-lg transition-all"
                >
                  Заказать первую карту
                </button>
              </div>
            {:else}
              <div class="space-y-1">
                {#each cards as card}
                  <div
                    class="bg-gradient-to-r {getCardColor(
                      card.card_type,
                    )} rounded-lg p-3 text-white relative shadow-md hover:shadow-xl transition-shadow duration-300"
                  >
                    <!-- Card Status Indicator -->
                    {#if card.is_blocked}
                      <div
                        class="absolute top-2 right-2 bg-red-500/90 backdrop-blur-sm text-white px-1.5 py-0.5 rounded-full text-xs font-medium shadow-md"
                      >
                        Заблокирована
                      </div>
                    {:else if !card.is_active}
                      <div
                        class="absolute top-2 right-2 bg-gray-500/90 backdrop-blur-sm text-white px-1.5 py-0.5 rounded-full text-xs font-medium shadow-md"
                      >
                        Закрыта
                      </div>
                    {/if}

                    <div class="flex justify-between items-start mb-2">
                      <div>
                        <p class="text-xs opacity-80">{card.card_name}</p>
                        <p class="text-xs opacity-60 uppercase">
                          {card.card_type} • {card.currency}
                        </p>
                      </div>
                      <div class="flex items-center space-x-1">
                        <Icon
                          icon="mdi:credit-card"
                          class="w-5 h-5 opacity-80"
                        />
                        <button
                          on:click={() => openCardManagement(card)}
                          class="bg-white/20 hover:bg-white/40 p-1 rounded-md transition-colors backdrop-blur-sm"
                          title="Управление картой"
                        >
                          <Icon icon="mdi:cog" class="w-3 h-3" />
                        </button>
                      </div>
                    </div>
                    <div class="mb-2">
                      <p class="text-lg font-light">
                        {formatCurrency(card.balance)}
                      </p>
                      {#if card.credit_limit}
                        <p class="text-xs opacity-60">
                          Лимит: {formatCurrency(card.credit_limit)}
                        </p>
                        <p class="text-xs opacity-60">
                          Доступно: {formatCurrency(
                            card.credit_limit - Math.abs(card.balance),
                          )}
                        </p>
                      {/if}
                    </div>
                    <div class="flex justify-between items-end">
                      <p class="font-mono text-xs">
                        {formatCardNumber(card.card_number)}
                      </p>
                      <p class="text-xs opacity-60">
                        {new Date(card.expiry_date).toLocaleDateString(
                          "ru-RU",
                          { month: "2-digit", year: "2-digit" },
                        )}
                      </p>
                    </div>
                  </div>
                {/each}
              </div>
            {/if}
          </div>
        </div>

        <!-- Transactions Section -->
        <div
          class="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow duration-300 border border-gray-100 flex flex-col"
        >
          <div
            class="p-3 border-b border-gray-200 bg-gradient-to-r from-gray-50 to-white flex-shrink-0"
          >
            <h2 class="text-sm font-semibold text-gray-900 flex items-center">
              <Icon icon="mdi:history" class="w-4 h-4 mr-2 text-primary" />
              Последние операции
            </h2>
          </div>
          <div class="p-3 overflow-y-auto flex-1">
            {#if transactions.length === 0}
              <div class="text-center py-4">
                <Icon
                  icon="mdi:history"
                  class="w-12 h-12 text-gray-300 mx-auto mb-3"
                />
                <p class="text-sm text-gray-500">Операций пока нет</p>
              </div>
            {:else}
              <div class="space-y-1">
                {#each transactions as transaction}
                  <div
                    class="flex items-center justify-between p-2 border border-gray-200 rounded-lg hover:shadow-sm transition-shadow duration-300 hover:border-primary/30 bg-white"
                  >
                    <div class="flex items-center space-x-3">
                      <div
                        class="w-8 h-8 bg-gradient-to-br {transaction.transaction_type ===
                        'credit'
                          ? 'from-green-400 to-green-600'
                          : 'from-red-400 to-red-600'} rounded-lg flex items-center justify-center shadow-sm"
                      >
                        <Icon
                          icon={transaction.transaction_type === "credit"
                            ? "mdi:arrow-down-bold"
                            : "mdi:arrow-up-bold"}
                          class="w-4 h-4 text-white"
                        />
                      </div>
                      <div>
                        <p class="text-xs font-medium text-gray-900">
                          {transaction.description}
                        </p>
                        <p class="text-[11px] text-gray-500">
                          {new Date(transaction.created_at).toLocaleDateString(
                            "ru-RU",
                          )} •
                          {transaction.from_card?.card_name ||
                            "Неизвестная карта"}
                        </p>
                      </div>
                    </div>
                    <div class="text-right">
                      <p
                        class="text-sm font-medium {transaction.transaction_type ===
                        'credit'
                          ? 'text-green-600'
                          : 'text-red-600'}"
                      >
                        {transaction.transaction_type === "credit"
                          ? "+"
                          : "-"}{formatCurrency(transaction.amount)}
                      </p>
                      <p class="text-xs text-gray-500 capitalize">
                        {transaction.status}
                      </p>
                    </div>
                  </div>
                {/each}
              </div>
            {/if}
          </div>
        </div>
      </div>
    </div>
{/if}

<!-- Create Card Modal -->
{#if showCreateCardModal}
  <div
    class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 {isClosingCreateCard
      ? 'animate-out fade-out duration-200'
      : 'animate-in fade-in duration-200'}"
  >
    <div
      class="modal-container bg-white rounded-lg w-full max-w-md max-h-[90vh] overflow-y-auto p-5 {isClosingCreateCard
        ? 'animate-out zoom-out-95 duration-200 slide-out-to-bottom-4'
        : 'animate-in zoom-in-95 duration-200 slide-in-from-bottom-4'} m-4"
    >
      <h3 class="text-lg font-light text-gray-900 mb-4">
        Заказать новую карту
      </h3>

      <form on:submit|preventDefault={createCard} class="space-y-4">
        <div class="form-control">
          <label class="label" for="card-name">
            <span class="label-text font-medium text-gray-700"
              >Название карты</span
            >
          </label>
          <input
            type="text"
            id="card-name"
            bind:value={createCardForm.card_name}
            placeholder="Например: Основная карта"
            class="input input-bordered bg-gray-50 focus:bg-white focus:border-primary transition-colors"
            required
          />
        </div>

        <div class="form-control">
          <label class="label" for="card-type">
            <span class="label-text font-medium text-gray-700">Тип карты</span>
          </label>
          <select
            id="card-type"
            bind:value={createCardForm.card_type}
            class="select select-bordered bg-gray-50 focus:bg-white focus:border-primary transition-colors"
          >
            <option value="debit">Дебетовая</option>
            <option value="credit">Кредитная</option>
            <option value="savings">Накопительная</option>
          </select>
        </div>

        <div class="form-control">
          <label class="label" for="card-currency">
            <span class="label-text font-medium text-gray-700">Валюта</span>
          </label>
          <select
            id="card-currency"
            bind:value={createCardForm.currency}
            class="select select-bordered bg-gray-50 focus:bg-white focus:border-primary transition-colors"
          >
            <option value="МР">Маннрубли (МР)</option>
          </select>
        </div>

        <div
          class="flex justify-end space-x-2 mt-6 pt-4 border-t border-gray-100"
        >
          <button
            type="button"
            on:click={closeCreateCardModal}
            class="btn btn-ghost btn-sm"
            disabled={isCreatingCard}
          >
            Отмена
          </button>
          <button
            type="submit"
            class="btn btn-primary btn-sm"
            disabled={isCreatingCard}
          >
            {#if isCreatingCard}
              <Icon icon="mdi:loading" class="w-4 h-4 animate-spin" />
              Создание...
            {:else}
              <Icon icon="mdi:credit-card-plus" class="w-4 h-4" />
              Заказать карту
            {/if}
          </button>
        </div>
      </form>
    </div>
  </div>
{/if}

<!-- Transfer Modal -->
{#if showTransferModal}
  <div
    class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 {isClosingTransfer
      ? 'animate-out fade-out duration-200'
      : 'animate-in fade-in duration-200'}"
  >
    <div
      class="modal-container bg-white rounded-lg w-full max-w-md max-h-[90vh] overflow-y-auto p-5 {isClosingTransfer
        ? 'animate-out zoom-out-95 duration-200 slide-out-to-bottom-4'
        : 'animate-in zoom-in-95 duration-200 slide-in-from-bottom-4'} m-4"
    >
      <h3 class="text-lg font-light text-gray-900 mb-4">Перевод средств</h3>

      <form on:submit|preventDefault={makeTransfer} class="space-y-4">
        <div class="form-control">
          <label class="label" for="transfer-from-card">
            <span class="label-text font-medium text-gray-700"
              >Карта списания</span
            >
          </label>
          <select
            id="transfer-from-card"
            bind:value={transferForm.from_card}
            class="select select-bordered bg-gray-50 focus:bg-white focus:border-primary transition-colors"
            required
          >
            <option value="">Выберите карту</option>
            {#each cards as card}
              <option value={card.id}>
                {card.card_name} - {formatCurrency(card.balance)}
              </option>
            {/each}
          </select>
        </div>

        <div class="form-control">
          <label class="label" for="transfer-to-account">
            <span class="label-text font-medium text-gray-700"
              >Номер счета получателя</span
            >
          </label>
          <input
            type="text"
            id="transfer-to-account"
            bind:value={transferForm.to_account}
            placeholder="1234567890123456"
            class="input input-bordered bg-gray-50 focus:bg-white focus:border-primary transition-colors"
            required
          />
        </div>

        <div class="form-control">
          <label class="label" for="transfer-amount">
            <span class="label-text font-medium text-gray-700">Сумма</span>
          </label>
          <input
            type="number"
            id="transfer-amount"
            bind:value={transferForm.amount}
            placeholder="0"
            min="1"
            step="1"
            class="input input-bordered bg-gray-50 focus:bg-white focus:border-primary transition-colors"
            required
          />
          <label class="label">
            <span class="label-text-alt text-gray-500">В маннрублях (МР)</span>
          </label>
        </div>

        <div class="form-control">
          <label class="label" for="transfer-description">
            <span class="label-text font-medium text-gray-700"
              >Описание (необязательно)</span
            >
          </label>
          <input
            type="text"
            id="transfer-description"
            bind:value={transferForm.description}
            placeholder="Назначение платежа"
            class="input input-bordered bg-gray-50 focus:bg-white focus:border-primary transition-colors"
          />
        </div>

        <div
          class="flex justify-end space-x-2 mt-6 pt-4 border-t border-gray-100"
        >
          <button
            type="button"
            on:click={closeTransferModal}
            class="btn btn-ghost btn-sm"
            disabled={isTransferring}
          >
            Отмена
          </button>
          <button
            type="submit"
            class="btn btn-primary btn-sm"
            disabled={isTransferring}
          >
            {#if isTransferring}
              <Icon icon="mdi:loading" class="w-4 h-4 animate-spin" />
              Отправка...
            {:else}
              <Icon icon="mdi:bank-transfer" class="w-4 h-4" />
              Выполнить перевод
            {/if}
          </button>
        </div>
      </form>
    </div>
  </div>
{/if}

<!-- Borrow Money Modal -->
{#if showBorrowModal}
  <div
    class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 {isClosingBorrow
      ? 'animate-out fade-out duration-200'
      : 'animate-in fade-in duration-200'}"
  >
    <div
      class="modal-container bg-white rounded-lg w-full max-w-md max-h-[90vh] overflow-y-auto p-5 {isClosingBorrow
        ? 'animate-out zoom-out-95 duration-200 slide-out-to-bottom-4'
        : 'animate-in zoom-in-95 duration-200 slide-in-from-bottom-4'} m-4"
    >
      <h3 class="text-lg font-light text-gray-900 mb-4">Взять в долг</h3>

      <form on:submit|preventDefault={borrowMoney} class="space-y-4">
        <div class="form-control">
          <label class="label" for="borrow-card">
            <span class="label-text font-medium text-gray-700"
              >Кредитная карта</span
            >
          </label>
          <select
            id="borrow-card"
            bind:value={borrowForm.card_id}
            class="select select-bordered bg-gray-50 focus:bg-white focus:border-primary transition-colors"
            required
          >
            <option value="">Выберите кредитную карту</option>
            {#each cards.filter((c) => c.card_type === "credit") as card}
              <option value={card.id}>
                {card.card_name} - Доступно: {formatCurrency(
                  card.credit_limit - Math.abs(card.balance),
                )}
              </option>
            {/each}
          </select>
        </div>

        <div class="form-control">
          <label class="label" for="borrow-amount">
            <span class="label-text font-medium text-gray-700">Сумма займа</span
            >
          </label>
          <input
            type="number"
            id="borrow-amount"
            bind:value={borrowForm.amount}
            placeholder="0"
            min="1"
            step="1"
            class="input input-bordered bg-gray-50 focus:bg-white focus:border-primary transition-colors"
            required
          />
          <label class="label">
            <span class="label-text-alt text-gray-500"
              >Средства поступят на баланс карты</span
            >
          </label>
        </div>

        <div class="bg-blue-50 p-3 rounded-lg">
          <div class="flex items-start space-x-3">
            <Icon icon="mdi:information" class="w-5 h-5 text-blue-600 mt-0.5" />
            <div class="text-sm">
              <p class="font-medium text-blue-900 mb-1">Условия займа</p>
              <p class="text-blue-700">
                • Займ доступен в рамках кредитного лимита<br />
                • Ставка: 19.9% годовых<br />
                • Льготный период: 55 дней
              </p>
            </div>
          </div>
        </div>

        <div
          class="flex justify-end space-x-2 mt-6 pt-4 border-t border-gray-100"
        >
          <button
            type="button"
            on:click={closeBorrowModal}
            class="btn btn-ghost btn-sm"
            disabled={isBorrowing}
          >
            Отмена
          </button>
          <button
            type="submit"
            class="btn btn-accent btn-sm"
            disabled={isBorrowing}
          >
            {#if isBorrowing}
              <Icon icon="mdi:loading" class="w-4 h-4 animate-spin" />
              Оформление...
            {:else}
              <Icon icon="mdi:cash-plus" class="w-4 h-4" />
              Взять займ
            {/if}
          </button>
        </div>
      </form>
    </div>
  </div>
{/if}

<!-- Card Management Modal -->
{#if showCardManagementModal && selectedCard}
  <div
    class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 {isClosingCardManagement
      ? 'animate-out fade-out duration-200'
      : 'animate-in fade-in duration-200'}"
  >
    <div
      class="modal-container bg-white rounded-lg w-full max-w-md max-h-[90vh] overflow-y-auto p-5 {isClosingCardManagement
        ? 'animate-out zoom-out-95 duration-200 slide-out-to-bottom-4'
        : 'animate-in zoom-in-95 duration-200 slide-in-from-bottom-4'} m-4"
    >
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-lg font-light text-gray-900">Управление картой</h3>
        <button
          on:click={closeCardManagementModal}
          class="text-gray-400 hover:text-gray-600"
        >
          <Icon icon="mdi:close" class="w-6 h-6" />
        </button>
      </div>

      <!-- Card Preview -->
      <div
        class="bg-gradient-to-r {getCardColor(
          selectedCard.card_type,
        )} rounded-xl p-4 text-white mb-6"
      >
        <div class="flex justify-between items-start mb-3">
          <div>
            <p class="text-sm opacity-80">{selectedCard.card_name}</p>
            <p class="text-xs opacity-60 uppercase">
              {selectedCard.card_type} • {selectedCard.currency}
            </p>
          </div>
          <Icon icon="mdi:credit-card" class="w-6 h-6 opacity-80" />
        </div>
        <p class="text-lg font-light">{formatCurrency(selectedCard.balance)}</p>
        <p class="font-mono text-xs mt-2">
          {formatCardNumber(selectedCard.card_number)}
        </p>
      </div>

      <!-- Card Status -->
      <div class="mb-6">
        <div
          class="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
        >
          <div class="flex items-center space-x-3">
            <Icon
              icon={selectedCard.is_blocked
                ? "mdi:lock"
                : selectedCard.is_active
                  ? "mdi:check-circle"
                  : "mdi:close-circle"}
              class="w-5 h-5 {selectedCard.is_blocked
                ? 'text-red-500'
                : selectedCard.is_active
                  ? 'text-green-500'
                  : 'text-gray-500'}"
            />
            <span class="font-medium">
              {selectedCard.is_blocked
                ? "Заблокирована"
                : selectedCard.is_active
                  ? "Активна"
                  : "Закрыта"}
            </span>
          </div>
          {#if selectedCard.is_active}
            {#if selectedCard.is_blocked}
              <button
                on:click={() => unblockCard(selectedCard.id)}
                class="btn btn-sm btn-success"
              >
                Разблокировать
              </button>
            {:else}
              <button
                on:click={() => blockCard(selectedCard.id)}
                class="btn btn-sm btn-warning"
              >
                Заблокировать
              </button>
            {/if}
          {/if}
        </div>
      </div>

      <!-- Management Actions -->
      <div class="space-y-4">
        <!-- Rename Card -->
        <div class="form-control">
          <label class="label" for="card-rename">
            <span class="label-text font-medium text-gray-700"
              >Изменить название карты</span
            >
          </label>
          <input
            type="text"
            id="card-rename"
            value={selectedCard.card_name}
            on:change={(e) =>
              updateCardName(
                selectedCard.id,
                (e.target as HTMLInputElement).value,
              )}
            class="input input-bordered bg-gray-50 focus:bg-white focus:border-primary transition-colors"
            placeholder="Название карты"
          />
        </div>

        <!-- Card Details -->
        <div class="grid grid-cols-2 gap-4 text-sm">
          <div>
            <p class="text-gray-500">Номер карты</p>
            <p class="font-mono">
              {formatCardNumber(selectedCard.card_number)}
            </p>
          </div>
          <div>
            <p class="text-gray-500">Срок действия</p>
            <p>
              {new Date(selectedCard.expiry_date).toLocaleDateString("ru-RU", {
                month: "2-digit",
                year: "2-digit",
              })}
            </p>
          </div>
          <div>
            <p class="text-gray-500">Баланс</p>
            <p class="font-medium">{formatCurrency(selectedCard.balance)}</p>
          </div>
          {#if selectedCard.credit_limit}
            <div>
              <p class="text-gray-500">Кредитный лимит</p>
              <p class="font-medium">
                {formatCurrency(selectedCard.credit_limit)}
              </p>
            </div>
          {/if}
        </div>

        <!-- Danger Zone -->
        {#if selectedCard.is_active}
          <div class="border-t pt-4">
            <h4 class="text-sm font-medium text-red-600 mb-3">Опасная зона</h4>
            <button
              on:click={() => deactivateCard(selectedCard.id)}
              class="btn btn-error btn-sm w-full"
            >
              <Icon icon="mdi:close-circle" class="w-4 h-4" />
              Закрыть карту
            </button>
            <p class="text-xs text-gray-500 mt-2">
              После закрытия карту нельзя будет восстановить
            </p>
          </div>
        {/if}
      </div>

      <div class="flex justify-end mt-6 pt-4 border-t border-gray-100">
        <button
          on:click={closeCardManagementModal}
          class="btn btn-primary btn-sm"
        >
          <Icon icon="mdi:check" class="w-4 h-4" />
          Готово
        </button>
      </div>
    </div>
  </div>
{/if}
