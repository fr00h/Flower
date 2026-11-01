import 'json.dart';

class Bouquet {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final int price;
  final String description;
  final bool available;

  const Bouquet({
    required this.id,
    required this.name,
    required this.categoryId,
    this.categoryName = '',
    required this.price,
    required this.description,
    required this.available,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': categoryId,
    'price': price,
    'description': description,
    'available': available,
  };

  factory Bouquet.fromJson(Map<String, dynamic> json) => Bouquet(
    id: str(json['id']),
    name: str(json['name']),
    categoryId: str(json['category']),
    categoryName: str(expanded(json, 'category')?['name']),
    price: integer(json['price']),
    description: str(json['description']),
    available: json['available'] == true,
  );
}
