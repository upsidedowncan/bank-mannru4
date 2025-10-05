<script lang="ts">
  import { onMount } from "svelte";
  import { bankService } from "$lib/supabase";
  import Icon from "@iconify/svelte";

  let email = "";
  let isSubscribing = false;
  let subscriptionMessage = "";

  async function subscribeNewsletter() {
    if (!email) return;

    isSubscribing = true;
    try {
      await bankService.subscribeNewsletter(email);
      subscriptionMessage = "Спасибо! Вы успешно подписались на рассылку.";
      email = "";
    } catch (error) {
      subscriptionMessage = "Произошла ошибка. Попробуйте позже.";
    } finally {
      isSubscribing = false;
    }
  }
</script>

<svelte:head>
  <title>Маннру - Ваш надежный банк</title>
</svelte:head>

<!-- Navigation -->
<nav class="navbar bg-white shadow-sm border-b">
  <div class="navbar-start">
    <div class="dropdown">
      <div tabindex="0" role="button" class="btn btn-ghost lg:hidden">
        <Icon icon="mdi:menu" class="w-5 h-5" />
      </div>
      <ul
        tabindex="0"
        class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52"
      >
        <li><a href="#services">Услуги</a></li>
        <li><a href="#about">О банке</a></li>
      </ul>
    </div>
    <a class="btn btn-ghost text-xl font-bold text-primary">Маннру</a>
  </div>
  <div class="navbar-center hidden lg:flex">
    <ul class="menu menu-horizontal px-1">
      <li><a href="#services" class="hover:text-primary">Услуги</a></li>
      <li><a href="#about" class="hover:text-primary">О банке</a></li>
    </ul>
  </div>
  <div class="navbar-end">
    <a href="/login" class="btn btn-primary">
      <Icon icon="mdi:login" class="w-4 h-4" />
      Интернет-банк
    </a>
  </div>
</nav>

<!-- Hero Section -->
<section class="hero min-h-[80vh] bg-gradient-to-r from-slate-50 to-blue-50">
  <div class="hero-content text-center max-w-4xl">
    <div>
      <h1
        class="text-5xl lg:text-6xl font-light text-gray-900 mb-6 tracking-tight"
      >
        Банк <span class="text-primary font-medium">Маннру</span>
      </h1>
      <p
        class="text-xl text-gray-600 mb-8 max-w-2xl mx-auto font-light leading-relaxed"
      >
        Надежные финансовые решения для вашего бизнеса и личных потребностей.
        Более 25 лет на рынке банковских услуг.
      </p>
      <div class="flex flex-col sm:flex-row gap-4 justify-center">
        <button class="btn btn-primary btn-lg">
          <Icon icon="mdi:account-plus" class="w-5 h-5" />
          Открыть счет
        </button>
        <button class="btn btn-outline btn-lg">
          <Icon icon="mdi:phone" class="w-5 h-5" />
          Консультация
        </button>
      </div>
    </div>
  </div>
</section>

