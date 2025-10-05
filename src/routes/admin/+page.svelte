<script lang="ts">
  import Icon from "@iconify/svelte";
  import { onMount } from "svelte";
  import { goto } from "$app/navigation";
  import { supabase, adminService, bankService } from "$lib/supabase";

  let user: any = null;
  let isAdmin = false;
  let adminRole = "";
  let isLoading = true;
  let activeTab = "dashboard";

  // Data
  let settings: any[] = [];
  let pendingApprovals: any[] = [];
  let allUsers: any[] = [];
  let allCards: any[] = [];

  // Loading states
  let loadingSettings = false;
  let loadingApprovals = false;
  let loadingUsers = false;
  let loadingCards = false;

  // Modal states
  let showRejectModal = false;
  let selectedApproval: any = null;
  let rejectReason = "";
  let isRejecting = false;

  let showCardModal = false;
  let selectedCard: any = null;
  let cardUpdates = { balance: 0, status: "", credit_limit: 0 };
  let isUpdatingCard = false;

  onMount(async () => {
    await checkAuth();
    if (isAdmin) {
      await loadDashboardData();
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
    const { isAdmin: userIsAdmin, role } = await adminService.isAdmin(user.id);
    if (!userIsAdmin) {
      goto("/dashboard");
      return;
    }

    isAdmin = userIsAdmin;
    adminRole = role;
  }

  async function loadDashboardData() {
    await Promise.all([
      loadSettings(),
      loadPendingApprovals(),
      loadUsers(),
      loadCards(),
    ]);
  }

  async function loadSettings() {
    loadingSettings = true;
    try {
      const { data, error } = await adminService.getSettings();
      if (!error) {
        settings = data || [];
      }
    } catch (error) {
      console.error("Error loading settings:", error);
    } finally {
      loadingSettings = false;
    }
  }

  async function loadPendingApprovals() {
    loadingApprovals = true;
    try {
      const { data, error } = await adminService.getPendingApprovals();
      if (!error) {
        pendingApprovals = data || [];
      }
    } catch (error) {
      console.error("Error loading approvals:", error);
    } finally {
      loadingApprovals = false;
    }
  }

  async function loadUsers() {
    loadingUsers = true;
    try {
      const { data, error } = await adminService.getAllUsers();
      if (!error) {
        allUsers = data || [];
      }
    } catch (error) {
      console.error("Error loading users:", error);
    } finally {
      loadingUsers = false;
    }
  }

  async function loadCards() {
    loadingCards = true;
    try {
      const { data, error } = await adminService.getAllCards();
      if (!error) {
        allCards = data || [];
      }
    } catch (error) {
      console.error("Error loading cards:", error);
    } finally {
      loadingCards = false;
    }
  }

  async function updateSetting(settingKey: string, value: boolean) {
    try {
      const { error } = await adminService.updateSetting(settingKey, value);
      if (!error) {
        await loadSettings();
      }
    } catch (error) {
      console.error("Error updating setting:", error);
    }
  }

  async function approveUser(approvalId: string) {
    try {
      const { error } = await adminService.approveUser(approvalId, user.id);
      if (!error) {
        await loadPendingApprovals();
      }
    } catch (error) {
      console.error("Error approving user:", error);
    }
  }

  function openRejectModal(approval: any) {
    selectedApproval = approval;
    rejectReason = "";
    showRejectModal = true;
  }

  async function rejectUser() {
    if (!selectedApproval || !rejectReason.trim()) return;

    isRejecting = true;
    try {
      const { error } = await adminService.rejectUser(
        selectedApproval.id,
        user.id,
        rejectReason,
      );
      if (!error) {
        showRejectModal = false;
        await loadPendingApprovals();
      }
    } catch (error) {
      console.error("Error rejecting user:", error);
    } finally {
      isRejecting = false;
    }
  }

  function openCardModal(card: any) {
    selectedCard = card;
    cardUpdates = {
      balance: card.balance,
      status: card.status,
      credit_limit: card.credit_limit || 0,
    };
    showCardModal = true;
  }

  async function updateCard() {
    if (!selectedCard) return;

    isUpdatingCard = true;
    try {
      const { error } = await adminService.adminUpdateCard(
        selectedCard.id,
        cardUpdates,
      );
      if (!error) {
        showCardModal = false;
        await loadCards();
      }
    } catch (error) {
      console.error("Error updating card:", error);
    } finally {
      isUpdatingCard = false;
    }
  }

  async function deleteCard(cardId: string) {
    if (!confirm("Вы уверены, что хотите удалить эту карту?")) return;

    try {
      const { error } = await adminService.adminDeleteCard(cardId);
      if (!error) {
        await loadCards();
      }
    } catch (error) {
      console.error("Error deleting card:", error);
    }
  }

  async function signOut() {
    await supabase.auth.signOut();
    goto("/");
  }

  function formatCurrency(amount: number) {
    return new Intl.NumberFormat("ru-RU").format(amount) + " МР";
  }

  function getStatusBadge(status: string) {
    switch (status) {
      case "active":
        return "badge-success";
      case "blocked":
        return "badge-error";
      case "closed":
        return "badge-neutral";
      default:
        return "badge-ghost";
    }
  }
</script>

<svelte:head>
  <title>Админ панель - Банк Маннру</title>
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
{:else if !isAdmin}
  <div class="min-h-screen bg-gray-50 flex items-center justify-center">
    <div class="text-center">
      <Icon
        icon="mdi:shield-alert"
        class="w-16 h-16 text-red-500 mx-auto mb-4"
      />
      <h1 class="text-2xl font-bold text-gray-900 mb-2">Доступ запрещен</h1>
      <p class="text-gray-600">У вас нет прав администратора</p>
    </div>
  </div>
{:else}
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <nav class="sticky top-0 z-40 bg-white shadow-sm border-b">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex items-center">
            <Icon icon="mdi:shield-crown" class="w-8 h-8 text-primary mr-3" />
            <h1 class="text-2xl font-light text-primary tracking-tight">
              Админ панель
            </h1>
            <span
              class="ml-3 text-sm text-gray-500 bg-gray-100 px-2 py-1 rounded"
            >
              {adminRole === "super_admin" ? "Супер админ" : "Админ"}
            </span>
          </div>
          <div class="flex items-center space-x-4">
            <span class="text-sm text-gray-600">
              {user?.user_metadata?.first_name || user?.email}
            </span>
            <a href="/dashboard" class="btn btn-ghost btn-sm">
              <Icon icon="mdi:view-dashboard" class="w-4 h-4 mr-1" />
              Панель пользователя
            </a>
            <button on:click={signOut} class="btn btn-ghost btn-sm">
              <Icon icon="mdi:logout" class="w-4 h-4 mr-1" />
              Выйти
            </button>
          </div>
        </div>
      </div>
    </nav>

    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Tabs -->
      <div class="tabs tabs-bordered mb-8">
        <button
          class="tab {activeTab === 'dashboard' ? 'tab-active' : ''}"
          on:click={() => (activeTab = "dashboard")}
        >
          <Icon icon="mdi:view-dashboard" class="w-4 h-4 mr-2" />
          Обзор
        </button>
        <button
          class="tab {activeTab === 'settings' ? 'tab-active' : ''}"
          on:click={() => (activeTab = "settings")}
        >
          <Icon icon="mdi:cog" class="w-4 h-4 mr-2" />
          Настройки
        </button>
        <button
          class="tab {activeTab === 'approvals' ? 'tab-active' : ''}"
          on:click={() => (activeTab = "approvals")}
        >
          <Icon icon="mdi:account-clock" class="w-4 h-4 mr-2" />
          Заявки ({pendingApprovals.length})
        </button>
        <button
          class="tab {activeTab === 'users' ? 'tab-active' : ''}"
          on:click={() => (activeTab = "users")}
        >
          <Icon icon="mdi:account-group" class="w-4 h-4 mr-2" />
          Пользователи
        </button>
        <button
          class="tab {activeTab === 'cards' ? 'tab-active' : ''}"
          on:click={() => (activeTab = "cards")}
        >
          <Icon icon="mdi:credit-card-multiple" class="w-4 h-4 mr-2" />
          Карты
        </button>
      </div>

      <!-- Dashboard Tab -->
      {#if activeTab === "dashboard"}
        <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div class="stat bg-white rounded-lg shadow-sm">
            <div class="stat-figure text-primary">
              <Icon icon="mdi:account-clock" class="w-8 h-8" />
            </div>
            <div class="stat-title">Ожидают одобрения</div>
            <div class="stat-value text-primary">{pendingApprovals.length}</div>
          </div>
          <div class="stat bg-white rounded-lg shadow-sm">
            <div class="stat-figure text-secondary">
              <Icon icon="mdi:account-group" class="w-8 h-8" />
            </div>
            <div class="stat-title">Всего пользователей</div>
            <div class="stat-value text-secondary">{allUsers.length}</div>
          </div>
          <div class="stat bg-white rounded-lg shadow-sm">
            <div class="stat-figure text-accent">
              <Icon icon="mdi:credit-card-multiple" class="w-8 h-8" />
            </div>
            <div class="stat-title">Всего карт</div>
            <div class="stat-value text-accent">{allCards.length}</div>
          </div>
          <div class="stat bg-white rounded-lg shadow-sm">
            <div class="stat-figure text-info">
              <Icon icon="mdi:credit-card-check" class="w-8 h-8" />
            </div>
            <div class="stat-title">Активные карты</div>
            <div class="stat-value text-info">
              {allCards.filter((card) => card.status === "active").length}
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <!-- Recent Approvals -->
          <div class="bg-white rounded-lg shadow-sm p-6">
            <h3 class="text-lg font-medium text-gray-900 mb-4">
              <Icon icon="mdi:account-clock" class="w-5 h-5 inline mr-2" />
              Последние заявки
            </h3>
            {#if pendingApprovals.length === 0}
              <p class="text-gray-500 text-center py-4">Нет ожидающих заявок</p>
            {:else}
              <div class="space-y-3">
                {#each pendingApprovals.slice(0, 5) as approval}
                  <div
                    class="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                  >
                    <div>
                      <p class="font-medium text-gray-900">
                        {approval.first_name}
                        {approval.last_name}
                      </p>
                      <p class="text-sm text-gray-500">{approval.email}</p>
                    </div>
                    <div class="flex space-x-2">
                      <button
                        on:click={() => approveUser(approval.id)}
                        class="btn btn-success btn-sm"
                      >
                        <Icon icon="mdi:check" class="w-4 h-4" />
                      </button>
                      <button
                        on:click={() => openRejectModal(approval)}
                        class="btn btn-error btn-sm"
                      >
                        <Icon icon="mdi:close" class="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                {/each}
              </div>
            {/if}
          </div>

          <!-- System Settings -->
          <div class="bg-white rounded-lg shadow-sm p-6">
            <h3 class="text-lg font-medium text-gray-900 mb-4">
              <Icon icon="mdi:cog" class="w-5 h-5 inline mr-2" />
              Системные настройки
            </h3>
            <div class="space-y-4">
              {#each settings as setting}
                <div class="flex items-center justify-between">
                  <div>
                    <p class="font-medium text-gray-900">
                      {setting.description}
                    </p>
                    <p class="text-sm text-gray-500">{setting.setting_key}</p>
                  </div>
                  <input
                    type="checkbox"
                    class="toggle toggle-primary"
                    checked={setting.setting_value}
                    on:change={(e) =>
                      updateSetting(setting.setting_key, e.target.checked)}
                  />
                </div>
              {/each}
            </div>
          </div>
        </div>
      {/if}

      <!-- Settings Tab -->
      {#if activeTab === "settings"}
        <div class="bg-white rounded-lg shadow-sm p-6">
          <h2 class="text-xl font-light text-gray-900 mb-6">
            Настройки системы
          </h2>
          {#if loadingSettings}
            <div class="text-center py-8">
              <Icon
                icon="mdi:loading"
                class="w-8 h-8 animate-spin text-primary mx-auto mb-2"
              />
              <p class="text-gray-500">Загрузка настроек...</p>
            </div>
          {:else}
            <div class="space-y-6">
              {#each settings as setting}
                <div
                  class="flex items-start justify-between p-4 border border-gray-200 rounded-lg"
                >
                  <div class="flex-1">
                    <h3 class="font-medium text-gray-900 mb-1">
                      {setting.description}
                    </h3>
                    <p class="text-sm text-gray-500 mb-2">
                      Ключ: <code class="bg-gray-100 px-1 rounded"
                        >{setting.setting_key}</code
                      >
                    </p>
                    <p class="text-xs text-gray-400">
                      Обновлено: {new Date(setting.updated_at).toLocaleString(
                        "ru-RU",
                      )}
                    </p>
                  </div>
                  <div class="ml-4">
                    <input
                      type="checkbox"
                      class="toggle toggle-primary toggle-lg"
                      checked={setting.setting_value}
                      on:change={(e) =>
                        updateSetting(setting.setting_key, e.target.checked)}
                    />
                  </div>
                </div>
              {/each}
            </div>
          {/if}
        </div>
      {/if}

      <!-- Approvals Tab -->
      {#if activeTab === "approvals"}
        <div class="bg-white rounded-lg shadow-sm">
          <div class="p-6 border-b border-gray-200">
            <h2 class="text-xl font-light text-gray-900">
              Заявки на регистрацию
            </h2>
            <p class="text-gray-600 mt-1">
              Управление заявками пользователей на регистрацию
            </p>
          </div>

          {#if loadingApprovals}
            <div class="text-center py-12">
              <Icon
                icon="mdi:loading"
                class="w-8 h-8 animate-spin text-primary mx-auto mb-2"
              />
              <p class="text-gray-500">Загрузка заявок...</p>
            </div>
          {:else if pendingApprovals.length === 0}
            <div class="text-center py-12">
              <Icon
                icon="mdi:check-circle"
                class="w-12 h-12 text-green-500 mx-auto mb-4"
              />
              <p class="text-gray-500">Нет ожидающих заявок</p>
            </div>
          {:else}
            <div class="overflow-x-auto">
              <table class="table table-zebra w-full">
                <thead>
                  <tr>
                    <th>Пользователь</th>
                    <th>Email</th>
                    <th>Телефон</th>
                    <th>Дата подачи</th>
                    <th>Действия</th>
                  </tr>
                </thead>
                <tbody>
                  {#each pendingApprovals as approval}
                    <tr>
                      <td>
                        <div class="font-medium">
                          {approval.first_name}
                          {approval.last_name}
                        </div>
                      </td>
                      <td>{approval.email}</td>
                      <td>{approval.phone || "—"}</td>
                      <td
                        >{new Date(approval.created_at).toLocaleDateString(
                          "ru-RU",
                        )}</td
                      >
                      <td>
                        <div class="flex space-x-2">
                          <button
                            on:click={() => approveUser(approval.id)}
                            class="btn btn-success btn-sm"
                            title="Одобрить"
                          >
                            <Icon icon="mdi:check" class="w-4 h-4" />
                          </button>
                          <button
                            on:click={() => openRejectModal(approval)}
                            class="btn btn-error btn-sm"
                            title="Отклонить"
                          >
                            <Icon icon="mdi:close" class="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  {/each}
                </tbody>
              </table>
            </div>
          {/if}
        </div>
      {/if}

      <!-- Users Tab -->
      {#if activeTab === "users"}
        <div class="bg-white rounded-lg shadow-sm">
          <div class="p-6 border-b border-gray-200">
            <h2 class="text-xl font-light text-gray-900">Пользователи</h2>
            <p class="text-gray-600 mt-1">Управление пользователями системы</p>
          </div>

          {#if loadingUsers}
            <div class="text-center py-12">
              <Icon
                icon="mdi:loading"
                class="w-8 h-8 animate-spin text-primary mx-auto mb-2"
              />
              <p class="text-gray-500">Загрузка пользователей...</p>
            </div>
          {:else}
            <div class="overflow-x-auto">
              <table class="table table-zebra w-full">
                <thead>
                  <tr>
                    <th>Пользователь</th>
                    <th>Email</th>
                    <th>Телефон</th>
                    <th>Статус</th>
                    <th>Дата регистрации</th>
                  </tr>
                </thead>
                <tbody>
                  {#each allUsers as user}
                    <tr>
                      <td>
                        <div class="font-medium">
                          {user.first_name}
                          {user.last_name}
                        </div>
                      </td>
                      <td>{user.email}</td>
                      <td>{user.phone || "—"}</td>
                      <td>
                        {#if user.user_approvals?.[0]}
                          <span
                            class="badge {user.user_approvals[0].status ===
                            'approved'
                              ? 'badge-success'
                              : user.user_approvals[0].status === 'rejected'
                                ? 'badge-error'
                                : 'badge-warning'}"
                          >
                            {user.user_approvals[0].status === "approved"
                              ? "Одобрен"
                              : user.user_approvals[0].status === "rejected"
                                ? "Отклонен"
                                : "Ожидает"}
                          </span>
                        {:else}
                          <span class="badge badge-ghost">Активен</span>
                        {/if}
                      </td>
                      <td
                        >{new Date(user.created_at).toLocaleDateString(
                          "ru-RU",
                        )}</td
                      >
                    </tr>
                  {/each}
                </tbody>
              </table>
            </div>
          {/if}
        </div>
      {/if}

      <!-- Cards Tab -->
      {#if activeTab === "cards"}
        <div class="bg-white rounded-lg shadow-sm">
          <div class="p-6 border-b border-gray-200">
            <h2 class="text-xl font-light text-gray-900">Банковские карты</h2>
            <p class="text-gray-600 mt-1">Управление картами пользователей</p>
          </div>

          {#if loadingCards}
            <div class="text-center py-12">
              <Icon
                icon="mdi:loading"
                class="w-8 h-8 animate-spin text-primary mx-auto mb-2"
              />
              <p class="text-gray-500">Загрузка карт...</p>
            </div>
          {:else}
            <div class="overflow-x-auto">
              <table class="table table-zebra w-full">
                <thead>
                  <tr>
                    <th>Карта</th>
                    <th>Владелец</th>
                    <th>Тип</th>
                    <th>Баланс</th>
                    <th>Статус</th>
                    <th>Действия</th>
                  </tr>
                </thead>
                <tbody>
                  {#each allCards as card}
                    <tr>
                      <td>
                        <div>
                          <div class="font-medium">{card.card_name}</div>
                          <div class="text-sm text-gray-500">
                            **** **** **** {card.card_number.slice(-4)}
                          </div>
                        </div>
                      </td>
                      <td>
                        {#if card.user_profiles}
                          <div class="font-medium">
                            {card.user_profiles.first_name}
                            {card.user_profiles.last_name}
                          </div>
                          <div class="text-sm text-gray-500">
                            {card.user_profiles.email}
                          </div>
                        {:else}
                          <span class="text-gray-400">—</span>
                        {/if}
                      </td>
                      <td>
                        <span
                          class="badge {card.card_type === 'credit'
                            ? 'badge-warning'
                            : card.card_type === 'debit'
                              ? 'badge-info'
                              : 'badge-success'}"
                        >
                          {card.card_type === "credit"
                            ? "Кредитная"
                            : card.card_type === "debit"
                              ? "Дебетовая"
                              : "Сберегательная"}
                        </span>
                      </td>
                      <td>
                        <div class="font-medium">
                          {formatCurrency(card.balance)}
                        </div>
                        {#if card.card_type === "credit" && card.credit_limit}
                          <div class="text-xs text-gray-500">
                            Лимит: {formatCurrency(card.credit_limit)}
                          </div>
                        {/if}
                      </td>
                      <td>
                        <span class="badge {getStatusBadge(card.status)}">
                          {card.status === "active"
                            ? "Активна"
                            : card.status === "blocked"
                              ? "Заблокирована"
                              : "Закрыта"}
                        </span>
                      </td>
                      <td>
                        <div class="flex space-x-2">
                          <button
                            on:click={() => openCardModal(card)}
                            class="btn btn-primary btn-sm"
                            title="Редактировать"
                          >
                            <Icon icon="mdi:pencil" class="w-4 h-4" />
                          </button>
                          <button
                            on:click={() => deleteCard(card.id)}
                            class="btn btn-error btn-sm"
                            title="Удалить"
                          >
                            <Icon icon="mdi:delete" class="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  {/each}
                </tbody>
              </table>
            </div>
          {/if}
        </div>
      {/if}
    </div>
  </div>
{/if}

<!-- Reject Modal -->
{#if showRejectModal}
  <div
    class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 animate-in fade-in duration-200"
  >
    <div
      class="modal-container bg-white rounded-lg w-full max-w-md max-h-[90vh] overflow-y-auto p-6 animate-in zoom-in-95 duration-200 slide-in-from-bottom-4 m-4"
    >
      <h3 class="text-xl font-light text-gray-900 mb-6">Отклонить заявку</h3>

      {#if selectedApproval}
        <div class="mb-4 p-3 bg-gray-50 rounded-lg">
          <p class="font-medium">
            {selectedApproval.first_name}
            {selectedApproval.last_name}
          </p>
          <p class="text-sm text-gray-500">{selectedApproval.email}</p>
        </div>
      {/if}

      <div class="form-control mb-6">
        <label class="label" for="reject-reason">
          <span class="label-text font-medium text-gray-700"
            >Причина отклонения</span
          >
        </label>
        <textarea
          id="reject-reason"
          bind:value={rejectReason}
          class="textarea textarea-bordered bg-gray-50 focus:bg-white focus:border-primary transition-colors"
          placeholder="Укажите причину отклонения заявки..."
          rows="3"
          required
        ></textarea>
      </div>

      <div
        class="flex justify-end space-x-3 mt-8 pt-6 border-t border-gray-100"
      >
        <button
          type="button"
          on:click={() => (showRejectModal = false)}
          class="btn btn-ghost"
          disabled={isRejecting}
        >
          Отмена
        </button>
        <button
          on:click={rejectUser}
          class="btn btn-error"
          disabled={isRejecting || !rejectReason.trim()}
        >
          {#if isRejecting}
            <Icon icon="mdi:loading" class="w-4 h-4 animate-spin" />
            Отклонение...
          {:else}
            <Icon icon="mdi:close" class="w-4 h-4" />
            Отклонить
          {/if}
        </button>
      </div>
    </div>
  </div>
{/if}

<!-- Card Edit Modal -->
{#if showCardModal}
  <div
    class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 animate-in fade-in duration-200"
  >
    <div
      class="modal-container bg-white rounded-lg w-full max-w-md max-h-[90vh] overflow-y-auto p-6 animate-in zoom-in-95 duration-200 slide-in-from-bottom-4 m-4"
    >
      <h3 class="text-xl font-light text-gray-900 mb-6">Редактировать карту</h3>

      {#if selectedCard}
        <div
          class="mb-6 p-4 bg-gradient-to-r from-primary to-blue-600 text-white rounded-lg"
        >
          <div class="font-medium">{selectedCard.card_name}</div>
          <div class="text-sm opacity-90">
            **** **** **** {selectedCard.card_number.slice(-4)}
          </div>
        </div>

        <form on:submit|preventDefault={updateCard} class="space-y-5">
          <div class="form-control">
            <label class="label" for="card-balance">
              <span class="label-text font-medium text-gray-700">Баланс</span>
            </label>
            <input
              id="card-balance"
              type="number"
              step="0.01"
              bind:value={cardUpdates.balance}
              class="input input-bordered bg-gray-50 focus:bg-white focus:border-primary transition-colors"
              required
            />
          </div>

          <div class="form-control">
            <label class="label" for="card-status">
              <span class="label-text font-medium text-gray-700">Статус</span>
            </label>
            <select
              id="card-status"
              bind:value={cardUpdates.status}
              class="select select-bordered bg-gray-50 focus:bg-white focus:border-primary transition-colors"
              required
            >
              <option value="active">Активна</option>
              <option value="blocked">Заблокирована</option>
              <option value="closed">Закрыта</option>
            </select>
          </div>

          {#if selectedCard.card_type === "credit"}
            <div class="form-control">
              <label class="label" for="credit-limit">
                <span class="label-text font-medium text-gray-700"
                  >Кредитный лимит</span
                >
              </label>
              <input
                id="credit-limit"
                type="number"
                step="0.01"
                bind:value={cardUpdates.credit_limit}
                class="input input-bordered bg-gray-50 focus:bg-white focus:border-primary transition-colors"
                required
              />
            </div>
          {/if}

          <div
            class="flex justify-end space-x-3 mt-8 pt-6 border-t border-gray-100"
          >
            <button
              type="button"
              on:click={() => (showCardModal = false)}
              class="btn btn-ghost"
              disabled={isUpdatingCard}
            >
              Отмена
            </button>
            <button
              type="submit"
              class="btn btn-primary"
              disabled={isUpdatingCard}
            >
              {#if isUpdatingCard}
                <Icon icon="mdi:loading" class="w-4 h-4 animate-spin" />
                Сохранение...
              {:else}
                <Icon icon="mdi:content-save" class="w-4 h-4" />
                Сохранить
              {/if}
            </button>
          </div>
        </form>
      {/if}
    </div>
  </div>
{/if}
