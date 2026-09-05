<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\CustomerWalletController;
use App\Http\Controllers\Api\DriverController;
use App\Http\Controllers\Api\DriverWithdrawalController;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\RideController;
use App\Http\Controllers\Api\RideOfferController;
use Illuminate\Support\Facades\Route;

Route::get('/health', [HealthController::class, 'index']);

Route::prefix('auth')->middleware('throttle:auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('driver/register', [AuthController::class, 'registerDriver']);
    Route::post('login', [AuthController::class, 'login']);
    Route::post('verify-otp', [AuthController::class, 'verifyOtp']);
    Route::post('resend-otp', [AuthController::class, 'resendOtp']);
});

Route::apiResource('rides', RideController::class);
Route::post('rides/{ride}/offers', [RideOfferController::class, 'store']);
Route::patch('rides/{ride}/offers/{offer}/accept', [RideOfferController::class, 'accept']);
Route::patch('rides/{ride}/drivers/{driver}/accept', [RideOfferController::class, 'acceptDriverOffer']);
Route::patch('rides/{ride}/driver-confirmation', [RideController::class, 'driverConfirmation']);
Route::post('rides/{ride}/rating', [RideController::class, 'rate']);
Route::get('drivers/available', [DriverController::class, 'available']);
Route::patch('drivers/{driver}/status', [DriverController::class, 'updateStatus']);
Route::get('drivers/{driver}/withdrawals', [DriverWithdrawalController::class, 'index']);
Route::post('drivers/{driver}/withdrawals', [DriverWithdrawalController::class, 'store']);
Route::get('customers/me', [CustomerController::class, 'me']);
Route::patch('customers/{customer}', [CustomerController::class, 'update']);
Route::middleware(['auth:sanctum', 'financial'])->group(function () {
    Route::get('customers/me/wallet', [CustomerWalletController::class, 'show'])
        ->middleware('throttle:wallet-read');
    Route::post('customers/me/wallet/deposits', [CustomerWalletController::class, 'storeDeposit'])
        ->middleware('throttle:wallet-deposit');
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('firebase/token', fn (\Illuminate\Http\Request $request) => response()->json([
        'token' => app(\App\Services\FirebaseRealtimeService::class)->customToken($request->user()),
    ]));
    Route::patch('customers/me', [CustomerController::class, 'update']);
});
