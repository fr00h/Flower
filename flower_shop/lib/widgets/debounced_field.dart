import 'dart:async';

import 'package:flutter/material.dart';

class DebouncedField extends StatefulWidget {
  const DebouncedField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.width = 240,
    this.numeric = false,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final double width;
  final bool numeric;

  @override
  State<DebouncedField> createState() => _DebouncedFieldState();
}

class _DebouncedFieldState extends State<DebouncedField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  Timer? _timer;

  @override
  void didUpdateWidget(covariant DebouncedField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(
      const Duration(milliseconds: 300),
      () => widget.onChanged(value.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        keyboardType: widget.numeric ? TextInputType.number : null,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          isDense: true,
          prefixIcon: widget.numeric ? null : const Icon(Icons.search),
        ),
        onChanged: _onChanged,
      ),
    );
  }
}
