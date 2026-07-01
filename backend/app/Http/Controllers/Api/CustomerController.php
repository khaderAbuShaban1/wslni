<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;

class CustomerController extends Controller
{
    public function me(): JsonResponse
    {
        return response()->json([
            'message' => 'Customer profile endpoint is ready for integration.',
        ]);
    }
}
