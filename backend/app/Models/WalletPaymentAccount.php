<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class WalletPaymentAccount extends Model
{
    protected $fillable = [
        'type',
        'name',
        'account_holder_name',
        'account_number',
        'phone_number',
        'instructions',
        'is_active',
        'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    public function deposits(): HasMany
    {
        return $this->hasMany(WalletDeposit::class);
    }

    public function invoiceNumber(): string
    {
        return 'WSL-PAY-'.str_pad((string) $this->id, 6, '0', STR_PAD_LEFT);
    }
}
