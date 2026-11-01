import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../state/auth_notifier.dart';
import '../widgets/fields.dart';

class _AuthLayout extends StatelessWidget {
  const _AuthLayout({
    required this.formKey,
    required this.title,
    required this.fields,
    required this.error,
    required this.loading,
    required this.submitLabel,
    required this.onSubmit,
    required this.linkLabel,
    required this.linkPath,
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final List<Widget> fields;
  final String? error;
  final bool loading;
  final String submitLabel;
  final VoidCallback onSubmit;
  final String linkLabel;
  final String linkPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  for (final field in fields) ...[
                    field,
                    const SizedBox(height: 16),
                  ],
                  if (error != null) ...[
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton(
                    onPressed: loading ? null : onSubmit,
                    child: Text(submitLabel),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go(linkPath),
                    child: Text(linkLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthNotifier>().login(
        _email.text.trim(),
        _password.text,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _AuthLayout(
      formKey: _formKey,
      title: 'Вход в цветочный магазин',
      error: _error,
      loading: _loading,
      submitLabel: 'Войти',
      onSubmit: _submit,
      linkLabel: 'Регистрация',
      linkPath: '/register',
      fields: [
        TextInput(
          controller: _email,
          label: 'Почта',
          validator: V.combine([V.required(), V.email()]),
        ),
        TextFormField(
          controller: _password,
          obscureText: true,
          decoration: fieldDecoration('Пароль'),
          validator: V.required(),
          onFieldSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  String? _emailError;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _emailError = null;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthNotifier>().register(
        _email.text.trim(),
        _password.text,
        _name.text.trim(),
      );
    } on ValidationException catch (e) {
      _emailError = e.errors['email'];
      if (mounted) {
        setState(() => _error = _emailError == null ? e.message : null);
      }
      _formKey.currentState?.validate();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _AuthLayout(
      formKey: _formKey,
      title: 'Регистрация покупателя',
      error: _error,
      loading: _loading,
      submitLabel: 'Зарегистрироваться',
      onSubmit: _submit,
      linkLabel: 'Уже есть учётная запись',
      linkPath: '/login',
      fields: [
        TextInput(
          controller: _name,
          label: 'Имя',
          validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
        ),
        TextFormField(
          controller: _email,
          decoration: fieldDecoration('Почта'),
          onChanged: (_) => _emailError = null,
          validator: (v) =>
              V.combine([V.required(), V.email()])(v) ?? _emailError,
        ),
        TextFormField(
          controller: _password,
          obscureText: true,
          decoration: fieldDecoration('Пароль'),
          validator: V.combine([V.required(), V.password()]),
        ),
        TextFormField(
          controller: _repeat,
          obscureText: true,
          decoration: fieldDecoration('Повтор пароля'),
          validator: (v) => v != _password.text ? 'Пароли не совпадают' : null,
        ),
      ],
    );
  }
}
