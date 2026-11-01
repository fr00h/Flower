import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.size,
    required this.onPage,
    required this.onSize,
  });

  final int page;
  final int totalPages;
  final int total;
  final int size;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text('Всего записей: $total'),
          const SizedBox(width: 16),
          IconButton(
            tooltip: 'Первая',
            icon: const Icon(Icons.first_page),
            onPressed: page > 1 ? () => onPage(1) : null,
          ),
          IconButton(
            tooltip: 'Предыдущая',
            icon: const Icon(Icons.chevron_left),
            onPressed: page > 1 ? () => onPage(page - 1) : null,
          ),
          Text('Страница $page из $totalPages'),
          IconButton(
            tooltip: 'Следующая',
            icon: const Icon(Icons.chevron_right),
            onPressed: page < totalPages ? () => onPage(page + 1) : null,
          ),
          IconButton(
            tooltip: 'Последняя',
            icon: const Icon(Icons.last_page),
            onPressed: page < totalPages ? () => onPage(totalPages) : null,
          ),
          const SizedBox(width: 16),
          const Text('На странице:'),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: [10, 25, 50].contains(size) ? size : 10,
            items: [
              for (final s in [10, 25, 50])
                DropdownMenuItem(value: s, child: Text('$s')),
            ],
            onChanged: (value) => onSize(value ?? size),
          ),
        ],
      ),
    );
  }
}
