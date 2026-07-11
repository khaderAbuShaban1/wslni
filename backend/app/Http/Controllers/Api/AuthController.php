<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DriverProfile;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['required', 'string', 'max:30', 'unique:users,phone'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ], [
            'name.required' => 'الاسم مطلوب.',
            'email.required' => 'البريد الإلكتروني مطلوب.',
            'email.email' => 'أدخل بريدًا إلكترونيًا صحيحًا.',
            'email.unique' => 'هذا البريد مستخدم مسبقًا.',
            'phone.required' => 'رقم الجوال مطلوب.',
            'phone.unique' => 'رقم الجوال مستخدم مسبقًا.',
            'password.required' => 'كلمة المرور مطلوبة.',
            'password.min' => 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.',
            'password.confirmed' => 'تأكيد كلمة المرور غير متطابق.',
        ]);

        $user = DB::transaction(function () use ($data) {
            $user = User::create([
                'name' => $data['name'],
                'email' => $data['email'],
                'phone' => $data['phone'],
                'password' => $data['password'],
                'role' => 'customer',
                'account_status' => 'active',
            ]);

            $this->sendOtp($user);

            return $user;
        });

        return response()->json([
            'message' => 'تم إنشاء الحساب. تحقق من بريدك للحصول على رمز التحقق.',
            'user' => $this->userPayload($user),
        ], 201);
    }

    public function registerDriver(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['required', 'string', 'max:30', 'unique:users,phone'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'license_number' => ['required', 'string', 'max:100'],
            'vehicle_type' => ['required', 'string', 'max:100'],
            'vehicle_plate' => ['required', 'string', 'max:100'],
        ], [
            'name.required' => 'الاسم مطلوب.',
            'email.required' => 'البريد الإلكتروني مطلوب.',
            'email.email' => 'أدخل بريدًا إلكترونيًا صحيحًا.',
            'email.unique' => 'هذا البريد مستخدم مسبقًا.',
            'phone.required' => 'رقم الجوال مطلوب.',
            'phone.unique' => 'رقم الجوال مستخدم مسبقًا.',
            'password.required' => 'كلمة المرور مطلوبة.',
            'password.min' => 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.',
            'password.confirmed' => 'تأكيد كلمة المرور غير متطابق.',
            'license_number.required' => 'رقم الرخصة مطلوب.',
            'vehicle_type.required' => 'نوع السيارة مطلوب.',
            'vehicle_plate.required' => 'رقم السيارة مطلوب.',
        ]);

        $user = DB::transaction(function () use ($data) {
            $user = User::create([
                'name' => $data['name'],
                'email' => $data['email'],
                'phone' => $data['phone'],
                'password' => $data['password'],
                'role' => 'driver',
                'account_status' => 'active',
            ]);

            DriverProfile::create([
                'user_id' => $user->id,
                'license_number' => $data['license_number'],
                'vehicle_type' => $data['vehicle_type'],
                'vehicle_plate' => $data['vehicle_plate'],
                'approval_status' => 'pending',
                'is_online' => true,
            ]);

            $this->sendOtp($user);

            return $user->load('driverProfile');
        });

        return response()->json([
            'message' => 'تم إنشاء حساب السائق. تحقق من بريدك للحصول على رمز التحقق.',
            'user' => $this->userPayload($user),
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ], [
            'email.required' => 'البريد الإلكتروني مطلوب.',
            'email.email' => 'أدخل بريدًا إلكترونيًا صحيحًا.',
            'password.required' => 'كلمة المرور مطلوبة.',
        ]);

        $user = User::where('email', $credentials['email'])->first();

        if (! $user || ! Hash::check($credentials['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['البريد الإلكتروني أو كلمة المرور غير صحيحة.'],
            ]);
        }

        if (! $user->email_verified_at) {
            $this->sendOtp($user);

            return response()->json([
                'message' => 'البريد غير مفعل. تم إرسال رمز تحقق جديد.',
                'requires_otp' => true,
                'email' => $user->email,
            ], 403);
        }

        return response()->json([
            'message' => 'تم تسجيل الدخول بنجاح.',
            'user' => $this->userPayload($user),
        ]);
    }

    public function verifyOtp(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'otp' => ['required', 'digits:6'],
        ], [
            'email.required' => 'البريد الإلكتروني مطلوب.',
            'email.email' => 'أدخل بريدًا إلكترونيًا صحيحًا.',
            'otp.required' => 'رمز التحقق مطلوب.',
            'otp.digits' => 'رمز التحقق يجب أن يكون 6 أرقام.',
        ]);

        $user = User::where('email', $data['email'])->firstOrFail();

        if (
            ! $user->email_otp_code ||
            ! hash_equals($user->email_otp_code, $data['otp']) ||
            ! $user->email_otp_expires_at ||
            $user->email_otp_expires_at->isPast()
        ) {
            throw ValidationException::withMessages([
                'otp' => ['رمز التحقق غير صحيح أو منتهي الصلاحية.'],
            ]);
        }

        $user->forceFill([
            'email_verified_at' => now(),
            'email_otp_code' => null,
            'email_otp_expires_at' => null,
        ])->save();

        return response()->json([
            'message' => 'تم تفعيل البريد الإلكتروني بنجاح.',
            'user' => $this->userPayload($user),
        ]);
    }

    public function resendOtp(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
        ], [
            'email.required' => 'البريد الإلكتروني مطلوب.',
            'email.email' => 'أدخل بريدًا إلكترونيًا صحيحًا.',
        ]);

        $user = User::where('email', $data['email'])->firstOrFail();
        $this->sendOtp($user);

        return response()->json([
            'message' => 'تم إرسال رمز تحقق جديد.',
        ]);
    }

    private function sendOtp(User $user): void
    {
        $otp = (string) random_int(100000, 999999);

        Mail::raw(
            "رمز التحقق الخاص بتطبيق وصلني هو {$otp}. ينتهي خلال 10 دقائق.",
            fn ($message) => $message
                ->to($user->email)
                ->subject('رمز التحقق من وصلني')
        );

        $user->forceFill([
            'email_otp_code' => $otp,
            'email_otp_expires_at' => Carbon::now()->addMinutes(10),
        ])->save();
    }

    private function userPayload(User $user): array
    {
        $user->loadMissing('driverProfile');

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'role' => $user->role,
            'wallet_balance' => (float) $user->wallet_balance,
            'email_verified_at' => $user->email_verified_at,
            'driver_profile' => $user->driverProfile,
        ];
    }
}
