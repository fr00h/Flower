import 'json.dart';

class Category {
  final String id;
  final String name;
  final String description;

  const Category({
    required this.id,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() => {'name': name, 'description': description};

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: str(json['id']),
    name: str(json['name']),
    description: str(json['description']),
  );
}
