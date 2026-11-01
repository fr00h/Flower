import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../models/json.dart';
import '../models/list_query.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';
import '../state/entity_list_notifier.dart';
import '../widgets/debounced_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/fields.dart';
import '../widgets/state_views.dart';
import 'entity_list_screen.dart';

String orderNumber(Order o) => o.id.substring(0, 6).toUpperCase();

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key, required this.query, required this.mine});

  final ListQuery query;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<EntityListNotifier<Order>>();

    return EntityListScreen<Order>(
      query: query,
      title: mine ? 'Мои заказы' : 'Заказы в работу',
      searchLabel: mine ? 'Комментарий' : 'Покупатель или комментарий',
      emptyText: 'Заказы не найдены',
      idOf: (o) => o.id,
      nameOf: (o) => orderNumber(o),
      filters: (q, go) => [
        DropdownButton<String>(
          value: q.filter('status'),
          items: [
            const DropdownMenuItem(value: '', child: Text('Все статусы')),
            for (final s in OrderStatus.values)
              DropdownMenuItem(value: s.value, child: Text(s.title)),
          ],
          onChanged: (v) => go(q.withFilter('status', v ?? '')),
        ),
        DebouncedField(
          label: 'С (ГГГГ-ММ-ДД)',
          value: q.filter('from'),
          width: 160,
          numeric: true,
          onChanged: (v) =>
              go(q.withFilter('from', V.date()(v) == null ? v : '')),
        ),
        DebouncedField(
          label: 'По (ГГГГ-ММ-ДД)',
          value: q.filter('to'),
          width: 160,
          numeric: true,
          onChanged: (v) =>
              go(q.withFilter('to', V.date()(v) == null ? v : '')),
        ),
      ],
      extraActions: mine
          ? null
          : (o) => [
              if (o.status.next != null)
                IconButton(
                  tooltip: 'Перевести: ${o.status.next!.title}',
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await context.read<OrderRepository>().setStatus(
                        o.id,
                        o.status.next!,
                      );
                      await notifier.load();
                    } on ApiException catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.message)),
                      );
                    }
                  },
                ),
            ],
      columns: [
        TableColumnSpec(label: 'Номер', build: (o) => Text(orderNumber(o))),
        TableColumnSpec(
          label: 'Дата',
          sortField: 'created',
          build: (o) => Text(formatDate(o.created)),
        ),
        if (!mine)
          TableColumnSpec(
            label: 'Покупатель',
            sortField: 'user.name',
            build: (o) => Text(o.userName),
          ),
        TableColumnSpec(
          label: 'Сумма, ₽',
          sortField: 'total',
          numeric: true,
          build: (o) => Text('${o.total}'),
        ),
        TableColumnSpec(
          label: 'Статус',
          sortField: 'status',
          build: (o) => Text(o.status.title),
        ),
      ],
    );
  }
}

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.id, required this.mine});

  final String id;
  final bool mine;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<Order?> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<OrderRepository>().findById(widget.id);
  }

  void _reload() {
    final future = context.read<OrderRepository>().findById(widget.id);
    setState(() {
      _future = future;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = context.read<EntityListNotifier<Order>>();
    try {
      await action();
      notifier.load();
      _reload();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _editDelivery(Order order) async {
    final delivery = order.delivery!;
    final repository = context.read<OrderRepository>();
    final result = await showDialog<Delivery>(
      context: context,
      builder: (context) => _DeliveryDialog(delivery: delivery),
    );
    if (result == null) return;
    await _run(() => repository.updateDelivery(order.id, result));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Order?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          return ErrorView(
            message: 'Не удалось загрузить заказ: ${snapshot.error}',
            onRetry: _reload,
          );
        }
        final order = snapshot.data;
        if (order == null) return const EmptyView(text: 'Заказ не найден');
        final delivery = order.delivery;
        final repository = context.read<OrderRepository>();
        final theme = Theme.of(context).textTheme;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Заказ ${orderNumber(order)}',
                          style: theme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text('Статус: ${order.status.title}'),
                        Text('Оформлен: ${formatDate(order.created)}'),
                        if (!widget.mine) Text('Покупатель: ${order.userName}'),
                        if (order.comment.isNotEmpty)
                          Text('Комментарий: ${order.comment}'),
                        const SizedBox(height: 16),
                        Text('Состав', style: theme.titleMedium),
                        for (final i in order.items)
                          Text(
                            '${i.bouquetName} - ${i.quantity} шт. × ${i.price} ₽',
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Итого со скидкой: ${order.total} ₽',
                          style: theme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Text('Доставка', style: theme.titleMedium),
                        if (delivery == null)
                          const Text('Не указана')
                        else ...[
                          Text(delivery.address),
                          Text(
                            '${formatDate(delivery.date)}, с ${delivery.timeSlot.replaceAll('-', ' до ')} ч.',
                          ),
                          Text(
                            'Получатель: ${delivery.recipient}, ${delivery.phone}',
                          ),
                        ],
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: () => context.go(
                                widget.mine ? '/my-orders' : '/orders',
                              ),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('К заказам'),
                            ),
                            if (!widget.mine && order.status.next != null)
                              FilledButton(
                                onPressed: () => _run(
                                  () => repository.setStatus(
                                    order.id,
                                    order.status.next!,
                                  ),
                                ),
                                child: Text(order.status.next!.title),
                              ),
                            if (!widget.mine &&
                                order.status == OrderStatus.newOrder)
                              OutlinedButton(
                                onPressed: () => _run(
                                  () => repository.setStatus(
                                    order.id,
                                    OrderStatus.canceled,
                                  ),
                                ),
                                child: const Text('Отменить'),
                              ),
                            if (!widget.mine && delivery != null)
                              OutlinedButton(
                                onPressed: () => _editDelivery(order),
                                child: const Text('Изменить доставку'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DeliveryFields extends StatelessWidget {
  const DeliveryFields({
    super.key,
    required this.address,
    required this.date,
    required this.recipient,
    required this.phone,
    required this.timeSlot,
    required this.onTimeSlot,
  });

  final TextEditingController address;
  final TextEditingController date;
  final TextEditingController recipient;
  final TextEditingController phone;
  final String? timeSlot;
  final ValueChanged<String?> onTimeSlot;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Column(
      children: [
        TextInput(
          controller: address,
          label: 'Адрес доставки',
          validator: V.combine([V.required(), V.length(min: 5, max: 200)]),
        ),
        const SizedBox(height: 16),
        DateInput(
          controller: date,
          label: 'Дата доставки',
          firstDate: today,
          lastDate: today.add(const Duration(days: 30)),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: timeSlot,
          decoration: fieldDecoration('Время доставки'),
          items: [
            for (final s in Delivery.timeSlots)
              DropdownMenuItem(
                value: s,
                child: Text('с ${s.replaceAll('-', ' до ')} ч.'),
              ),
          ],
          onChanged: onTimeSlot,
          validator: (v) => v == null ? 'Выберите время' : null,
        ),
        const SizedBox(height: 16),
        TextInput(
          controller: recipient,
          label: 'Получатель',
          validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
        ),
        const SizedBox(height: 16),
        TextInput(
          controller: phone,
          label: 'Телефон получателя',
          validator: V.combine([V.required(), V.phone()]),
        ),
      ],
    );
  }
}

class _DeliveryDialog extends StatefulWidget {
  const _DeliveryDialog({required this.delivery});

  final Delivery delivery;

  @override
  State<_DeliveryDialog> createState() => _DeliveryDialogState();
}

class _DeliveryDialogState extends State<_DeliveryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _address = TextEditingController(text: widget.delivery.address);
  late final _date = TextEditingController(
    text: formatDate(widget.delivery.date),
  );
  late final _recipient = TextEditingController(
    text: widget.delivery.recipient,
  );
  late final _phone = TextEditingController(text: widget.delivery.phone);
  late String? _timeSlot = widget.delivery.timeSlot;

  @override
  void dispose() {
    _address.dispose();
    _date.dispose();
    _recipient.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Доставка'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: DeliveryFields(
              address: _address,
              date: _date,
              recipient: _recipient,
              phone: _phone,
              timeSlot: _timeSlot,
              onTimeSlot: (v) => setState(() => _timeSlot = v),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              Delivery(
                id: widget.delivery.id,
                address: _address.text.trim(),
                date: DateTime.parse(_date.text.trim()),
                timeSlot: _timeSlot!,
                recipient: _recipient.text.trim(),
                phone: _phone.text.trim(),
              ),
            );
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
