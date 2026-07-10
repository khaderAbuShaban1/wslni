class DriverOffer {
  const DriverOffer({
    required this.id,
    required this.driverId,
    required this.name,
    required this.rating,
    required this.car,
    required this.price,
    required this.eta,
  });

  final int id;
  final int driverId;
  final String name;
  final String rating;
  final String car;
  final String price;
  final String eta;
}
