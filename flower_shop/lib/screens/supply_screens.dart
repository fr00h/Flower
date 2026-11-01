import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/flower.dart';
import '../models/json.dart';
import '../models/list_query.dart';
import '../models/supplier.dart';
import '../models/supply.dart';
import '../state/entity_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_table.dart';
import '../widgets/fields.dart';
import '../widgets/state_views.dart';
import 'entity_detail_screen.dart';
import 'entity_list_screen.dart';

class SupplyListScreen extends StatefulWidget {
  const SupplyListScreen({super.key, required this.query});

  final ListQuery query;

  @override
  State<SupplyListScreen> createState() => _SupplyListScreenState();
}

class _SupplyListScreenState extends State<SupplyListScreen> {
  List<Supplier> _suppliers = [];
  List<Flower> _flowers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final suppliers = context.read<EntityListNotifier<Supplier>>().findAll();
    final flowers = context.read<EntityListNotifier<Flower>>().findAll();
    try {
      _suppliers = await suppliers;
      _flowers = await flowers;
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Widget _dropdown(
    ListQuery q,
    void Function(ListQuery) go,
    String key,
    String all,
    Map<String, String> options,
  ) {
    final value = q.filter(key);
    return DropdownButton<String>(
      value: options.containsKey(value) ? value : '',
      items: [
        DropdownMenuItem(value: '', child: Text(all)),
        for (final e in options.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: (v) => go(q.withFilter(key, v ?? '')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EntityListScreen<Supply>(
      query: widget.query,
      title: 'Поставки',
      searchLabel: 'Поставщик или цветок',
      addLabel: 'Добавить поставку',
      emptyText: 'Поставки не найдены',
      canEdit: true,
      canDelete: true,
      idOf: (s) => s.id,
      nameOf: (s) => '${s.flowerName} от ${formatDate(s.suppliedAt)}',
      filters: (q, go) => [
        _dropdown(q, go, 'supplier', 'Все поставщики', {
          for (final s in _suppliers) s.id: s.name,
        }),
        _dropdown(q, go, 'flower', 'Все цветы', {
          for (final f in _flowers) f.id: f.name,
        }),
      ],
      columns: [
        TableColumnSpec(
          label: 'Дата',
          sortField: 'supplied_at',
          build: (s) => Text(formatDate(s.suppliedAt)),
        ),
        TableColumnSpec(
          label: 'Поставщик',
          sortField: 'supplier.name',
          build: (s) => Text(s.supplierName),
        ),
        TableColumnSpec(
          label: 'Цветок',
          sortField: 'flower.name',
          build: (s) => Text(s.flowerName),
        ),
        TableColumnSpec(
          label: 'Кол-во',
          sortField: 'quantity',
          numeric: true,
          build: (s) => Text('${s.quantity} шт.'),
        ),
        TableColumnSpec(
          label: 'Сумма, ₽',
          numeric: true,
          build: (s) => Text('${s.sum}'),
        ),
      ],
    );
  }
}

class SupplyDetailScreen extends StatelessWidget {
  const SupplyDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return EntityDetailScreen<Supply>(
      id: id,
      path: '/admin/supplies',
      backLabel: 'К поставкам',
      canEdit: true,
      titleOf: (s) => 'Поставка от ${formatDate(s.suppliedAt)}',
      fieldsOf: (s) => {
        'Поставщик': s.supplierName,
        'Цветок': s.flowerName,
        'Количество': '${s.quantity} шт.',
        'Закупочная цена': '${s.price} ₽',
        'Сумма': '${s.sum} ₽',
      },
    );
  }
}

class SupplyFormScreen extends StatefulWidget {
  const SupplyFormScreen({super.key, this.id});

  final String? id;

  bool get isEditing => id != null;

  @override
  State<SupplyFormScreen> createState() => _SupplyFormScreenState();
}

class _SupplyFormScreenState extends State<SupplyFormScreen> {
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _date = TextEditingController(text: formatDate(DateTime.now()));
  String? _supplierId;
  String? _flowerId;
  List<Supplier> _suppliers = [];
  List<Flower> _flowers = [];
  Supply? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final supplies = context.read<EntityListNotifier<Supply>>();
    final suppliers = context.read<EntityListNotifier<Supplier>>();
    final flowers = context.read<EntityListNotifier<Flower>>();
    _suppliers = await suppliers.findAll();
    _flowers = await flowers.findAll();
    if (widget.isEditing) _item = await supplies.findById(widget.id!);
    final item = _item;
    if (item != null) {
      _supplierId = item.supplierId;
      _flowerId = item.flowerId;
      _quantity.text = '${item.quantity}';
      _price.text = '${item.price}';
      _date.text = formatDate(item.suppliedAt);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    _date.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    final item = Supply(
      id: _item?.id ?? '',
      supplierId: _supplierId!,
      flowerId: _flowerId!,
      quantity: int.parse(_quantity.text.trim()),
      price: int.parse(_price.text.trim()),
      suppliedAt: DateTime.parse(_date.text.trim()),
    );
    await context.read<EntityListNotifier<Supply>>().save(
      item,
      isNew: !widget.isEditing,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (widget.isEditing && _item == null) {
      return const EmptyView(text: 'Поставка не найдена');
    }

    return EntityForm(
      title: widget.isEditing ? 'Изменение поставки' : 'Новая поставка',
      isEditing: widget.isEditing,
      donePath: '/admin/supplies',
      onSave: _save,
      fields: [
        DropdownButtonFormField<String>(
          initialValue: _supplierId,
          decoration: fieldDecoration('Поставщик'),
          items: [
            for (final s in _suppliers)
              DropdownMenuItem(value: s.id, child: Text(s.name)),
          ],
          onChanged: (v) => setState(() => _supplierId = v),
          validator: (v) => v == null ? 'Выберите поставщика' : null,
        ),
        DropdownButtonFormField<String>(
          initialValue: _flowerId,
          decoration: fieldDecoration('Цветок'),
          items: [
            for (final f in _flowers)
              DropdownMenuItem(value: f.id, child: Text(f.name)),
          ],
          onChanged: (v) => setState(() => _flowerId = v),
          validator: (v) => v == null ? 'Выберите цветок' : null,
        ),
        TextInput(
          controller: _quantity,
          label: 'Количество, шт.',
          numeric: true,
          validator: V.combine([V.required(), V.integer(min: 1, max: 10000)]),
        ),
        TextInput(
          controller: _price,
          label: 'Закупочная цена за штуку, ₽',
          numeric: true,
          validator: V.combine([V.required(), V.integer(min: 1, max: 10000)]),
        ),
        DateInput(
          controller: _date,
          label: 'Дата поставки',
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        ),
      ],
    );
  }
}
