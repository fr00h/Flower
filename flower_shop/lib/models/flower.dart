import 'json.dart';

class Flower {
  final String id;
  final String name;
  final String color;
  final int price;
  final int stock;

  const Flower({
    required this.id,
    required this.name,
    required this.color,
    required this.price,
    required this.stock,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'color': color,
    'price': price,
    'stock': stock,
  };

  factory Flower.fromJson(Map<String, dynamic> json) => Flower(
    id: str(json['id']),
    name: str(json['name']),
    color: str(json['color']),
    price: integer(json['price']),
    stock: integer(json['stock']),
  );
}
