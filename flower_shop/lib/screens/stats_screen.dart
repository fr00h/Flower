import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../repositories/order_repository.dart';
import '../widgets/state_views.dart';

class SalesSummary {
  final int orders;
  final int revenue;
  final int averageCheck;
  final Map<OrderStatus, int> byStatus;
  final List<MapEntry<String, int>> topBouquets;

  const SalesSummary({
    required this.orders,
    required this.revenue,
    required this.averageCheck,
    required this.byStatus,
    required this.topBouquets,
  });

  factory SalesSummary.from(List<Order> orders) {
    final active = orders
        .where((o) => o.status != OrderStatus.canceled)
        .toList();
    final revenue = active.fold(0, (s, o) => s + o.total);
    final counts = <String, int>{};
    for (final o in active) {
      for (final i in o.items) {
        counts[i.bouquetName] = (counts[i.bouquetName] ?? 0) + i.quantity;
      }
    }
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return SalesSummary(
      orders: orders.length,
      revenue: revenue,
      averageCheck: active.isEmpty ? 0 : (revenue / active.length).round(),
      byStatus: {
        for (final s in OrderStatus.values)
          s: orders.where((o) => o.status == s).length,
      },
      topBouquets: top.take(5).toList(),
    );
  }
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<SalesSummary> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final orders = context.read<OrderRepository>();
    setState(() {
      _future = orders.findAll().then(SalesSummary.from);
    });
  }

  Widget _tile(String title, String value) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SalesSummary>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          return ErrorView(message: '${snapshot.error}', onRetry: _load);
        }
        final s = snapshot.data!;
        if (s.orders == 0) return const EmptyView(text: 'Заказов пока нет');
        final maxCount = s.topBouquets.isEmpty ? 1 : s.topBouquets.first.value;
        final theme = Theme.of(context).textTheme;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Сводка продаж', style: theme.headlineSmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _tile('Заказов', '${s.orders}'),
                _tile('Выручка без отменённых', '${s.revenue} ₽'),
                _tile('Средний чек', '${s.averageCheck} ₽'),
              ],
            ),
            const SizedBox(height: 24),
            Text('Заказы по статусам', style: theme.titleMedium),
            for (final e in s.byStatus.entries)
              Text('${e.key.title}: ${e.value}'),
            const SizedBox(height: 24),
            Text('Популярные букеты', style: theme.titleMedium),
            const SizedBox(height: 8),
            for (final e in s.topBouquets)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${e.key} - ${e.value} шт.'),
                    const SizedBox(height: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: LinearProgressIndicator(value: e.value / maxCount),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
