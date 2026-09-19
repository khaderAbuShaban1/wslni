part of '../main.dart';

class DriverUser {
  const DriverUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.vehiclePlate,
    this.avatarPath,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehiclePlate;
  final String? avatarPath;

  factory DriverUser.fromJson(Map<String, dynamic> json) {
    final profile = json['driver_profile'];
    final profileMap = profile is Map ? profile : {};
    return DriverUser(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'سائق',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      vehicleType: profileMap['vehicle_type']?.toString() ?? '',
      vehiclePlate: profileMap['vehicle_plate']?.toString() ?? '',
      avatarPath: _nonEmpty(json['avatar_path']),
    );
  }

  /// Same shape as the API payload, so [DriverUser.fromJson] reads it back.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'avatar_path': avatarPath,
    'driver_profile': {
      'vehicle_type': vehicleType,
      'vehicle_plate': vehiclePlate,
    },
  };

  DriverUser copyWith({
    String? name,
    String? phone,
    String? vehicleType,
    String? vehiclePlate,
    String? avatarPath,
    bool clearAvatar = false,
  }) {
    return DriverUser(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      avatarPath: clearAvatar ? null : avatarPath ?? this.avatarPath,
    );
  }
}
