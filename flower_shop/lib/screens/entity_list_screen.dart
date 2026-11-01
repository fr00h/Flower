import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/list_query.dart';
import '../state/entity_list_notifier.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/debounced_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/state_views.dart';

class EntityListScreen<T> extends StatefulWidget {
  const EntityListScreen({
    super.key,
    required this.query,
    required this.title,
    required this.searchLabel,
    required this.emptyText,
    required this.columns,
    required this.idOf,
    required this.nameOf,
    this.addLabel,
    this.canEdit = false,
    this.canDelete = false,
    this.filters,
    this.extraActions,
  });

  final ListQuery query;
  final String title;
  final String searchLabel;
  final String emptyText;
  final List<TableColumnSpec<T>> columns;
  final String Function(T item) idOf;
  final String Function(T item) nameOf;
  final String? addLabel;
  final bool canEdit;
  final bool canDelete;
  final List<Widget> Function(ListQuery query, void Function(ListQuery) go)?
  filters;
  final List<Widget> Function(T item)? extraActions;

  @override
  State<EntityListScreen<T>> createState() => _EntityListScreenState<T>();
}

class _EntityListScreenState<T> extends State<EntityListScreen<T>> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant EntityListScreen<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = context.read<EntityListNotifier<T>>();
      if (notifier.status == LoadStatus.idle ||
          notifier.query?.location != widget.query.location) {
        notifier.applyQuery(widget.query);
      }
    });
  }

  void _go(ListQuery query) => context.go(query.location);

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<EntityListNotifier<T>>();
    final q = widget.query;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DebouncedField(
                label: widget.searchLabel,
                value: q.search,
                width: 260,
                onChanged: (v) => _go(q.copyWith(search: v)),
              ),
              ...?widget.filters?.call(q, _go),
              TextButton(
                onPressed: () => context.go(q.path),
                child: const Text('Сбросить'),
              ),
              if (widget.canEdit && widget.addLabel != null)
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(widget.addLabel!),
                  onPressed: () => context.go('${q.path}/new'),
                ),
            ],
          ),
        ),
        Expanded(child: _buildContent(context, notifier)),
        if (notifier.status == LoadStatus.success && notifier.result.total > 0)
          PaginationBar(
            page: notifier.result.page,
            totalPages: notifier.result.totalPages,
            total: notifier.result.total,
            size: q.size,
            onPage: (p) => _go(q.copyWith(page: p)),
            onSize: (s) => _go(q.copyWith(size: s)),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, EntityListNotifier<T> notifier) {
    final q = widget.query;

    return switch (notifier.status) {
      LoadStatus.idle || LoadStatus.loading => const LoadingView(),
      LoadStatus.error => ErrorView(
        message: notifier.error ?? 'Ошибка',
        onRetry: notifier.load,
      ),
      LoadStatus.success when notifier.result.items.isEmpty => EmptyView(
        text: widget.emptyText,
      ),
      LoadStatus.success => EntityTable<T>(
        items: notifier.result.items,
        sortField: q.sortField,
        sortAscending: q.sortAscending,
        onSort: (field) => _go(
          q.copyWith(
            sortField: field,
            sortAscending: field == q.sortField ? !q.sortAscending : true,
          ),
        ),
        columns: widget.columns,
        actions: (item) => _actions(context, notifier, item),
      ),
    };
  }

  List<Widget> _actions(
    BuildContext context,
    EntityListNotifier<T> notifier,
    T item,
  ) {
    final id = widget.idOf(item);
    final path = widget.query.path;

    return [
      IconButton(
        tooltip: 'Открыть',
        icon: const Icon(Icons.info_outline),
        onPressed: () => context.go('$path/$id'),
      ),
      ...?widget.extraActions?.call(item),
      if (widget.canEdit)
        IconButton(
          tooltip: 'Изменить',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.go('$path/$id/edit'),
        ),
      if (widget.canDelete)
        IconButton(
          tooltip: 'Удалить',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            if (!await confirm(context, 'Удалить «${widget.nameOf(item)}»?')) {
              return;
            }
            final error = await notifier.delete(id);
            if (error != null) {
              messenger.showSnackBar(SnackBar(content: Text(error)));
            }
          },
        ),
    ];
  }
}
