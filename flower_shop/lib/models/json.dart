String str(dynamic value) => value is String ? value : '';

int integer(dynamic value) => value is num ? value.round() : 0;

DateTime? parseDate(dynamic value) => value is String && value.isNotEmpty
    ? DateTime.tryParse(value)?.toLocal()
    : null;

String dateToJson(DateTime value) {
  final d = DateTime(value.year, value.month, value.day);
  return '${formatDate(d)} 12:00:00.000Z';
}

String formatDate(DateTime? value) {
  if (value == null) return '';
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '${value.year}-$m-$d';
}

Map<String, dynamic>? expanded(Map<String, dynamic> json, String key) {
  final value = (json['expand'] as Map?)?[key];
  if (value is Map<String, dynamic>) return value;
  if (value is List &&
      value.isNotEmpty &&
      value.first is Map<String, dynamic>) {
    return value.first as Map<String, dynamic>;
  }
  return null;
}

List<Map<String, dynamic>> expandedList(Map<String, dynamic> json, String key) {
  final value = (json['expand'] as Map?)?[key];
  if (value is List) return value.whereType<Map<String, dynamic>>().toList();
  if (value is Map<String, dynamic>) return [value];
  return const [];
}
