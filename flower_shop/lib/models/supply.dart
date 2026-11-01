import 'json.dart';

class Supply {
  final String id;
  final String supplierId;
  final String supplierName;
  final String flowerId;
  final String flowerName;
  final int quantity;
  final int price;
  final DateTime suppliedAt;

  const Supply({
    required this.id,
    required this.supplierId,
    this.supplierName = '',
    required this.flowerId,
    this.flowerName = '',
    required this.quantity,
    required this.price,
    required this.suppliedAt,
  });

  int get sum => quantity * price;

  Map<String, dynamic> toJson() => {
    'supplier': supplierId,
    'flower': flowerId,
    'quantity': quantity,
    'price': price,
    'supplied_at': dateToJson(suppliedAt),
  };

  factory Supply.fromJson(Map<String, dynamic> json) => Supply(
    id: str(json['id']),
    supplierId: str(json['supplier']),
    supplierName: str(expanded(json, 'supplier')?['name']),
    flowerId: str(json['flower']),
    flowerName: str(expanded(json, 'flower')?['name']),
    quantity: integer(json['quantity']),
    price: integer(json['price']),
    suppliedAt: parseDate(json['supplied_at']) ?? DateTime(2000),
  );
}
