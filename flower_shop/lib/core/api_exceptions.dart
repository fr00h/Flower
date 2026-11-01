import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте, что PocketBase запущен.',
  ]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход в систему.']);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'Недостаточно прав для этого действия.',
  ]);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.']);
}

class ConflictException extends ApiException {
  const ConflictException(super.message);
}

class ValidationException extends ApiException {
  final Map<String, String> errors;
  const ValidationException(super.message, this.errors);
}

class ServerException extends ApiException {
  const ServerException([
    super.message = 'Ошибка на сервере. Попробуйте позже.',
  ]);
}

const _codes = {
  'validation_required': 'Поле обязательно',
  'validation_not_unique': 'Такое значение уже есть',
  'validation_invalid_email': 'Некорректный адрес почты',
  'validation_invalid_format': 'Неверный формат',
  'validation_min_text_constraint': 'Слишком короткое значение',
  'validation_max_text_constraint': 'Слишком длинное значение',
  'validation_min_number_constraint': 'Слишком маленькое число',
  'validation_max_number_constraint': 'Слишком большое число',
};

ApiException mapHttpError(int status, dynamic body) {
  final message = (body is Map && body['message'] is String)
      ? body['message'] as String
      : '';
  final data = (body is Map && body['data'] is Map)
      ? body['data'] as Map
      : const {};

  if (status == 400 && data.isNotEmpty) {
    return ValidationException(
      'Проверьте поля формы',
      data.map((key, value) {
        final code = value is Map ? '${value['code']}' : '';
        final text = value is Map ? '${value['message']}' : '$value';
        return MapEntry('$key', _codes[code] ?? text);
      }),
    );
  }
  if (status == 400 && message.contains('relation reference')) {
    return const ConflictException(
      'Запись нельзя удалить: на неё ссылаются другие записи.',
    );
  }
  if (status == 400 && message.contains('authenticate')) {
    return const UnauthorizedException('Неверная почта или пароль.');
  }

  return switch (status) {
    400 => const ForbiddenException('Операция не выполнена: нет прав.'),
    401 => const UnauthorizedException(),
    403 => const ForbiddenException(),
    404 => const NotFoundException(),
    409 => ConflictException(
      message.isEmpty ? 'Операция невозможна.' : message,
    ),
    _ => ServerException('Неизвестная ошибка (код $status).'),
  };
}

ApiException mapDioError(DioException e) {
  final existing = e.error;
  if (existing is ApiException) return existing;

  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const NetworkException(
      'Сервер не ответил вовремя.',
    ),
    DioExceptionType.connectionError => const NetworkException(),
    DioExceptionType.cancel => const NetworkException('Запрос отменён.'),
    _ => const ServerException(),
  };
}

Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}

String pbText(String value) =>
    '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
