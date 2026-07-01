<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DriverProfile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DriverController extends Controller
{
    public function available(): JsonResponse
    {
        return response()->json([
            'drivers' => DriverProfile::query()->where('is_online', true)->latest()->get(),
        ]);
    }

    public function updateStatus(Request $request, DriverProfile $driver): JsonResponse
    {
        return response()->json([
            'message' => 'Driver status endpoint is ready for integration.',
            'driver' => $driver,
            'payload' => $request->all(),
        ]);
    }
}
