import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) return _buildCards(context);
        return _buildTable(context, constraints.maxWidth);
      },
    );
  }

  Widget _buildTable(BuildContext context, double width) {
    final sortIndex = columns.indexWhere(
      (c) => c.sortField != null && c.sortField == sortField,
    );

    final table = DataTable(
      sortColumnIndex: sortIndex == -1 ? null : sortIndex,
      sortAscending: sortAscending,
      columns: [
        for (final column in columns)
          DataColumn(
            label: Text(column.label),
            numeric: column.numeric,
            onSort: column.sortField == null || onSort == null
                ? null
                : (_, _) => onSort!(column.sortField!),
          ),
        if (actions != null) const DataColumn(label: Text('Действия')),
      ],
      rows: [
        for (final item in items)
          DataRow(
            cells: [
              for (final column in columns) DataCell(column.build(item)),
              if (actions != null)
                DataCell(
                  Row(mainAxisSize: MainAxisSize.min, children: actions!(item)),
                ),
            ],
          ),
      ],
    );

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: width),
          child: table,
        ),
      ),
    );
  }

  Widget _buildCards(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          child: ListTile(
            title: columns.first.build(item),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  children: [
                    for (final column in columns.skip(1)) column.build(item),
                  ],
                ),
                if (actions != null) Wrap(children: actions!(item)),
              ],
            ),
          ),
        );
      },
    );
  }
}
