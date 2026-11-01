import 'package:flutter/material.dart';

import '../core/validators.dart';
import '../models/json.dart';

InputDecoration fieldDecoration(String label) =>
    InputDecoration(labelText: label, border: const OutlineInputBorder());

class TextInput extends StatelessWidget {
  const TextInput({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.numeric = false,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final Validator? validator;
  final bool numeric;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : null,
      maxLines: maxLines,
      decoration: fieldDecoration(label),
      validator: validator,
    );
  }
}

class DateInput extends StatelessWidget {
  const DateInput({
    super.key,
    required this.controller,
    required this.label,
    required this.firstDate,
    required this.lastDate,
  });

  final TextEditingController controller;
  final String label;
  final DateTime firstDate;
  final DateTime lastDate;

  Future<void> _pick(BuildContext context) async {
    final current = DateTime.tryParse(controller.text);
    final picked = await showDatePicker(
      context: context,
      initialDate:
          current != null &&
              !current.isBefore(firstDate) &&
              !current.isAfter(lastDate)
          ? current
          : firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) controller.text = formatDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: fieldDecoration(label).copyWith(
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: () => _pick(context),
        ),
      ),
      validator: (value) {
        final error = V.combine([V.required(), V.date()])(value);
        if (error != null) return error;
        final d = DateTime.parse(value!.trim());
        if (d.isBefore(
              DateTime(firstDate.year, firstDate.month, firstDate.day),
            ) ||
            d.isAfter(lastDate)) {
          return 'Дата с ${formatDate(firstDate)} по ${formatDate(lastDate)}';
        }
        return null;
      },
    );
  }
}
