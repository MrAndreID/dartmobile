import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

/// The landing screen. Acts as a directory of the available features so the
/// skeleton is navigable out of the box.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DartMobile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FeatureTile(
            icon: Icons.waving_hand_rounded,
            title: 'Hello World',
            subtitle: 'A simple presentation-only feature.',
            onTap: () => context.goNamed(AppRoutes.helloWorld),
          ),
          const SizedBox(height: 12),
          _FeatureTile(
            icon: Icons.people_alt_rounded,
            title: 'Users',
            subtitle: 'Full CRUD backed by the goapi service.',
            onTap: () => context.goNamed(AppRoutes.userList),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
