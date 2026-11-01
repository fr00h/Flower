import 'package:flower_shop/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('телефон проверяется по формату', () {
    expect(V.phone()('+7 900 123-45-67'), isNull);
    expect(V.phone()('89001234567'), isNotNull);
  });

  test('цена должна быть в диапазоне', () {
    final v = V.combine([V.required(), V.integer(min: 1, max: 100000)]);
    expect(v(''), 'Поле обязательно');
    expect(v('0'), isNotNull);
    expect(v('2500'), isNull);
  });

  test('пароль требует цифру и спецсимвол', () {
    expect(V.password()('flowers12'), isNotNull);
    expect(V.password()('flowers12!'), isNull);
  });
}
