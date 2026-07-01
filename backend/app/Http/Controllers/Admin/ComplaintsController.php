<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Complaint;
use App\Models\RideRequest;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class ComplaintsController extends Controller
{
    public function index(Request $request): View
    {
        return view('admin.complaints', [
            'complaints' => Complaint::query()->with(['user:id,name,phone', 'rideRequest:id,pickup_address,dropoff_address,status'])->latest()->get(),
            'openCount' => Complaint::query()->where('status', 'open')->count(),
            'resolvedCount' => Complaint::query()->where('status', 'resolved')->count(),
            'users' => User::query()->select('id', 'name')->orderBy('name')->get(),
            'rides' => RideRequest::query()->select('id', 'pickup_address', 'dropoff_address')->latest()->limit(25)->get(),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'user_id' => ['required', 'exists:users,id'],
            'ride_request_id' => ['nullable', 'exists:ride_requests,id'],
            'category' => ['required', 'string', 'max:120'],
            'message' => ['required', 'string', 'max:5000'],
        ]);

        Complaint::create($data + ['status' => 'open']);

        return back()->with('status', 'Complaint added.');
    }

    public function resolve(Request $request, Complaint $complaint): RedirectResponse
    {
        $data = $request->validate([
            'resolution_note' => ['required', 'string', 'max:5000'],
        ]);

        $complaint->update([
            'status' => 'resolved',
            'resolution_note' => $data['resolution_note'],
            'resolved_at' => now(),
        ]);

        return back()->with('status', 'Complaint resolved.');
    }
}
