part of '../main.dart';

class DriverUser {
  const DriverUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.vehiclePlate,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehiclePlate;

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
    );
  }
}
