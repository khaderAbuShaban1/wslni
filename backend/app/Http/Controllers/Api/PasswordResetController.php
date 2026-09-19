<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

/**
 * Forgot password in three steps: email a code, exchange the code for a
 * short-lived reset token, then set the new password with that token.
 */
class PasswordResetController extends Controller
{
    private const CODE_MINUTES = 10;

    private const TOKEN_MINUTES = 15;

    private const MAX_ATTEMPTS = 5;

    private const RESEND_COOLDOWN_SECONDS = 60;

    public function sendCode(Request $request): JsonResponse
    {
        $email = $this->email($request);

        // Same answer whether or not the account exists, so the endpoint
        // can't be used to discover which emails are registered.
        $response = response()->json([
            'message' => 'إذا كان البريد مسجلًا لدينا، فسيصلك رمز التحقق خلال لحظات.',
        ]);

        $user = User::where('email', $email)->first();
        if ($user === null || ! $user->isActive()) {
            return $response;
        }

        $existing = $this->row($email);
        if ($existing && now()->diffInSeconds($existing->updated_at, true) < self::RESEND_COOLDOWN_SECONDS) {
            return $response;
        }

        $code = (string) random_int(100000, 999999);
        DB::table('password_reset_codes')->updateOrInsert(['email' => $email], [
            'code_hash' => Hash::make($code),
            'attempts' => 0,
            'code_expires_at' => now()->addMinutes(self::CODE_MINUTES),
            'reset_token_hash' => null,
            'reset_token_expires_at' => null,
            'created_at' => $existing->created_at ?? now(),
            'updated_at' => now(),
        ]);

        app()->terminating(static function () use ($email, $code): void {
            try {
                Mail::raw(
                    "رمز إعادة تعيين كلمة المرور في تطبيق وصلني هو {$code}. ينتهي خلال ".self::CODE_MINUTES.' دقائق. إذا لم تطلب ذلك فتجاهل هذه الرسالة.',
                    fn ($message) => $message->to($email)->subject('إعادة تعيين كلمة المرور - وصلني')
                );
            } catch (\Throwable $e) {
                report($e);
            }
        });

        return $response;
    }

    public function verifyCode(Request $request): JsonResponse
    {
        $email = $this->email($request);
        $data = $request->validate(['code' => ['required', 'digits:6']], [
            'code.required' => 'رمز التحقق مطلوب.',
            'code.digits' => 'رمز التحقق يجب أن يكون 6 أرقام.',
        ]);

        $row = $this->row($email);
        $invalid = ValidationException::withMessages([
            'code' => ['رمز التحقق غير صحيح أو منتهي الصلاحية.'],
        ]);

        if (! $row || ! $row->code_hash || now()->greaterThan($row->code_expires_at)) {
            throw $invalid;
        }

        if (! Hash::check($data['code'], $row->code_hash)) {
            $attempts = $row->attempts + 1;
            if ($attempts >= self::MAX_ATTEMPTS) {
                DB::table('password_reset_codes')->where('email', $email)->delete();

                throw ValidationException::withMessages([
                    'code' => ['تجاوزت عدد المحاولات. اطلب رمزًا جديدًا.'],
                ]);
            }
            DB::table('password_reset_codes')->where('email', $email)->update([
                'attempts' => $attempts,
                'updated_at' => now(),
            ]);

            throw $invalid;
        }

        // The code is single use; from here on only the reset token counts.
        $token = Str::random(64);
        DB::table('password_reset_codes')->where('email', $email)->update([
            'code_hash' => null,
            'reset_token_hash' => hash('sha256', $token),
            'reset_token_expires_at' => now()->addMinutes(self::TOKEN_MINUTES),
            'updated_at' => now(),
        ]);

        return response()->json([
            'message' => 'تم التحقق من الرمز. أدخل كلمة المرور الجديدة.',
            'reset_token' => $token,
        ]);
    }

    public function reset(Request $request): JsonResponse
    {
        $email = $this->email($request);
        $data = $request->validate([
            'reset_token' => ['required', 'string', 'size:64'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ], [
            'reset_token.required' => 'انتهت جلسة إعادة التعيين. ابدأ من جديد.',
            'reset_token.size' => 'انتهت جلسة إعادة التعيين. ابدأ من جديد.',
            'password.required' => 'أدخل كلمة المرور الجديدة.',
            'password.min' => 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.',
            'password.confirmed' => 'تأكيد كلمة المرور غير متطابق.',
        ]);

        $row = $this->row($email);
        $user = User::where('email', $email)->first();
        if (! $row || ! $user || ! $row->reset_token_hash
            || now()->greaterThan($row->reset_token_expires_at)
            || ! hash_equals($row->reset_token_hash, hash('sha256', $data['reset_token']))) {
            throw ValidationException::withMessages([
                'reset_token' => ['انتهت جلسة إعادة التعيين. ابدأ من جديد.'],
            ]);
        }

        DB::transaction(function () use ($user, $data, $email): void {
            $user->forceFill([
                'password' => $data['password'],
                // Receiving the code proves the address belongs to them.
                'email_verified_at' => $user->email_verified_at ?? now(),
            ])->save();

            // Anyone who knew the old password is signed out everywhere.
            $user->tokens()->delete();
            DB::table('password_reset_codes')->where('email', $email)->delete();
        });

        return response()->json([
            'message' => 'تم تغيير كلمة المرور بنجاح. سجّل الدخول بكلمة المرور الجديدة.',
        ]);
    }

    private function email(Request $request): string
    {
        $data = $request->validate(['email' => ['required', 'email', 'max:255']], [
            'email.required' => 'البريد الإلكتروني مطلوب.',
            'email.email' => 'أدخل بريدًا إلكترونيًا صحيحًا.',
        ]);

        return strtolower(trim($data['email']));
    }

    private function row(string $email): ?object
    {
        $row = DB::table('password_reset_codes')->where('email', $email)->first();
        if ($row) {
            foreach (['code_expires_at', 'reset_token_expires_at', 'created_at', 'updated_at'] as $column) {
                $row->{$column} = $row->{$column} ? Carbon::parse($row->{$column}) : null;
            }
        }

        return $row;
    }
}
