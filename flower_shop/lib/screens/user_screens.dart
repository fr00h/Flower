import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../models/app_user.dart';
import '../models/customer_card.dart';
import '../models/list_query.dart';
import '../repositories/entity_repository.dart';
import '../state/entity_list_notifier.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/entity_table.dart';
import '../widgets/fields.dart';
import '../widgets/state_views.dart';
import 'entity_list_screen.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key, required this.query});

  final ListQuery query;

  @override
  Widget build(BuildContext context) {
    return EntityListScreen<AppUser>(
      query: query,
      title: 'Пользователи',
      searchLabel: 'Имя или почта',
      emptyText: 'Пользователи не найдены',
      canDelete: true,
      idOf: (u) => u.id,
      nameOf: (u) => u.name,
      filters: (q, go) => [
        DropdownButton<String>(
          value: q.filter('role'),
          items: [
            const DropdownMenuItem(value: '', child: Text('Все роли')),
            for (final r in Role.values)
              DropdownMenuItem(value: r.name, child: Text(r.title)),
          ],
          onChanged: (v) => go(q.withFilter('role', v ?? '')),
        ),
      ],
      columns: [
        TableColumnSpec(
          label: 'Имя',
          sortField: 'name',
          build: (u) => Text(u.name),
        ),
        TableColumnSpec(
          label: 'Почта',
          sortField: 'email',
          build: (u) => Text(u.email),
        ),
        TableColumnSpec(
          label: 'Роль',
          sortField: 'role',
          build: (u) => Text(u.role.title),
        ),
      ],
    );
  }
}

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  AppUser? _user;
  CustomerCard? _card;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _user = await context.read<EntityListNotifier<AppUser>>().findById(
        widget.id,
      );
      if (!mounted) return;
      final cards = await context
          .read<EntityRepository<CustomerCard>>()
          .findAll(filter: 'user="${widget.id}"');
      _card = cards.firstOrNull;
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _run(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      await _load();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _setRole(Role role) async {
    final users = context.read<EntityListNotifier<AppUser>>();
    await _run(() => users.save(_user!.copyWith(role: role), isNew: false));
  }

  Future<void> _editCard() async {
    final cards = context.read<EntityRepository<CustomerCard>>();
    final result = await showDialog<CustomerCard>(
      context: context,
      builder: (context) => _CardDialog(userId: widget.id, card: _card),
    );
    if (result == null) return;
    await _run(
      () => result.id.isEmpty ? cards.create(result) : cards.update(result),
    );
  }

  Future<void> _deleteCard() async {
    final cards = context.read<EntityRepository<CustomerCard>>();
    if (!await confirm(context, 'Удалить карту ${_card!.number}?')) return;
    await _run(() => cards.delete(_card!.id));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    final user = _user;
    if (user == null) return const EmptyView(text: 'Пользователь не найден');
    final card = _card;

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
                      user.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(user.email),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Role>(
                      initialValue: user.role,
                      decoration: fieldDecoration('Роль'),
                      items: [
                        for (final r in Role.values)
                          DropdownMenuItem(value: r, child: Text(r.title)),
                      ],
                      onChanged: (r) {
                        if (r != null && r != user.role) _setRole(r);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Карта покупателя',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      card == null
                          ? 'Карта не выдана'
                          : '${card.number}, скидка ${card.discount}%',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _editCard,
                          child: Text(
                            card == null ? 'Выдать карту' : 'Изменить карту',
                          ),
                        ),
                        if (card != null)
                          OutlinedButton(
                            onPressed: _deleteCard,
                            child: const Text('Удалить карту'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => context.go('/admin/users'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('К пользователям'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardDialog extends StatefulWidget {
  const _CardDialog({required this.userId, this.card});

  final String userId;
  final CustomerCard? card;

  @override
  State<_CardDialog> createState() => _CardDialogState();
}

class _CardDialogState extends State<_CardDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _number = TextEditingController(
    text: widget.card?.number ?? 'FC-',
  );
  late final _discount = TextEditingController(
    text: '${widget.card?.discount ?? 0}',
  );

  @override
  void dispose() {
    _number.dispose();
    _discount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Карта покупателя'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextInput(
                controller: _number,
                label: 'Номер',
                validator: V.combine([
                  V.required(),
                  V.pattern(RegExp(r'^FC-\d{6}$'), 'Формат: FC-000123'),
                ]),
              ),
              const SizedBox(height: 16),
              TextInput(
                controller: _discount,
                label: 'Скидка, %',
                numeric: true,
                validator: V.combine([
                  V.required(),
                  V.integer(min: 0, max: 30),
                ]),
              ),
            ],
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
              CustomerCard(
                id: widget.card?.id ?? '',
                userId: widget.userId,
                number: _number.text.trim(),
                discount: int.parse(_discount.text.trim()),
              ),
            );
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
