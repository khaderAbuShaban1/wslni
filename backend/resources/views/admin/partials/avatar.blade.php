{{-- Usage: @include('admin.partials.avatar', ['user' => $user, 'size' => 38]) --}}
@php
    $size = $size ?? 38;
    $name = trim((string) ($user?->name ?? ''));
    $initial = $name === '' ? '?' : mb_substr($name, 0, 1);
@endphp
@if ($user?->avatar_path)
    <img class="avatar" src="{{ asset('storage/'.$user->avatar_path) }}" alt="{{ $name }}" loading="lazy"
         style="width: {{ $size }}px; height: {{ $size }}px;">
@else
    <span class="avatar avatar-fallback" aria-hidden="true"
          style="width: {{ $size }}px; height: {{ $size }}px; font-size: {{ round($size * 0.42) }}px;">{{ $initial }}</span>
@endif