<!-- Services Section -->
<section id="services" class="py-20 bg-white">
  <div class="container mx-auto px-4">
    <div class="text-center mb-16">
      <h2 class="text-4xl font-light text-gray-900 mb-4 tracking-tight">
        Банковские услуги
      </h2>
      <p class="text-lg text-gray-600 max-w-2xl mx-auto font-light">
        Полный спектр финансовых услуг для частных лиц и корпоративных клиентов
      </p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
      <div
        class="card bg-white border border-gray-200 hover:shadow-lg transition-shadow"
      >
        <div class="card-body">
          <div
            class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center mb-4"
          >
            <Icon icon="mdi:credit-card" class="w-6 h-6 text-primary" />
          </div>
          <h3 class="card-title text-xl mb-3">Хотя бы есть банковские карты</h3>
          <p class="text-gray-600 mb-4">
            Дебетовые и кредитные карты с кэшбэком до 5% и льготным периодом
          </p>
          <div class="card-actions">
            <button class="btn btn-outline btn-sm">Подробнее</button>
          </div>
        </div>
      </div>

      <div
        class="card bg-white border border-gray-200 hover:shadow-lg transition-shadow"
      >
        <div class="card-body">
          <div
            class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center mb-4"
          >
            <Icon icon="mdi:home" class="w-6 h-6 text-green-600" />
          </div>
          <h3 class="card-title text-xl mb-3">И ипотечного кредитования нет</h3>
          <p class="text-gray-600 mb-4">
            Нет ипотека от 4.5% годовых с минимальным первоначальным взносом
          </p>
          <div class="card-actions">
            <button class="btn btn-outline btn-sm">Подробнее</button>
          </div>
        </div>
      </div>

      <div
        class="card bg-white border border-gray-200 hover:shadow-lg transition-shadow"
      >
        <div class="card-body">
          <div
            class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center mb-4"
          >
            <Icon icon="mdi:chart-line" class="w-6 h-6 text-purple-600" />
          </div>
          <h3 class="card-title text-xl mb-3">Были инвестиции</h3>
          <p class="text-gray-600 mb-4">
            Раньше были инвестиционные продукты и управление портфелем
          </p>
          <div class="card-actions">
            <button class="btn btn-outline btn-sm">Подробнее</button>
          </div>
        </div>
      </div>

      <div
        class="card bg-white border border-gray-200 hover:shadow-lg transition-shadow"
      >
        <div class="card-body">
          <div
            class="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center mb-4"
          >
            <Icon icon="mdi:office-building" class="w-6 h-6 text-orange-600" />
          </div>
          <h3 class="card-title text-xl mb-3">
            Без корпоративного обслуживания
          </h3>
          <p class="text-gray-600 mb-4">
            Нет расчетно-кассового обслуживания и кредитования бизнеса
          </p>
          <div class="card-actions">
            <button class="btn btn-outline btn-sm">Подробнее</button>
          </div>
        </div>
      </div>

      <div
        class="card bg-white border border-gray-200 hover:shadow-lg transition-shadow"
      >
        <div class="card-body">
          <div
            class="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center mb-4"
          >
            <Icon icon="mdi:shield-check" class="w-6 h-6 text-red-600" />
          </div>
          <h3 class="card-title text-xl mb-3">Нет страхования</h3>
          <p class="text-gray-600 mb-4">
            Нет страховки жизни, имущества и автотранспорта
          </p>
          <div class="card-actions">
            <button class="btn btn-outline btn-sm">Подробнее</button>
          </div>
        </div>
      </div>

      <div
        class="card bg-white border border-gray-200 hover:shadow-lg transition-shadow"
      >
        <div class="card-body">
          <div
            class="w-12 h-12 bg-indigo-100 rounded-lg flex items-center justify-center mb-4"
          >
            <Icon icon="mdi:piggy-bank" class="w-6 h-6 text-indigo-600" />
          </div>
          <h3 class="card-title text-xl mb-3">Депозитов тоже нет</h3>
          <p class="text-gray-600 mb-4">
            Нет выгодных условий размещения средств до 8% годовых
          </p>
          <div class="card-actions">
            <button class="btn btn-outline btn-sm">Подробнее</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>

<!-- Features Section -->
<section id="about" class="py-20 bg-gray-50">
  <div class="container mx-auto px-4">
    <div class="text-center mb-16">
      <h2 class="text-4xl font-light text-gray-900 mb-4 tracking-tight">
        Наши преимущества
      </h2>
      <p class="text-lg text-gray-600 max-w-2xl mx-auto font-light">
        Более 25 лет мы предоставляем качественные банковские услуги
      </p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
      <div class="text-center">
        <div
          class="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4"
        >
          <Icon icon="mdi:shield-check" class="w-8 h-8 text-primary" />
        </div>
        <h3 class="text-xl font-semibold mb-3 text-gray-900">Надежность</h3>
        <p class="text-gray-600">
          Высокие рейтинги надежности и страхование вкладов
        </p>
      </div>

      <div class="text-center">
        <div
          class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4"
        >
          <Icon icon="mdi:lightning-bolt" class="w-8 h-8 text-green-600" />
        </div>
        <h3 class="text-xl font-semibold mb-3 text-gray-900">Скорость</h3>
        <p class="text-gray-600">
          Мгновенные переводы и быстрое рассмотрение заявок
        </p>
      </div>

      <div class="text-center">
        <div
          class="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4"
        >
          <Icon icon="mdi:cellphone" class="w-8 h-8 text-purple-600" />
        </div>
        <h3 class="text-xl font-semibold mb-3 text-gray-900">Технологии</h3>
        <p class="text-gray-600">
          Современное мобильное приложение и интернет-банк
        </p>
      </div>

      <div class="text-center">
        <div
          class="w-16 h-16 bg-orange-100 rounded-full flex items-center justify-center mx-auto mb-4"
        >
          <Icon icon="mdi:account-heart" class="w-8 h-8 text-orange-600" />
        </div>
        <h3 class="text-xl font-semibold mb-3 text-gray-900">Сервис</h3>
        <p class="text-gray-600">
          Персональный подход и круглосуточная поддержка
        </p>
      </div>
    </div>
  </div>
</section>

<!-- Stats Section -->
<section class="py-20 bg-primary">
  <div class="container mx-auto px-4">
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-8 text-center text-white">
      <div>
        <div class="text-4xl lg:text-5xl font-bold mb-2">1.2М+</div>
        <div class="text-lg font-medium mb-1">Клиентов</div>
        <div class="text-sm opacity-80">Довольных клиентов</div>
      </div>

      <div>
        <div class="text-4xl lg:text-5xl font-bold mb-2">500+</div>
        <div class="text-lg font-medium mb-1">Отделений</div>
        <div class="text-sm opacity-80">По всей стране</div>
      </div>

      <div>
        <div class="text-4xl lg:text-5xl font-bold mb-2">2000+</div>
        <div class="text-lg font-medium mb-1">Банкоматов</div>
        <div class="text-sm opacity-80">Круглосуточно</div>
      </div>

      <div>
        <div class="text-4xl lg:text-5xl font-bold mb-2">25+</div>
        <div class="text-lg font-medium mb-1">Лет на рынке</div>
        <div class="text-sm opacity-80">Проверенная надежность</div>
      </div>
    </div>
  </div>
