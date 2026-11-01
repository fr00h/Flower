import 'package:flutter/foundation.dart';

import '../models/bouquet.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';

class CartLine {
  final Bouquet bouquet;
  final int quantity;

  const CartLine(this.bouquet, this.quantity);

  int get sum => bouquet.price * quantity;
}

class CartNotifier extends ChangeNotifier {
  final OrderRepository _orders;

  CartNotifier(this._orders);

  final Map<String, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList();
  bool get isEmpty => _lines.isEmpty;
  int get count => _lines.values.fold(0, (s, l) => s + l.quantity);
  int get sum => _lines.values.fold(0, (s, l) => s + l.sum);

  int totalWith(int discount) => (sum * (100 - discount) / 100).round();

  void add(Bouquet bouquet) {
    final line = _lines[bouquet.id];
    setQuantity(bouquet, (line?.quantity ?? 0) + 1);
  }

  void setQuantity(Bouquet bouquet, int quantity) {
    if (quantity <= 0) {
      _lines.remove(bouquet.id);
    } else {
      _lines[bouquet.id] = CartLine(bouquet, quantity.clamp(1, 50));
    }
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }

  Future<String> checkout({
    required String userId,
    required int discount,
    required Delivery delivery,
    required String comment,
  }) async {
    final id = await _orders.create(
      userId: userId,
      items: [
        for (final l in _lines.values)
          OrderItem(
            bouquetId: l.bouquet.id,
            quantity: l.quantity,
            price: l.bouquet.price,
          ),
      ],
      delivery: delivery,
      total: totalWith(discount),
      comment: comment,
    );
    clear();
    return id;
  }
}
