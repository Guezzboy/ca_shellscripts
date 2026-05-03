import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../core/services/collection_export_service.dart';
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
            leading: const Icon(Icons.share_outlined),
            title: const Text('Exporter les collections'),
            subtitle: const Text('Partager en JSON'),
            onTap: () => _exportAll(context),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Importer des collections'),
            subtitle: const Text('Depuis une URL ou un fichier'),
            onTap: () => context.push('/download'),
          ),
          const _RemoteUrlTile(),
          const _ProxyUrlTile(),
          const Divider(),
          const _SectionHeader('Sync'),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Syncthing'),
            subtitle: const Text('Sync locale via Wi-Fi (configuré sur CasaOS)'),
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

  Future<void> _exportAll(BuildContext context) async {
    try {
      final service = CollectionExportService();
      final json = await service.exportAllCollections();
      await Share.share(
        json,
        subject: 'Collections export',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur export : $e')),
        );
      }
    }
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

class _RemoteUrlTile extends StatefulWidget {
  const _RemoteUrlTile();

  @override
  State<_RemoteUrlTile> createState() => _RemoteUrlTileState();
}

class _RemoteUrlTileState extends State<_RemoteUrlTile> {
  String _url = '';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() =>
            _url = p.getString('remote_collection_base_url') ?? '');
      }
    });
  }

  Future<void> _edit() async {
    final ctrl = TextEditingController(text: _url);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('URL de données distantes'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://example.com/collections',
            helperText:
                'Le slug est ajouté : …/{nom-collection}.json',
            helperMaxLines: 2,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('remote_collection_base_url', result);
      if (mounted) setState(() => _url = result);
    }
  }

  @override
  Widget build(BuildContext context) => ListTile(
        leading: const Icon(Icons.cloud_outlined),
        title: const Text('URL de données distantes'),
        subtitle: Text(
          _url.isEmpty ? 'Non configurée' : _url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 13,
              color: _url.isEmpty
                  ? AppTheme.textSecondary
                  : AppTheme.textPrimary),
        ),
        onTap: _edit,
      );
}

class _ProxyUrlTile extends StatefulWidget {
  const _ProxyUrlTile();

  @override
  State<_ProxyUrlTile> createState() => _ProxyUrlTileState();
}

class _ProxyUrlTileState extends State<_ProxyUrlTile> {
  String _url = '';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() => _url = p.getString('proxy_server_url') ?? '');
      }
    });
  }

  Future<void> _edit() async {
    final ctrl = TextEditingController(text: _url);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('URL du serveur proxy'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'http://localhost:3000',
            helperText:
                'Serveur Node.js local (server/index.js). '
                'Lance-le avec : node server/index.js',
            helperMaxLines: 3,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('proxy_server_url', result);
      if (mounted) setState(() => _url = result);
    }
  }

  @override
  Widget build(BuildContext context) => ListTile(
        leading: const Icon(Icons.travel_explore_outlined),
        title: const Text('Serveur proxy (Coleka)'),
        subtitle: Text(
          _url.isEmpty ? 'Non configuré — recherche Coleka désactivée' : _url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 13,
              color: _url.isEmpty
                  ? AppTheme.textSecondary
                  : AppTheme.textPrimary),
        ),
        onTap: _edit,
      );
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
          color: AppTheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
