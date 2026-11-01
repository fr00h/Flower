import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/app_user.dart';

class AuthResult {
  final String token;
  final AppUser user;

  const AuthResult(this.token, this.user);

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    json['token'] as String,
    AppUser.fromJson(json['record'] as Map<String, dynamic>),
  );
}

class AuthApi {
  static const _path = '/collections/users';

  final Dio _dio;

  AuthApi(this._dio);

  Future<AuthResult> login(String email, String password) => guard(() async {
    final response = await _dio.post(
      '$_path/auth-with-password',
      data: {'identity': email, 'password': password},
    );
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  });

  Future<AuthResult> refresh() => guard(() async {
    final response = await _dio.post('$_path/auth-refresh');
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  });

  Future<void> register(String email, String password, String name) => guard(
    () => _dio.post(
      '$_path/records',
      data: {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'name': name,
        'role': Role.customer.name,
      },
    ),
  );
}
