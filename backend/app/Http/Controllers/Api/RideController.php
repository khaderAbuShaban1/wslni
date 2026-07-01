<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use App\Models\RideRequest;

class RideController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(RideRequest::query()->latest()->get());
    }

    public function store(Request $request): JsonResponse
    {
        return response()->json([
            'message' => 'Ride request endpoint is ready for integration.',
            'payload' => $request->all(),
        ], 201);
    }

    public function show(RideRequest $ride): JsonResponse
    {
        return response()->json($ride);
    }

    public function update(Request $request, RideRequest $ride): JsonResponse
    {
        return response()->json([
            'message' => 'Ride update stub.',
            'ride' => $ride,
            'payload' => $request->all(),
        ]);
    }

    public function destroy(RideRequest $ride): JsonResponse
    {
        return response()->json(['message' => 'Ride deletion stub.', 'ride_id' => $ride->id]);
    }
}
