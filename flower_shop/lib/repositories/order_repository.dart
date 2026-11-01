import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/list_query.dart';
import '../models/order.dart';
import '../models/page_result.dart';
import 'pb_repository.dart';

class OrderRepository {
  final Dio _dio;
  final PbRepository<Order> orders;

  OrderRepository(this._dio)
    : orders = PbRepository<Order>(
        _dio,
        'orders',
        Order.fromJson,
        (o) => {'status': o.status.value},
        (o) => o.id,
        searchFields: ['user.name', 'comment'],
        expand: 'user,order_items_via_order.bouquet,deliveries_via_order',
        conditions: (q) => [
          if (q.filter('status').isNotEmpty)
            'status=${pbText(q.filter('status'))}',
          if (q.filter('from').isNotEmpty)
            'created>=${pbText('${q.filter('from')} 00:00:00')}',
          if (q.filter('to').isNotEmpty)
            'created<=${pbText('${q.filter('to')} 23:59:59')}',
        ],
      );

  Future<PageResult<Order>> find(ListQuery query) => orders.find(query);

  Future<List<Order>> findAll() => orders.findAll();

  Future<Order?> findById(String id) => orders.findById(id);

  Future<void> setStatus(String id, OrderStatus status) => guard(
    () => _dio.patch(
      '/collections/orders/records/$id',
      data: {'status': status.value},
    ),
  );

  Future<void> updateDelivery(String orderId, Delivery delivery) => guard(
    () => _dio.patch(
      '/collections/deliveries/records/${delivery.id}',
      data: delivery.toJson(orderId),
    ),
  );

  Future<String> create({
    required String userId,
    required List<OrderItem> items,
    required Delivery delivery,
    required int total,
    required String comment,
  }) => guard(() async {
    final response = await _dio.post(
      '/collections/orders/records',
      data: {
        'user': userId,
        'status': OrderStatus.newOrder.value,
        'total': total,
        'comment': comment,
      },
    );
    final id = (response.data as Map<String, dynamic>)['id'] as String;
    for (final item in items) {
      await _dio.post(
        '/collections/order_items/records',
        data: item.toJson(id),
      );
    }
    await _dio.post(
      '/collections/deliveries/records',
      data: delivery.toJson(id),
    );
    return id;
  });
}
