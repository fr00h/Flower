import 'package:flower_shop/core/api_exceptions.dart';
import 'package:flower_shop/models/list_query.dart';
import 'package:flower_shop/models/order.dart';
import 'package:flower_shop/screens/stats_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('условия отбора попадают в адрес и читаются обратно', () {
    final q = ListQuery.fromParams('/bouquets', 'name', {})
        .withFilter('category', 'c1')
        .copyWith(sortField: 'price', sortAscending: false);
    final back = ListQuery.fromParams(
      '/bouquets',
      'name',
      Uri.parse(q.location).queryParameters,
    );

    expect(back.filter('category'), 'c1');
    expect(back.pbSort, '-price');
  });

  test('ошибка поля от PocketBase попадает в ValidationException', () {
    final e = mapHttpError(400, {
      'message': 'Failed to create record.',
      'data': {
        'email': {
          'code': 'validation_not_unique',
          'message': 'Value must be unique.',
        },
      },
    });

    expect(e, isA<ValidationException>());
    expect(
      (e as ValidationException).errors['email'],
      'Такое значение уже есть',
    );
  });

  test('сводка продаж не учитывает отменённые заказы', () {
    const item = OrderItem(
      bouquetId: 'b1',
      bouquetName: 'Весенний',
      quantity: 2,
      price: 2300,
    );
    final s = SalesSummary.from(const [
      Order(
        id: '1',
        userId: 'u',
        status: OrderStatus.done,
        total: 4600,
        comment: '',
        items: [item],
      ),
      Order(
        id: '2',
        userId: 'u',
        status: OrderStatus.canceled,
        total: 9000,
        comment: '',
        items: [item],
      ),
    ]);

    expect(s.orders, 2);
    expect(s.revenue, 4600);
    expect(s.topBouquets.single.value, 2);
  });
}
