import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../models/customer_card.dart';
import '../models/order.dart';
import '../repositories/entity_repository.dart';
import '../state/auth_notifier.dart';
import '../state/cart_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../widgets/fields.dart';
import '../widgets/state_views.dart';
import 'order_screens.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _date = TextEditingController();
  final _recipient = TextEditingController();
  final _phone = TextEditingController();
  final _comment = TextEditingController();
  String? _timeSlot;
  CustomerCard? _card;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _recipient.text = context.read<AuthNotifier>().user?.name ?? '';
    _loadCard();
  }

  Future<void> _loadCard() async {
    final userId = context.read<AuthNotifier>().user!.id;
    try {
      final cards = await context
          .read<EntityRepository<CustomerCard>>()
          .findAll(filter: 'user="$userId"');
      if (mounted) setState(() => _card = cards.firstOrNull);
    } on ApiException catch (_) {}
  }

  @override
  void dispose() {
    _address.dispose();
    _date.dispose();
    _recipient.dispose();
    _phone.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _checkout() async {
    if (!_formKey.currentState!.validate()) return;
    final cart = context.read<CartNotifier>();
    final orders = context.read<EntityListNotifier<Order>>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _saving = true);
    try {
      final id = await cart.checkout(
        userId: context.read<AuthNotifier>().user!.id,
        discount: _card?.discount ?? 0,
        comment: _comment.text.trim(),
        delivery: Delivery(
          address: _address.text.trim(),
          date: DateTime.parse(_date.text.trim()),
          timeSlot: _timeSlot!,
          recipient: _recipient.text.trim(),
          phone: _phone.text.trim(),
        ),
      );
      orders.load();
      messenger.showSnackBar(const SnackBar(content: Text('Заказ оформлен')));
      router.go('/my-orders/$id');
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartNotifier>();
    if (cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyView(text: 'Корзина пуста'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/bouquets'),
              child: const Text('Перейти в каталог'),
            ),
          ],
        ),
      );
    }
    final discount = _card?.discount ?? 0;
    final theme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Корзина', style: theme.headlineSmall),
                  const SizedBox(height: 8),
                  for (final line in cart.lines)
                    Card(
                      child: ListTile(
                        title: Text(
                          line.bouquet.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${line.bouquet.price} ₽ × ${line.quantity} = ${line.sum} ₽',
                        ),
                        trailing: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Меньше',
                              icon: const Icon(Icons.remove),
                              onPressed: () => cart.setQuantity(
                                line.bouquet,
                                line.quantity - 1,
                              ),
                            ),
                            Text('${line.quantity}'),
                            IconButton(
                              tooltip: 'Больше',
                              icon: const Icon(Icons.add),
                              onPressed: () => cart.setQuantity(
                                line.bouquet,
                                line.quantity + 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text('Сумма: ${cart.sum} ₽'),
                  Text(
                    _card == null
                        ? 'Карты покупателя нет, скидка 0%'
                        : 'Карта ${_card!.number}, скидка $discount%',
                  ),
                  Text(
                    'К оплате: ${cart.totalWith(discount)} ₽',
                    style: theme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  Text('Доставка', style: theme.titleMedium),
                  const SizedBox(height: 16),
                  DeliveryFields(
                    address: _address,
                    date: _date,
                    recipient: _recipient,
                    phone: _phone,
                    timeSlot: _timeSlot,
                    onTimeSlot: (v) => setState(() => _timeSlot = v),
                  ),
                  const SizedBox(height: 16),
                  TextInput(
                    controller: _comment,
                    label: 'Комментарий к заказу',
                    maxLines: 2,
                    validator: V.length(max: 300),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _checkout,
                    child: const Text('Оформить заказ'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
