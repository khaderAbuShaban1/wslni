class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.walletBalance = 0,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final double walletBalance;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'راكب',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      walletBalance:
          double.tryParse(json['wallet_balance']?.toString() ?? '') ?? 0,
    );
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    double? walletBalance,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      walletBalance: walletBalance ?? this.walletBalance,
    );
  }
}
