import 'json.dart';

class CustomerCard {
  final String id;
  final String userId;
  final String number;
  final int discount;

  const CustomerCard({
    required this.id,
    required this.userId,
    required this.number,
    required this.discount,
  });

  Map<String, dynamic> toJson() => {
    'user': userId,
    'number': number,
    'discount': discount,
  };

  factory CustomerCard.fromJson(Map<String, dynamic> json) => CustomerCard(
    id: str(json['id']),
    userId: str(json['user']),
    number: str(json['number']),
    discount: integer(json['discount']),
  );
}
