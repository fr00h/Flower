import 'json.dart';

enum OrderStatus {
  newOrder('new', 'Новый'),
  assembling('assembling', 'Собирается'),
  delivering('delivering', 'В доставке'),
  done('done', 'Выполнен'),
  canceled('canceled', 'Отменён');

  final String value;
  final String title;
  const OrderStatus(this.value, this.title);

  static OrderStatus fromValue(String? value) =>
      OrderStatus.values.where((s) => s.value == value).firstOrNull ??
      OrderStatus.newOrder;

  OrderStatus? get next => switch (this) {
    newOrder => assembling,
    assembling => delivering,
    delivering => done,
    _ => null,
  };
}

class OrderItem {
  final String id;
  final String bouquetId;
  final String bouquetName;
  final int quantity;
  final int price;

  const OrderItem({
    this.id = '',
    required this.bouquetId,
    this.bouquetName = '',
    required this.quantity,
    required this.price,
  });

  int get sum => quantity * price;

  Map<String, dynamic> toJson(String orderId) => {
    'order': orderId,
    'bouquet': bouquetId,
    'quantity': quantity,
    'price': price,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: str(json['id']),
    bouquetId: str(json['bouquet']),
    bouquetName: str(expanded(json, 'bouquet')?['name']),
    quantity: integer(json['quantity']),
    price: integer(json['price']),
  );
}

class Delivery {
  static const timeSlots = ['10-14', '14-18', '18-22'];

  final String id;
  final String address;
  final DateTime date;
  final String timeSlot;
  final String recipient;
  final String phone;

  const Delivery({
    this.id = '',
    required this.address,
    required this.date,
    required this.timeSlot,
    required this.recipient,
    required this.phone,
  });

  Map<String, dynamic> toJson(String orderId) => {
    'order': orderId,
    'address': address,
    'date': dateToJson(date),
    'time_slot': timeSlot,
    'recipient': recipient,
    'phone': phone,
  };

  factory Delivery.fromJson(Map<String, dynamic> json) => Delivery(
    id: str(json['id']),
    address: str(json['address']),
    date: parseDate(json['date']) ?? DateTime(2000),
    timeSlot: str(json['time_slot']),
    recipient: str(json['recipient']),
    phone: str(json['phone']),
  );
}

class Order {
  final String id;
  final String userId;
  final String userName;
  final OrderStatus status;
  final int total;
  final String comment;
  final DateTime? created;
  final List<OrderItem> items;
  final Delivery? delivery;

  const Order({
    required this.id,
    required this.userId,
    this.userName = '',
    required this.status,
    required this.total,
    required this.comment,
    this.created,
    this.items = const [],
    this.delivery,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final delivery = expanded(json, 'deliveries_via_order');
    return Order(
      id: str(json['id']),
      userId: str(json['user']),
      userName: str(expanded(json, 'user')?['name']),
      status: OrderStatus.fromValue(json['status'] as String?),
      total: integer(json['total']),
      comment: str(json['comment']),
      created: parseDate(json['created']),
      items: expandedList(
        json,
        'order_items_via_order',
      ).map(OrderItem.fromJson).toList(),
      delivery: delivery == null ? null : Delivery.fromJson(delivery),
    );
  }
}
