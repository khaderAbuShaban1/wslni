@php
    $walletTabs = [
        'deposits' => ['label' => 'إشعارات الإيداع', 'route' => 'admin.wallets.index'],
        'withdrawals' => ['label' => 'طلبات السحب', 'route' => 'admin.wallets.withdrawals'],
        'balances' => ['label' => 'أرصدة المستخدمين', 'route' => 'admin.wallets.balances'],
        'accounts' => ['label' => 'حسابات التحويل', 'route' => 'admin.wallet-payment-accounts.index'],
    ];
@endphp
<nav class="subnav">
    @foreach ($walletTabs as $key => $tab)
        <a class="subnav-link {{ $active === $key ? 'active' : '' }}" href="{{ route($tab['route']) }}">
            {{ $tab['label'] }}
            @isset($tabCounts[$key])
                <span class="subnav-count">{{ $tabCounts[$key] }}</span>
            @endisset
        </a>
    @endforeach
</nav>
