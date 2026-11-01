import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';
import '../widgets/destinations.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user!;
    final items = destinationsFor(user.role).skip(1);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Здравствуйте, ${user.name}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text('Роль: ${user.role.title}'),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final d in items)
              SizedBox(
                width: 200,
                height: 100,
                child: Card(
                  child: InkWell(
                    onTap: () => context.go(d.path),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(d.icon, size: 32),
                        const SizedBox(height: 8),
                        Text(d.label),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
