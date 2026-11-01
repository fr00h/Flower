import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/entity_list_notifier.dart';
import '../widgets/state_views.dart';

class EntityDetailScreen<T> extends StatefulWidget {
  const EntityDetailScreen({
    super.key,
    required this.id,
    required this.path,
    required this.backLabel,
    required this.titleOf,
    required this.fieldsOf,
    this.canEdit = false,
    this.extra,
  });

  final String id;
  final String path;
  final String backLabel;
  final String Function(T item) titleOf;
  final Map<String, String> Function(T item) fieldsOf;
  final bool canEdit;
  final Widget Function(T item)? extra;

  @override
  State<EntityDetailScreen<T>> createState() => _EntityDetailScreenState<T>();
}

class _EntityDetailScreenState<T> extends State<EntityDetailScreen<T>> {
  late Future<T?> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<EntityListNotifier<T>>().findById(widget.id);
  }

  void _retry() {
    setState(() {
      _future = context.read<EntityListNotifier<T>>().findById(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          return ErrorView(
            message: 'Не удалось загрузить запись: ${snapshot.error}',
            onRetry: _retry,
          );
        }
        final item = snapshot.data;
        if (item == null) {
          return const EmptyView(text: 'Запись не найдена');
        }

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
                          widget.titleOf(item),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        for (final e in widget.fieldsOf(item).entries)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(e.key),
                            subtitle: Text(e.value.isEmpty ? '-' : e.value),
                          ),
                        if (widget.extra != null) widget.extra!(item),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: () => context.go(widget.path),
                              icon: const Icon(Icons.arrow_back),
                              label: Text(widget.backLabel),
                            ),
                            if (widget.canEdit)
                              FilledButton.icon(
                                onPressed: () => context.go(
                                  '${widget.path}/${widget.id}/edit',
                                ),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Изменить'),
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
