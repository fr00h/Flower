import 'package:flutter/material.dart';

import '../models/app_user.dart';

class Destination {
  final String path;
  final IconData icon;
  final String label;

  const Destination(this.path, this.icon, this.label);
}

List<Destination> destinationsFor(Role? role) => [
  const Destination('/', Icons.home, 'Главная'),
  const Destination('/bouquets', Icons.local_florist, 'Каталог'),
  if (role == Role.customer) ...const [
    Destination('/cart', Icons.shopping_cart, 'Корзина'),
    Destination('/my-orders', Icons.receipt_long, 'Мои заказы'),
  ],
  if (role == Role.florist)
    const Destination('/orders', Icons.assignment, 'Заказы'),
  if (role == Role.florist || role == Role.admin) ...const [
    Destination('/categories', Icons.category, 'Категории'),
    Destination('/flowers', Icons.spa, 'Цветы'),
  ],
  if (role == Role.admin) ...const [
    Destination('/admin/users', Icons.manage_accounts, 'Пользователи'),
    Destination('/admin/suppliers', Icons.local_shipping, 'Поставщики'),
    Destination('/admin/supplies', Icons.inventory, 'Поставки'),
    Destination('/admin/stats', Icons.bar_chart, 'Сводка'),
  ],
];
