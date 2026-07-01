<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DriverProfile extends Model
{
    protected $fillable = [
        'user_id',
        'license_number',
        'vehicle_type',
        'vehicle_plate',
        'approval_status',
        'approved_at',
        'rejection_reason',
        'is_online',
        'current_lat',
        'current_lng',
        'rating',
    ];

    protected function casts(): array
    {
        return [
            'approved_at' => 'datetime',
            'is_online' => 'boolean',
            'current_lat' => 'decimal:7',
            'current_lng' => 'decimal:7',
            'rating' => 'decimal:2',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isApproved(): bool
    {
        return $this->approval_status === 'approved';
    }
}
