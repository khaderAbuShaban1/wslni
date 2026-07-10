<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WalletDeposit extends Model
{
    protected $fillable = [
        'user_id',
        'wallet_payment_account_id',
        'amount',
        'bank_name',
        'reference_number',
        'receipt_path',
        'status',
        'note',
        'reviewed_by',
        'reviewed_at',
        'wallet_credited_at',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'reviewed_at' => 'datetime',
            'wallet_credited_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function paymentAccount(): BelongsTo
    {
        return $this->belongsTo(WalletPaymentAccount::class, 'wallet_payment_account_id');
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function isApproved(): bool
    {
        return $this->status === 'approved';
    }
}
