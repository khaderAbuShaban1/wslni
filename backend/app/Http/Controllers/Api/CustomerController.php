<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CustomerController extends Controller
{
    public function me(): JsonResponse
    {
        return response()->json([
            'message' => 'Customer profile endpoint is ready for integration.',
        ]);
    }

    public function update(Request $request, User $customer): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:30'],
        ], [
            'name.required' => 'الاسم مطلوب.',
            'phone.max' => 'رقم الجوال طويل جدًا.',
        ]);

        $customer->update([
            'name' => $data['name'],
            'phone' => $data['phone'] ?? null,
        ]);

        return response()->json([
            'message' => 'تم تحديث بيانات الحساب بنجاح.',
            'user' => $customer->fresh(),
        ]);
    }
}
