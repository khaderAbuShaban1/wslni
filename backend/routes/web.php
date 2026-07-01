<?php

use App\Http\Controllers\Admin\AnalyticsController;
use App\Http\Controllers\Admin\ComplaintsController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\DriversController;
use App\Http\Controllers\Admin\OffersController;
use App\Http\Controllers\Admin\RidersController;
use App\Http\Controllers\Admin\RidesController;
use App\Http\Controllers\Admin\SettingsController;
use App\Http\Controllers\Auth\AuthController;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('auth.login');
});

Route::middleware('guest')->group(function () {
    Route::get('/login', [AuthController::class, 'showLogin'])->name('auth.login');
    Route::post('/login', [AuthController::class, 'login'])->name('auth.login.store');
});

Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth')->name('auth.logout');

Route::get('/home', function () {
    if (Auth::check() && Auth::user()->isAdmin()) {
        return redirect()->route('admin.dashboard');
    }

    return view('home');
})->middleware('auth')->name('home');

Route::prefix('admin')->middleware(['auth', 'admin'])->name('admin.')->group(function () {
    Route::get('/', [DashboardController::class, 'index'])->name('dashboard');

    Route::get('/drivers', [DriversController::class, 'index'])->name('drivers.index');
    Route::patch('/drivers/{driverProfile}/approve', [DriversController::class, 'approve'])->name('drivers.approve');
    Route::patch('/drivers/{driverProfile}/reject', [DriversController::class, 'reject'])->name('drivers.reject');
    Route::patch('/drivers/{driverProfile}/toggle-online', [DriversController::class, 'toggleOnline'])->name('drivers.toggle-online');

    Route::get('/riders', [RidersController::class, 'index'])->name('riders.index');
    Route::patch('/riders/{user}/suspend', [RidersController::class, 'suspend'])->name('riders.suspend');
    Route::patch('/riders/{user}/activate', [RidersController::class, 'activate'])->name('riders.activate');

    Route::get('/rides', [RidesController::class, 'index'])->name('rides.index');
    Route::patch('/rides/{rideRequest}/status', [RidesController::class, 'updateStatus'])->name('rides.status');

    Route::get('/commission', [SettingsController::class, 'edit'])->name('commission.edit');
    Route::post('/commission', [SettingsController::class, 'update'])->name('commission.update');

    Route::get('/complaints', [ComplaintsController::class, 'index'])->name('complaints.index');
    Route::post('/complaints', [ComplaintsController::class, 'store'])->name('complaints.store');
    Route::patch('/complaints/{complaint}/resolve', [ComplaintsController::class, 'resolve'])->name('complaints.resolve');

    Route::get('/offers', [OffersController::class, 'index'])->name('offers.index');
    Route::post('/offers', [OffersController::class, 'store'])->name('offers.store');
    Route::patch('/offers/{promotion}/toggle', [OffersController::class, 'toggle'])->name('offers.toggle');

    Route::get('/analytics', [AnalyticsController::class, 'index'])->name('analytics.index');
});
