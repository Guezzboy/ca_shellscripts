import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../shared/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          const _SectionHeader('Application'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            trailing: const Text('1.0.0'),
          ),
          const Divider(),
          const _SectionHeader('Données'),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Exporter les collections'),
            subtitle: const Text('Export JSON (bientôt disponible)'),
            onTap: () => _showComingSoon(context),
          ),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Importer des collections'),
            subtitle: const Text('Import JSON (bientôt disponible)'),
            onTap: () => _showComingSoon(context),
          ),
          const Divider(),
          const _SectionHeader('Sync'),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Syncthing'),
            subtitle: const Text('Sync locale via Wi-Fi (Phase 3)'),
            onTap: () => _showComingSoon(context),
          ),
          const Divider(),
          const _SectionHeader('Danger zone'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Effacer toutes les données',
                style: TextStyle(color: Colors.red)),
            onTap: () => _confirmClearAll(context, ref),
          ),
          const Divider(),
          const _SectionHeader('À propos'),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Code source'),
            subtitle: const Text('github.com/guezzboy/ca_shellscripts'),
          ),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Stack technique'),
            subtitle: const Text('Flutter · SQLite · Riverpod · go_router'),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Collection App v1.0.0\nFait avec ❤️ par Guezz',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.brown.shade400,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité prévue pour la Phase 3 !'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Effacer toutes les données ?'),
        content: const Text(
          'Cette action est irréversible. '
          'Toutes vos collections et items seront supprimés.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Tout effacer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final collections = await ref.read(collectionsProvider.future);
      final notifier = ref.read(collectionsProvider.notifier);
      for (final c in collections) {
        await notifier.delete(c.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toutes les données ont été effacées.')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryBrown,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
