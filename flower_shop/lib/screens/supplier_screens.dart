import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/list_query.dart';
import '../models/supplier.dart';
import '../state/entity_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/entity_table.dart';
import '../widgets/fields.dart';
import '../widgets/state_views.dart';
import 'entity_detail_screen.dart';
import 'entity_list_screen.dart';

class SupplierListScreen extends StatelessWidget {
  const SupplierListScreen({super.key, required this.query});

  final ListQuery query;

  @override
  Widget build(BuildContext context) {
    return EntityListScreen<Supplier>(
      query: query,
      title: 'Поставщики',
      searchLabel: 'Название или город',
      addLabel: 'Добавить поставщика',
      emptyText: 'Поставщики не найдены',
      canEdit: true,
      canDelete: true,
      idOf: (s) => s.id,
      nameOf: (s) => s.name,
      columns: [
        TableColumnSpec(
          label: 'Название',
          sortField: 'name',
          build: (s) => Text(s.name),
        ),
        TableColumnSpec(
          label: 'Город',
          sortField: 'city',
          build: (s) => Text(s.city),
        ),
        TableColumnSpec(label: 'Телефон', build: (s) => Text(s.phone)),
        TableColumnSpec(label: 'Почта', build: (s) => Text(s.email)),
      ],
    );
  }
}

class SupplierDetailScreen extends StatelessWidget {
  const SupplierDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return EntityDetailScreen<Supplier>(
      id: id,
      path: '/admin/suppliers',
      backLabel: 'К поставщикам',
      canEdit: true,
      titleOf: (s) => s.name,
      fieldsOf: (s) => {'Город': s.city, 'Телефон': s.phone, 'Почта': s.email},
    );
  }
}

class SupplierFormScreen extends StatefulWidget {
  const SupplierFormScreen({super.key, this.id});

  final String? id;

  bool get isEditing => id != null;

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  Supplier? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.isEditing) {
      _item = await context.read<EntityListNotifier<Supplier>>().findById(
        widget.id!,
      );
    }
    final item = _item;
    if (item != null) {
      _name.text = item.name;
      _phone.text = item.phone;
      _email.text = item.email;
      _city.text = item.city;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    final item = Supplier(
      id: _item?.id ?? '',
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      city: _city.text.trim(),
    );
    await context.read<EntityListNotifier<Supplier>>().save(
      item,
      isNew: !widget.isEditing,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (widget.isEditing && _item == null) {
      return const EmptyView(text: 'Поставщик не найден');
    }

    return EntityForm(
      title: widget.isEditing ? 'Изменение поставщика' : 'Новый поставщик',
      isEditing: widget.isEditing,
      donePath: '/admin/suppliers',
      onSave: _save,
      fields: [
        TextInput(
          controller: _name,
          label: 'Название',
          validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
        ),
        TextInput(
          controller: _phone,
          label: 'Телефон',
          validator: V.combine([V.required(), V.phone()]),
        ),
        TextInput(
          controller: _email,
          label: 'Почта',
          validator: V.combine([V.required(), V.email()]),
        ),
        TextInput(
          controller: _city,
          label: 'Город',
          validator: V.combine([V.required(), V.length(min: 2, max: 50)]),
        ),
      ],
    );
  }
}
