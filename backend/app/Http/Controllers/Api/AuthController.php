<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        return response()->json([
            'message' => 'Registration endpoint is ready.',
            'payload' => $request->all(),
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        return response()->json([
            'message' => 'Login endpoint is ready.',
            'payload' => $request->all(),
        ]);
    }

    public function me(): JsonResponse
    {
        return response()->json([
            'message' => 'Authenticated user endpoint is ready.',
        ]);
    }

    public function logout(): JsonResponse
    {
        return response()->json([
            'message' => 'Logout endpoint is ready.',
        ]);
    }
}
