<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Promotion;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class OffersController extends Controller
{
    public function index(): View
    {
        return view('admin.offers', [
            'offers' => Promotion::query()->latest()->get(),
            'activeCount' => Promotion::query()->where('is_active', true)->count(),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'code' => ['required', 'string', 'max:100', 'unique:promotions,code'],
            'type' => ['required', 'in:discount,fixed,free_ride'],
            'value' => ['required', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string', 'max:5000'],
        ]);

        Promotion::create($data + ['is_active' => true]);

        return back()->with('status', 'تم إنشاء العرض.');
    }

    public function toggle(Promotion $promotion): RedirectResponse
    {
        $promotion->update([
            'is_active' => ! $promotion->is_active,
        ]);

        return back()->with('status', 'تم تحديث حالة العرض.');
    }
}
