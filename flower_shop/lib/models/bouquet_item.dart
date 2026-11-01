import 'json.dart';

class BouquetItem {
  final String id;
  final String bouquetId;
  final String flowerId;
  final String flowerName;
  final int quantity;

  const BouquetItem({
    required this.id,
    required this.bouquetId,
    required this.flowerId,
    this.flowerName = '',
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    'bouquet': bouquetId,
    'flower': flowerId,
    'quantity': quantity,
  };

  factory BouquetItem.fromJson(Map<String, dynamic> json) => BouquetItem(
    id: str(json['id']),
    bouquetId: str(json['bouquet']),
    flowerId: str(json['flower']),
    flowerName: str(expanded(json, 'flower')?['name']),
    quantity: integer(json['quantity']),
  );
}
