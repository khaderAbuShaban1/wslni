<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\DriverController;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\RideController;
use Illuminate\Support\Facades\Route;

Route::get('/health', [HealthController::class, 'index']);

Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
});

Route::get('/me', [AuthController::class, 'me']);
Route::post('/logout', [AuthController::class, 'logout']);

Route::apiResource('rides', RideController::class);
Route::get('drivers/available', [DriverController::class, 'available']);
Route::patch('drivers/{driver}/status', [DriverController::class, 'updateStatus']);
Route::get('customers/me', [CustomerController::class, 'me']);
