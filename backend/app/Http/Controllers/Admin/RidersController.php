<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class RidersController extends Controller
{
    public function index(Request $request): View
    {
        $search = trim($request->string('search')->toString());
        $status = $request->string('status')->toString();

        $riders = User::query()
            ->where('role', 'customer')
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($nested) use ($search) {
                    $nested->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%");
                });
            })
            ->when($status && $status !== 'all', fn ($query) => $query->where('account_status', $status))
            ->latest()
            ->get();

        return view('admin.riders', [
            'riders' => $riders,
            'search' => $search,
            'status' => $status ?: 'all',
            'activeCount' => User::query()->where('role', 'customer')->where('account_status', 'active')->count(),
            'suspendedCount' => User::query()->where('role', 'customer')->where('account_status', 'suspended')->count(),
        ]);
    }

    public function suspend(User $user): RedirectResponse
    {
        $user->update(['account_status' => 'suspended']);

        return back()->with('status', 'تم إيقاف الراكب مؤقتًا.');
    }

    public function activate(User $user): RedirectResponse
    {
        $user->update(['account_status' => 'active']);

        return back()->with('status', 'تم تفعيل الراكب.');
    }
}
