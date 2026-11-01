import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../models/app_user.dart';
import '../models/bouquet.dart';
import '../models/bouquet_item.dart';
import '../models/category.dart';
import '../models/flower.dart';
import '../models/list_query.dart';
import '../repositories/entity_repository.dart';
import '../state/auth_notifier.dart';
import '../state/cart_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../widgets/debounced_field.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_table.dart';
import '../widgets/fields.dart';
import '../widgets/multi_select_field.dart';
import '../widgets/state_views.dart';
import 'entity_detail_screen.dart';
import 'entity_list_screen.dart';

void addToCart(BuildContext context, Bouquet bouquet) {
  context.read<CartNotifier>().add(bouquet);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('«${bouquet.name}» добавлен в корзину')),
  );
}

class BouquetListScreen extends StatefulWidget {
  const BouquetListScreen({super.key, required this.query});

  final ListQuery query;

  @override
  State<BouquetListScreen> createState() => _BouquetListScreenState();
}

class _BouquetListScreenState extends State<BouquetListScreen> {
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _categories = await context
          .read<EntityListNotifier<Category>>()
          .findAll();
    } on ApiException catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final customer = auth.isRole(Role.customer);

    return EntityListScreen<Bouquet>(
      query: widget.query,
      title: 'Каталог букетов',
      searchLabel: 'Название или описание',
      addLabel: 'Добавить букет',
      emptyText: 'Букеты не найдены',
      canEdit: auth.isStaff,
      canDelete: auth.isStaff,
      idOf: (b) => b.id,
      nameOf: (b) => b.name,
      filters: (q, go) {
        final category = q.filter('category');
        return [
          DropdownButton<String>(
            value: _categories.any((c) => c.id == category) ? category : '',
            items: [
              const DropdownMenuItem(value: '', child: Text('Все категории')),
              for (final c in _categories)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => go(q.withFilter('category', v ?? '')),
          ),
          DebouncedField(
            label: 'Цена от',
            value: q.filter('priceFrom'),
            width: 110,
            numeric: true,
            onChanged: (v) =>
                go(q.withFilter('priceFrom', '${int.tryParse(v) ?? ''}')),
          ),
          DebouncedField(
            label: 'Цена до',
            value: q.filter('priceTo'),
            width: 110,
            numeric: true,
            onChanged: (v) =>
                go(q.withFilter('priceTo', '${int.tryParse(v) ?? ''}')),
          ),
          FilterChip(
            label: const Text('В наличии'),
            selected: q.filter('available') == 'true',
            onSelected: (v) => go(q.withFilter('available', v ? 'true' : '')),
          ),
        ];
      },
      extraActions: customer
          ? (b) => [
              IconButton(
                tooltip: 'В корзину',
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: b.available ? () => addToCart(context, b) : null,
              ),
            ]
          : null,
      columns: [
        TableColumnSpec(
          label: 'Название',
          sortField: 'name',
          build: (b) => ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(b.name, overflow: TextOverflow.ellipsis),
          ),
        ),
        TableColumnSpec(
          label: 'Категория',
          sortField: 'category.name',
          build: (b) => Text(b.categoryName),
        ),
        TableColumnSpec(
          label: 'Цена, ₽',
          sortField: 'price',
          numeric: true,
          build: (b) => Text('${b.price}'),
        ),
        TableColumnSpec(
          label: 'Наличие',
          sortField: 'available',
          build: (b) => Text(b.available ? 'в наличии' : 'нет'),
        ),
      ],
    );
  }
}

class BouquetDetailScreen extends StatelessWidget {
  const BouquetDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    return EntityDetailScreen<Bouquet>(
      id: id,
      path: '/bouquets',
      backLabel: 'К каталогу',
      canEdit: auth.isStaff,
      titleOf: (b) => b.name,
      fieldsOf: (b) => {
        'Категория': b.categoryName,
        'Цена': '${b.price} ₽',
        'Наличие': b.available ? 'в наличии' : 'нет в наличии',
        'Описание': b.description,
      },
      extra: (b) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Composition(bouquetId: b.id),
          if (auth.isRole(Role.customer)) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: b.available ? () => addToCart(context, b) : null,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('В корзину'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Composition extends StatelessWidget {
  const _Composition({required this.bouquetId});

  final String bouquetId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BouquetItem>>(
      future: context.read<EntityListNotifier<BouquetItem>>().findAll(
        filter: 'bouquet="$bouquetId"',
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Состав не загрузился');
        final items = snapshot.data;
        if (items == null) return const LinearProgressIndicator();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Состав', style: Theme.of(context).textTheme.titleMedium),
            if (items.isEmpty) const Text('Состав не указан'),
            for (final i in items) Text('${i.flowerName} - ${i.quantity} шт.'),
          ],
        );
      },
    );
  }
}

