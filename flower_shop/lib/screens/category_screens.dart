import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/category.dart';
import '../models/list_query.dart';
import '../state/auth_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_table.dart';
import '../widgets/fields.dart';
import '../widgets/state_views.dart';
import 'entity_detail_screen.dart';
import 'entity_list_screen.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key, required this.query});

  final ListQuery query;

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<AuthNotifier>().isStaff;

    return EntityListScreen<Category>(
      query: query,
      title: 'Категории',
      searchLabel: 'Название',
      addLabel: 'Добавить категорию',
      emptyText: 'Категории не найдены',
      canEdit: staff,
      canDelete: staff,
      idOf: (c) => c.id,
      nameOf: (c) => c.name,
      columns: [
        TableColumnSpec(
          label: 'Название',
          sortField: 'name',
          build: (c) => Text(c.name),
        ),
        TableColumnSpec(
          label: 'Описание',
          build: (c) => ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(c.description, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}

class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return EntityDetailScreen<Category>(
      id: id,
      path: '/categories',
      backLabel: 'К категориям',
      canEdit: context.watch<AuthNotifier>().isStaff,
      titleOf: (c) => c.name,
      fieldsOf: (c) => {'Описание': c.description},
    );
  }
}

class CategoryFormScreen extends StatefulWidget {
  const CategoryFormScreen({super.key, this.id});

  final String? id;

  bool get isEditing => id != null;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  Category? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.isEditing) {
      _item = await context.read<EntityListNotifier<Category>>().findById(
        widget.id!,
      );
    }
    final item = _item;
    if (item != null) {
      _name.text = item.name;
      _description.text = item.description;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    final item = Category(
      id: _item?.id ?? '',
      name: _name.text.trim(),
      description: _description.text.trim(),
    );
    await context.read<EntityListNotifier<Category>>().save(
      item,
      isNew: !widget.isEditing,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (widget.isEditing && _item == null) {
      return const EmptyView(text: 'Категория не найдена');
    }

    return EntityForm(
      title: widget.isEditing ? 'Изменение категории' : 'Новая категория',
      isEditing: widget.isEditing,
      donePath: '/categories',
      onSave: _save,
      fields: [
        TextInput(
          controller: _name,
          label: 'Название',
          validator: V.combine([V.required(), V.length(min: 2, max: 50)]),
        ),
        TextInput(
          controller: _description,
          label: 'Описание',
          maxLines: 3,
          validator: V.length(max: 300),
        ),
      ],
    );
  }
}
