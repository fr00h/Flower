import 'package:flower_shop/models/app_user.dart';
import 'package:flower_shop/models/bouquet.dart';
import 'package:flower_shop/models/order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Bouquet.fromJson берёт категорию из expand', () {
    final b = Bouquet.fromJson({
      'id': 'b1',
      'name': 'Алые розы',
      'category': 'c1',
      'price': 3900,
      'available': true,
      'expand': {
        'category': {'id': 'c1', 'name': 'Классика'},
      },
    });

    expect(b.categoryId, 'c1');
    expect(b.categoryName, 'Классика');
    expect(b.toJson()['category'], 'c1');
  });

  test('Order.fromJson разбирает позиции и доставку', () {
    final o = Order.fromJson({
      'id': 'abcdef123',
      'user': 'u1',
      'status': 'assembling',
      'total': 4370,
      'expand': {
        'order_items_via_order': [
          {
            'bouquet': 'b1',
            'quantity': 2,
            'price': 2300,
            'expand': {
              'bouquet': {'name': 'Весенний'},
            },
          },
        ],
        'deliveries_via_order': {
          'address': 'пр. Мира, 20',
          'date': '2026-11-02 12:00:00.000Z',
          'time_slot': '14-18',
          'recipient': 'Смирнов Олег',
          'phone': '+7 900 111-22-34',
        },
      },
    });

    expect(o.status, OrderStatus.assembling);
    expect(o.items.single.bouquetName, 'Весенний');
    expect(o.items.single.sum, 4600);
    expect(o.delivery?.timeSlot, '14-18');
  });

  test('статусы заказа идут по порядку', () {
    expect(OrderStatus.newOrder.next, OrderStatus.assembling);
    expect(OrderStatus.delivering.next, OrderStatus.done);
    expect(OrderStatus.canceled.next, isNull);
  });

  test('роль определяется по имени, неизвестная - покупатель', () {
    final user = AppUser.fromJson({'id': '1', 'role': 'florist'});
    expect(user.isStaff, isTrue);
    expect(Role.fromName('boss'), Role.customer);
  });
}
