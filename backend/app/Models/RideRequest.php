<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RideRequest extends Model
{
    protected $fillable = [
        'customer_id',
        'driver_id',
        'status',
        'pickup_address',
        'pickup_lat',
        'pickup_lng',
        'dropoff_address',
        'dropoff_lat',
        'dropoff_lng',
        'fare_estimate',
        'actual_fare',
        'distance_km',
        'commission_percent',
        'platform_fee',
        'notes',
        'requested_at',
        'accepted_at',
        'completed_at',
    ];

    protected function casts(): array
    {
        return [
            'pickup_lat' => 'decimal:7',
            'pickup_lng' => 'decimal:7',
            'dropoff_lat' => 'decimal:7',
            'dropoff_lng' => 'decimal:7',
            'fare_estimate' => 'decimal:2',
            'actual_fare' => 'decimal:2',
            'distance_km' => 'decimal:2',
            'commission_percent' => 'decimal:2',
            'platform_fee' => 'decimal:2',
            'requested_at' => 'datetime',
            'accepted_at' => 'datetime',
            'completed_at' => 'datetime',
        ];
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'driver_id');
    }
}
