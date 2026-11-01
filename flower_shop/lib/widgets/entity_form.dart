import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exceptions.dart';
import 'confirm_dialog.dart';

class EntityForm extends StatefulWidget {
  const EntityForm({
    super.key,
    required this.title,
    required this.isEditing,
    required this.fields,
    required this.onSave,
    required this.donePath,
  });

  final String title;
  final bool isEditing;
  final List<Widget> fields;
  final Future<bool> Function() onSave;
  final String donePath;

  @override
  State<EntityForm> createState() => _EntityFormState();
}

class _EntityFormState extends State<EntityForm> {
  final _formKey = GlobalKey<FormState>();
  bool _dirty = false;
  bool _saving = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    var ok = false;
    try {
      ok = await widget.onSave();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      _formKey.currentState!.validate();
      return;
    }
    _dirty = false;
    context.go(widget.donePath);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final leave = await confirm(
          context,
          'Есть несохранённые изменения. Уйти без сохранения?',
          okLabel: 'Уйти',
        );
        if (leave) navigator.pop();
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: () {
                  if (!_dirty) setState(() => _dirty = true);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    for (final field in widget.fields) ...[
                      field,
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Text('Назад'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _saving ? null : _submit,
                          child: Text(
                            widget.isEditing ? 'Сохранить' : 'Создать',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