class BouquetFormScreen extends StatefulWidget {
  const BouquetFormScreen({super.key, this.id});

  final String? id;

  bool get isEditing => id != null;

  @override
  State<BouquetFormScreen> createState() => _BouquetFormScreenState();
}

class _BouquetFormScreenState extends State<BouquetFormScreen> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final Map<String, TextEditingController> _quantities = {};
  String? _categoryId;
  bool _available = true;
  List<String> _flowerIds = [];
  List<Category> _categories = [];
  List<Flower> _flowers = [];
  List<BouquetItem> _items = [];
  Bouquet? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bouquets = context.read<EntityListNotifier<Bouquet>>();
    final items = context.read<EntityListNotifier<BouquetItem>>();
    final categories = context.read<EntityListNotifier<Category>>();
    final flowers = context.read<EntityListNotifier<Flower>>();
    _categories = await categories.findAll();
    _flowers = await flowers.findAll();
    if (widget.isEditing) {
      _item = await bouquets.findById(widget.id!);
      _items = await items.findAll(filter: 'bouquet="${widget.id}"');
    }
    final item = _item;
    if (item != null) {
      _name.text = item.name;
      _price.text = '${item.price}';
      _description.text = item.description;
      _categoryId = item.categoryId;
      _available = item.available;
      for (final i in _items) {
        _quantity(i.flowerId).text = '${i.quantity}';
      }
      _flowerIds = _items.map((i) => i.flowerId).toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  TextEditingController _quantity(String flowerId) =>
      _quantities.putIfAbsent(flowerId, () => TextEditingController(text: '1'));

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    for (final c in _quantities.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<bool> _save() async {
    final bouquets = context.read<EntityRepository<Bouquet>>();
    final items = context.read<EntityRepository<BouquetItem>>();
    final notifier = context.read<EntityListNotifier<Bouquet>>();
    final data = Bouquet(
      id: _item?.id ?? '',
      name: _name.text.trim(),
      categoryId: _categoryId!,
      price: int.parse(_price.text.trim()),
      description: _description.text.trim(),
      available: _available,
    );
    final saved = widget.isEditing
        ? await bouquets.update(data)
        : await bouquets.create(data);

    for (final old in _items) {
      if (!_flowerIds.contains(old.flowerId)) await items.delete(old.id);
    }
    for (final flowerId in _flowerIds) {
      final quantity = int.parse(_quantity(flowerId).text.trim());
      final old = _items.where((i) => i.flowerId == flowerId).firstOrNull;
      final item = BouquetItem(
        id: old?.id ?? '',
        bouquetId: saved.id,
        flowerId: flowerId,
        quantity: quantity,
      );
      if (old == null) {
        await items.create(item);
      } else if (old.quantity != quantity) {
        await items.update(item);
      }
    }
    await notifier.load();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (widget.isEditing && _item == null) {
      return const EmptyView(text: 'Букет не найден');
    }
    final names = {for (final f in _flowers) f.id: f.name};

    return EntityForm(
      title: widget.isEditing ? 'Изменение букета' : 'Новый букет',
      isEditing: widget.isEditing,
      donePath: '/bouquets',
      onSave: _save,
      fields: [
        TextInput(
          controller: _name,
          label: 'Название',
          validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
        ),
        DropdownButtonFormField<String>(
          initialValue: _categoryId,
          decoration: fieldDecoration('Категория'),
          items: [
            for (final c in _categories)
              DropdownMenuItem(value: c.id, child: Text(c.name)),
          ],
          onChanged: (v) => setState(() => _categoryId = v),
          validator: (v) => v == null ? 'Выберите категорию' : null,
        ),
        TextInput(
          controller: _price,
          label: 'Цена, ₽',
          numeric: true,
          validator: V.combine([V.required(), V.integer(min: 1, max: 100000)]),
        ),
        TextInput(
          controller: _description,
          label: 'Описание',
          maxLines: 3,
          validator: V.length(max: 500),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('В наличии'),
          value: _available,
          onChanged: (v) => setState(() => _available = v),
        ),
        MultiSelectField(
          label: 'Цветы в составе',
          options: names,
          initialValue: _flowerIds,
          onChanged: (v) => setState(() => _flowerIds = v),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Выберите хотя бы один цветок' : null,
        ),
        for (final id in _flowerIds)
          TextInput(
            key: ValueKey(id),
            controller: _quantity(id),
            label: '${names[id] ?? ''}, шт.',
            numeric: true,
            validator: V.combine([V.required(), V.integer(min: 1, max: 101)]),
          ),
      ],
    );
  }
}
