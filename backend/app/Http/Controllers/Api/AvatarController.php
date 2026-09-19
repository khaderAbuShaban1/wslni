<?php

namespace App\Http\Controllers\Api;

use App\Enums\RideStatus;
use App\Http\Controllers\Controller;
use App\Jobs\SyncFirebaseProjection;
use App\Models\RideRequest;
use App\Models\User;
use App\Support\ImageMetadataStripper;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use InvalidArgumentException;

class AvatarController extends Controller
{
    private const EXTENSIONS = [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
    ];

    public function store(Request $request): JsonResponse
    {
        $user = $this->user($request);
        $request->validate([
            'avatar' => [
                'required', 'file', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120',
                'dimensions:min_width=64,min_height=64,max_width=6000,max_height=6000',
            ],
        ], [
            'avatar.required' => 'اختر صورة أولًا.',
            'avatar.image' => 'الملف المختار ليس صورة.',
            'avatar.mimes' => 'الصورة يجب أن تكون JPG أو PNG أو WebP.',
            'avatar.max' => 'حجم الصورة يجب ألا يتجاوز 5 ميجابايت.',
            'avatar.dimensions' => 'أبعاد الصورة غير مناسبة.',
        ]);

        $file = $request->file('avatar');
        $mime = (string) $file->getMimeType();
        if (! isset(self::EXTENSIONS[$mime])) {
            return response()->json(['message' => 'نوع الصورة غير مدعوم.'], 422);
        }

        try {
            $clean = ImageMetadataStripper::strip((string) file_get_contents($file->getRealPath()), $mime);
        } catch (InvalidArgumentException) {
            return response()->json(['message' => 'تعذر قراءة الصورة. جرّب صورة أخرى.'], 422);
        }

        // A fresh name per upload, so no client keeps showing a cached old photo.
        $path = 'avatars/'.$user->id.'-'.Str::random(32).'.'.self::EXTENSIONS[$mime];
        Storage::disk('public')->put($path, $clean);

        $this->replaceAvatar($user, $path);

        return response()->json([
            'message' => 'تم تحديث الصورة الشخصية.',
            'avatar_path' => $path,
        ]);
    }

    public function destroy(Request $request): JsonResponse
    {
        $this->replaceAvatar($this->user($request), null);

        return response()->json([
            'message' => 'تم حذف الصورة الشخصية.',
            'avatar_path' => null,
        ]);
    }

    private function user(Request $request): User
    {
        $user = $request->user();
        abort_unless($user?->isActive(), 403, 'الحساب موقوف.');

        return $user;
    }

    private function replaceAvatar(User $user, ?string $path): void
    {
        $previous = $user->avatar_path;
        $user->forceFill(['avatar_path' => $path])->save();

        if ($previous !== null && $previous !== $path) {
            Storage::disk('public')->delete($previous);
        }

        $this->republishLiveRides($user);
    }

    /** Rides embed both parties' photos, so the other side sees the change at once. */
    private function republishLiveRides(User $user): void
    {
        $live = [
            'requested',
            RideStatus::Pending->value,
            RideStatus::ReceivingOffers->value,
            RideStatus::DriverSelected->value,
            ...RideStatus::activeValues(),
        ];

        RideRequest::query()
            ->whereIn('status', $live)
            ->where(fn ($query) => $query
                ->where('customer_id', $user->id)
                ->orWhere('driver_id', $user->id)
                ->orWhereHas('offers', fn ($offers) => $offers->where('driver_id', $user->id)))
            ->pluck('id')
            ->each(fn (int $id) => SyncFirebaseProjection::dispatch(RideRequest::class, $id));
    }
}
