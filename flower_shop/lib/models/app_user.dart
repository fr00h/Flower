import 'json.dart';

enum Role {
  customer('Покупатель'),
  florist('Флорист'),
  admin('Администратор');

  final String title;
  const Role(this.title);

  static Role fromName(String? name) =>
      Role.values.where((r) => r.name == name).firstOrNull ?? Role.customer;
}

class AppUser {
  final String id;
  final String email;
  final String name;
  final Role role;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  bool get isStaff => role == Role.florist || role == Role.admin;

  AppUser copyWith({Role? role}) =>
      AppUser(id: id, email: email, name: name, role: role ?? this.role);

  Map<String, dynamic> toJson() => {'name': name, 'role': role.name};

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: str(json['id']),
    email: str(json['email']),
    name: str(json['name']),
    role: Role.fromName(json['role'] as String?),
  );
}
