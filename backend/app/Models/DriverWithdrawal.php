<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DriverWithdrawal extends Model
{
    protected $fillable = [
        'driver_id', 'amount', 'method', 'account_name', 'account_number',
        'status', 'reviewed_by', 'reviewed_at', 'note',
    ];

    protected function casts(): array
    {
        return ['amount' => 'decimal:2', 'reviewed_at' => 'datetime'];
    }

    public function driver(): BelongsTo { return $this->belongsTo(User::class, 'driver_id'); }
    public function reviewer(): BelongsTo { return $this->belongsTo(User::class, 'reviewed_by'); }
}
