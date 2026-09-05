<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CustomerController extends Controller
{
    public function me(Request $request): JsonResponse
    {
        return response()->json(['user' => $this->customerPayload($this->customer($request))]);
    }

    public function update(Request $request): JsonResponse
    {
        $customer = $this->customer($request);
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
            'user' => $this->customerPayload($customer->fresh()),
        ]);
    }

    private function customer(Request $request): User
    {
        $customer = $request->user();
        abort_unless($customer?->role === 'customer' && $customer->isActive(), 403);

        return $customer;
    }

    private function customerPayload(User $customer): array
    {
        return [
            'id' => $customer->id,
            'name' => $customer->name,
            'email' => $customer->email,
            'phone' => $customer->phone,
            'role' => $customer->role,
            'wallet_balance' => (float) $customer->wallet_balance,
        ];
    }
}
