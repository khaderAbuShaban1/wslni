<?php

namespace App\Providers;

use App\Models\{Complaint, CustomerWithdrawal, DriverProfile, DriverWithdrawal, Promotion, RideOffer, RideRequest, User, WalletDeposit};
use App\Observers\FirebaseRealtimeObserver;
use App\Services\FcmService;
use App\Services\FirebaseRealtimeService;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        // Singletons so queue workers reuse the access token and HTTP connection across jobs.
        $this->app->singleton(FirebaseRealtimeService::class);
        $this->app->singleton(FcmService::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        foreach ([User::class, DriverProfile::class, DriverWithdrawal::class, CustomerWithdrawal::class, WalletDeposit::class, Complaint::class, Promotion::class, RideRequest::class, RideOffer::class] as $model) {
            $model::observe(FirebaseRealtimeObserver::class);
        }

        RateLimiter::for('auth', fn (Request $request) => [
            Limit::perMinute(8)->by($request->ip()),
            Limit::perMinute(5)->by(strtolower((string) $request->input('email')).'|'.$request->ip()),
        ]);

        RateLimiter::for('wallet-read', fn (Request $request) => Limit::perMinute(60)->by((string) $request->user()?->id.'|'.$request->ip())
        );

        RateLimiter::for('wallet-deposit', fn (Request $request) => [
            Limit::perMinute(5)->by((string) $request->user()?->id.'|'.$request->ip()),
            Limit::perDay(10)->by((string) $request->user()?->id),
        ]);
    }
}
