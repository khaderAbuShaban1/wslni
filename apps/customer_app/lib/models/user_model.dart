class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'customer',
    this.walletBalance = 0,
    this.avatarPath,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final double walletBalance;
  final String? avatarPath;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar_path']?.toString();
    return AppUser(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'راكب',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      walletBalance:
          double.tryParse(json['wallet_balance']?.toString() ?? '') ?? 0,
      avatarPath: avatar == null || avatar.isEmpty ? null : avatar,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'wallet_balance': walletBalance,
    'avatar_path': avatarPath,
  };

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    double? walletBalance,
    String? avatarPath,
    bool clearAvatar = false,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      walletBalance: walletBalance ?? this.walletBalance,
      avatarPath: clearAvatar ? null : avatarPath ?? this.avatarPath,
    );
  }
}
