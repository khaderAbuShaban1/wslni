<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RideOffer;
use App\Models\RideRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RideOfferController extends Controller
{
    public function store(Request $request, RideRequest $ride): JsonResponse
    {
        $data = $request->validate([
            'driver_id' => ['required', 'exists:users,id'],
            'price' => ['required', 'numeric', 'min:1', 'max:99999'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ], [
            'driver_id.required' => 'بيانات السائق مطلوبة.',
            'driver_id.exists' => 'حساب السائق غير موجود.',
            'price.required' => 'السعر مطلوب.',
            'price.numeric' => 'السعر يجب أن يكون رقمًا.',
            'price.min' => 'السعر يجب أن يكون أكبر من صفر.',
        ]);

        if ($ride->status !== 'requested') {
            return response()->json([
                'message' => 'لا يمكن تقديم عرض على هذا الطلب حاليًا.',
            ], 422);
        }

        $offer = RideOffer::updateOrCreate(
            [
                'ride_request_id' => $ride->id,
                'driver_id' => $data['driver_id'],
            ],
            [
                'price' => $data['price'],
                'notes' => $data['notes'] ?? null,
                'status' => 'pending',
            ]
        );

        return response()->json([
            'message' => 'تم إرسال عرض السعر بنجاح.',
            'offer' => $offer,
        ], 201);
    }
}
