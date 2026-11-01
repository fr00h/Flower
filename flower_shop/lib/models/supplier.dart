import 'json.dart';

class Supplier {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String city;

  const Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.city,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'city': city,
  };

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
    id: str(json['id']),
    name: str(json['name']),
    phone: str(json['phone']),
    email: str(json['email']),
    city: str(json['city']),
  );
}
