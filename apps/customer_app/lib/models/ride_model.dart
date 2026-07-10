class RideDraft {
  const RideDraft({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.rideName,
    required this.price,
    required this.eta,
    this.status = 'open',
    this.offersCount = 0,
  });

  final int id;
  final String pickup;
  final String destination;
  final String rideName;
  final String price;
  final String eta;
  final String status;
  final int offersCount;

  factory RideDraft.fromJson(Map<String, dynamic> json) {
    return RideDraft(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      pickup: json['pickup_address']?.toString() ?? '',
      destination: json['dropoff_address']?.toString() ?? '',
      rideName: 'طلب جديد',
      price: 'بانتظار العرض',
      eta: 'بانتظار السائق',
      status: json['status']?.toString() ?? 'open',
      offersCount: _offersCount(json['offers']),
    );
  }

  String get statusLabel {
    return switch (status) {
      'requested' => 'بانتظار العروض',
      'open' => 'بانتظار العروض',
      'accepted' => 'تم اختيار سائق',
      'in_progress' => 'الرحلة قيد التنفيذ',
      'completed' => 'مكتملة',
      'cancelled' => 'ملغية',
      _ => 'بانتظار العروض',
    };
  }

  static int _offersCount(Object? value) {
    if (value is Map) return value.length;
    if (value is List) return value.length;
    return 0;
  }
}
