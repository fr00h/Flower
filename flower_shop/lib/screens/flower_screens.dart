import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/flower.dart';
import '../models/list_query.dart';
import '../state/auth_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_table.dart';
import '../widgets/fields.dart';
import '../widgets/state_views.dart';
import 'entity_detail_screen.dart';
import 'entity_list_screen.dart';

class FlowerListScreen extends StatelessWidget {
  const FlowerListScreen({super.key, required this.query});

  final ListQuery query;

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<AuthNotifier>().isStaff;

    return EntityListScreen<Flower>(
      query: query,
      title: 'Цветы',
      searchLabel: 'Название или цвет',
      addLabel: 'Добавить цветок',
      emptyText: 'Цветы не найдены',
      canEdit: staff,
      canDelete: staff,
      idOf: (f) => f.id,
      nameOf: (f) => f.name,
      columns: [
        TableColumnSpec(
          label: 'Название',
          sortField: 'name',
          build: (f) => Text(f.name),
        ),
        TableColumnSpec(
          label: 'Цвет',
          sortField: 'color',
          build: (f) => Text(f.color),
        ),
        TableColumnSpec(
          label: 'Цена за шт., ₽',
          sortField: 'price',
          numeric: true,
          build: (f) => Text('${f.price}'),
        ),
        TableColumnSpec(
          label: 'На складе',
          sortField: 'stock',
          numeric: true,
          build: (f) => Text('${f.stock} шт.'),
        ),
      ],
    );
  }
}

class FlowerDetailScreen extends StatelessWidget {
  const FlowerDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return EntityDetailScreen<Flower>(
      id: id,
      path: '/flowers',
      backLabel: 'К цветам',
      canEdit: context.watch<AuthNotifier>().isStaff,
      titleOf: (f) => f.name,
      fieldsOf: (f) => {
        'Цвет': f.color,
        'Цена за штуку': '${f.price} ₽',
        'На складе': '${f.stock} шт.',
      },
    );
  }
}

class FlowerFormScreen extends StatefulWidget {
  const FlowerFormScreen({super.key, this.id});

  final String? id;

  bool get isEditing => id != null;

  @override
  State<FlowerFormScreen> createState() => _FlowerFormScreenState();
}

class _FlowerFormScreenState extends State<FlowerFormScreen> {
  final _name = TextEditingController();
  final _color = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  Flower? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.isEditing) {
      _item = await context.read<EntityListNotifier<Flower>>().findById(
        widget.id!,
      );
    }
    final item = _item;
    if (item != null) {
      _name.text = item.name;
      _color.text = item.color;
      _price.text = '${item.price}';
      _stock.text = '${item.stock}';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _color.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    final item = Flower(
      id: _item?.id ?? '',
      name: _name.text.trim(),
      color: _color.text.trim(),
      price: int.parse(_price.text.trim()),
      stock: int.parse(_stock.text.trim()),
    );
    await context.read<EntityListNotifier<Flower>>().save(
      item,
      isNew: !widget.isEditing,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (widget.isEditing && _item == null) {
      return const EmptyView(text: 'Цветок не найден');
    }

    return EntityForm(
      title: widget.isEditing ? 'Изменение цветка' : 'Новый цветок',
      isEditing: widget.isEditing,
      donePath: '/flowers',
      onSave: _save,
      fields: [
        TextInput(
          controller: _name,
          label: 'Название',
          validator: V.combine([V.required(), V.length(min: 2, max: 50)]),
        ),
        TextInput(
          controller: _color,
          label: 'Цвет',
          validator: V.length(max: 30),
        ),
        TextInput(
          controller: _price,
          label: 'Цена за штуку, ₽',
          numeric: true,
          validator: V.combine([V.required(), V.integer(min: 1, max: 10000)]),
        ),
        TextInput(
          controller: _stock,
          label: 'Остаток на складе, шт.',
          numeric: true,
          validator: V.combine([V.required(), V.integer(min: 0, max: 100000)]),
        ),
      ],
    );
  }
}