</section>

<!-- Newsletter Section -->
<section class="py-20 bg-gray-900 text-white">
  <div class="container mx-auto px-4 text-center">
    <div class="max-w-2xl mx-auto">
      <Icon
        icon="mdi:email-newsletter"
        class="w-16 h-16 mx-auto mb-6 text-accent"
      />
      <h2 class="text-3xl font-bold mb-4">Будьте в курсе новостей</h2>
      <p class="text-lg mb-8 text-gray-300">
        Получайте информацию о новых продуктах, изменениях тарифов и специальных
        предложениях
      </p>

      <div class="max-w-md mx-auto">
        <div class="flex flex-col sm:flex-row gap-3">
          <input
            type="email"
            bind:value={email}
            placeholder="Ваш email адрес"
            class="input input-bordered flex-1 text-black bg-white"
          />
          <button
            class="btn btn-accent"
            disabled={isSubscribing}
            on:click={subscribeNewsletter}
          >
            {#if isSubscribing}
              <Icon icon="mdi:loading" class="w-5 h-5 animate-spin" />
              Подписка...
            {:else}
              <Icon icon="mdi:email-plus" class="w-5 h-5" />
              Подписаться
            {/if}
          </button>
        </div>

        {#if subscriptionMessage}
          <div class="alert alert-success mt-4">
            <Icon icon="mdi:check-circle" class="w-5 h-5" />
            <span>{subscriptionMessage}</span>
          </div>
        {/if}
      </div>
    </div>
  </div>
</section>

<!-- Footer -->
<footer class="bg-gray-800 text-white">
  <div class="container mx-auto px-4 py-12">
    <div class="grid grid-cols-1 md:grid-cols-4 gap-8">
      <!-- Company Info -->
      <div class="col-span-1 md:col-span-2">
        <h3 class="text-2xl font-bold text-primary mb-4">Маннру</h3>
        <p class="text-gray-300 mb-4 max-w-md">
          Банк Маннру - ваш надежный финансовый партнер с 1998 года.
          Предоставляем полный спектр банковских услуг для частных лиц и
          бизнеса.
        </p>
        <div class="flex space-x-4">
          <a href="#" class="text-gray-400 hover:text-white">
            <Icon icon="mdi:facebook" class="w-6 h-6" />
          </a>
          <a href="#" class="text-gray-400 hover:text-white">
            <Icon icon="mdi:twitter" class="w-6 h-6" />
          </a>
          <a href="#" class="text-gray-400 hover:text-white">
            <Icon icon="mdi:instagram" class="w-6 h-6" />
          </a>
          <a href="#" class="text-gray-400 hover:text-white">
            <Icon icon="mdi:youtube" class="w-6 h-6" />
          </a>
        </div>
      </div>

      <!-- Services -->
      <div>
        <h4 class="text-lg font-semibold mb-4">Услуги</h4>
        <ul class="space-y-2 text-gray-300">
          <li><a href="#" class="hover:text-white">Банковские карты</a></li>
          <li><a href="#" class="hover:text-white">Кредиты</a></li>
          <li><a href="#" class="hover:text-white">Депозиты</a></li>
          <li><a href="#" class="hover:text-white">Ипотека</a></li>
          <li><a href="#" class="hover:text-white">Инвестиции</a></li>
        </ul>
      </div>

      <!-- Support -->
      <div>
        <h4 class="text-lg font-semibold mb-4">Поддержка</h4>
        <ul class="space-y-2 text-gray-300">
          <li><a href="#" class="hover:text-white">Контакты</a></li>
          <li><a href="#" class="hover:text-white">FAQ</a></li>
          <li><a href="#" class="hover:text-white">Интернет-банк</a></li>
          <li><a href="#" class="hover:text-white">Мобильное приложение</a></li>
          <li><a href="#" class="hover:text-white">Безопасность</a></li>
        </ul>
      </div>
    </div>

    <div
      class="border-t border-gray-700 mt-8 pt-8 flex flex-col md:flex-row justify-between items-center"
    >
      <div class="text-gray-400 text-sm mb-4 md:mb-0">
        <p>© 2024 Банк Маннру. Все права защищены.</p>
        <p>Лицензия Банка России № 1234 от 15.03.1998</p>
      </div>
      <div class="flex space-x-6 text-sm">
        <a href="#" class="text-gray-400 hover:text-white"
          >Политика конфиденциальности</a
        >
        <a href="#" class="text-gray-400 hover:text-white"
          >Условия использования</a
        >
      </div>
    </div>
  </div>
</footer>
