import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceIdAsync = ref.watch(deviceIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Appearance'),
            subtitle: Text('Follows system theme (Phase 0)'),
          ),
          const Divider(),
          const ListTile(
            title: Text('About Ayutam'),
            subtitle: Text(
              'Local-first skill tracker · schema v${AppConstants.schemaVersion}',
            ),
          ),
          deviceIdAsync.when(
            data: (id) =>
                ListTile(title: const Text('Device ID'), subtitle: Text(id)),
            loading: () => const ListTile(
              title: Text('Device ID'),
              subtitle: Text('Loading…'),
            ),
            error: (e, _) => ListTile(
              title: const Text('Device ID'),
              subtitle: Text('Error: $e'),
            ),
          ),
          const ListTile(
            title: Text('Privacy'),
            subtitle: Text(
              'No accounts, analytics, or automatic cloud sync. '
              'Data stays on this device until you export a backup.',
            ),
          ),
        ],
      ),
    );
  }
}
