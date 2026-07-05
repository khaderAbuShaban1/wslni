class RideDraft {
  const RideDraft({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.rideName,
    required this.price,
    required this.eta,
  });

  final int id;
  final String pickup;
  final String destination;
  final String rideName;
  final String price;
  final String eta;

  factory RideDraft.fromJson(Map<String, dynamic> json) {
    return RideDraft(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      pickup: json['pickup_address']?.toString() ?? '',
      destination: json['dropoff_address']?.toString() ?? '',
      rideName: 'طلب جديد',
      price: 'بانتظار العرض',
      eta: 'بانتظار السائق',
    );
  }
}
