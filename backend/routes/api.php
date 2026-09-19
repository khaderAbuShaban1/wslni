<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\CustomerWalletController;
use App\Http\Controllers\Api\CustomerWithdrawalController;
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

/*
|--------------------------------------------------------------------------
| Authenticated API Routes
|--------------------------------------------------------------------------
| Every route below requires a valid Sanctum token. The identity of the
| acting user is ALWAYS derived from $request->user() — never from a
| client-supplied ID in the request body or URL.
*/
Route::middleware('auth:sanctum')->group(function () {
    Route::post('auth/change-password', [AuthController::class, 'changePassword'])
        ->middleware('throttle:6,1');

    // Rides — scoped by the authenticated user's role.
    Route::apiResource('rides', RideController::class);
    Route::post('rides/{ride}/offers', [RideOfferController::class, 'store']);
    Route::patch('rides/{ride}/offers/{offer}/accept', [RideOfferController::class, 'accept']);
    Route::patch('rides/{ride}/drivers/{driver}/accept', [RideOfferController::class, 'acceptDriverOffer']);
    Route::patch('rides/{ride}/driver-confirmation', [RideController::class, 'driverConfirmation']);
    Route::post('rides/{ride}/rating', [RideController::class, 'rate']);
    Route::post('rides/{ride}/expire', [RideController::class, 'expire']);

    // Drivers
    Route::get('drivers/available', [DriverController::class, 'available']);
    Route::get('drivers/{driver}/ratings', [DriverController::class, 'ratings']);
    Route::get('drivers/me', [DriverController::class, 'me']);
    Route::patch('drivers/me', [DriverController::class, 'update']);
    Route::patch('drivers/me/status', [DriverController::class, 'updateStatus']);
    Route::get('drivers/me/withdrawals', [DriverWithdrawalController::class, 'index']);
    Route::post('drivers/me/withdrawals', [DriverWithdrawalController::class, 'store']);

    // Customer profile
    Route::get('customers/me', [CustomerController::class, 'me']);
    Route::patch('customers/me', [CustomerController::class, 'update']);

    // Wallet (additional financial middleware)
    Route::middleware('financial')->group(function () {
        Route::get('customers/me/wallet', [CustomerWalletController::class, 'show'])
            ->middleware('throttle:wallet-read');
        Route::post('customers/me/wallet/deposits', [CustomerWalletController::class, 'storeDeposit'])
            ->middleware('throttle:wallet-deposit');
        Route::get('customers/me/withdrawals', [CustomerWithdrawalController::class, 'index'])
            ->middleware('throttle:wallet-read');
        Route::post('customers/me/withdrawals', [CustomerWithdrawalController::class, 'store'])
            ->middleware('throttle:wallet-deposit');
    });

    // Firebase custom token
    Route::get('firebase/token', fn (\Illuminate\Http\Request $request) => response()->json([
        'token' => app(\App\Services\FirebaseRealtimeService::class)->customToken($request->user()),
    ]));

    // FCM device token registration
    Route::post('fcm/token', function (\Illuminate\Http\Request $request) {
        $request->validate(['token' => ['required', 'string', 'max:512']]);
        $token = $request->input('token');
        // Clear this token from any other user (same device, different account).
        \App\Models\User::where('fcm_token', $token)
            ->where('id', '!=', $request->user()->id)
            ->update(['fcm_token' => null]);
        // Apps re-claim the token on every resume, so skip the write (and the
        // model observers it triggers) when nothing actually changed.
        if ($request->user()->fcm_token !== $token) {
            $request->user()->update(['fcm_token' => $token]);
        }
        return response()->json(['message' => 'تم تسجيل التوكن بنجاح.']);
    });

    Route::delete('fcm/token', function (\Illuminate\Http\Request $request) {
        $request->user()->update(['fcm_token' => null]);
        return response()->json(['message' => 'تم إلغاء تسجيل التوكن.']);
    });
});
