import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/collection_export_service.dart';
import '../../../core/services/badge_checker.dart';
import '../../../shared/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.themeTokens;
    final themeKey = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: const Text('Réglages'),
        backgroundColor: tokens.bg,
      ),
      body: ListView(
        children: [
          _SectionHeader('Apparence', tokens),
          // Theme picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _ThemeOption(
                  label: 'Solaire',
                  color: const Color(0xFFF4A72B),
                  active: themeKey == 'solaire',
                  onTap: () =>
                      ref.read(themeProvider.notifier).setTheme('solaire'),
                ),
                const SizedBox(width: 8),
                _ThemeOption(
                  label: 'Naturel',
                  color: const Color(0xFF94A87A),
                  active: themeKey == 'naturel',
                  onTap: () =>
                      ref.read(themeProvider.notifier).setTheme('naturel'),
                ),
                const SizedBox(width: 8),
                _ThemeOption(
                  label: 'Nuit',
                  color: const Color(0xFFF4B73A),
                  active: themeKey == 'nuit',
                  dark: true,
                  onTap: () =>
                      ref.read(themeProvider.notifier).setTheme('nuit'),
                ),
              ],
            ),
          ),
          const Divider(),
          _SectionHeader('Application', tokens),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            trailing: const Text('1.0.0'),
          ),
          const Divider(),
          _SectionHeader('Données', tokens),
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
            onTap: () {},
          ),
          const _RemoteUrlTile(),
          const _ProxyUrlTile(),
          const Divider(),
          _SectionHeader('Sync', tokens),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Syncthing'),
            subtitle:
                const Text('Sync locale via Wi-Fi (configuré sur CasaOS)'),
            onTap: () => _showComingSoon(context),
          ),
          const Divider(),
          _SectionHeader('Danger zone', tokens),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Effacer toutes les données',
                style: TextStyle(color: Colors.red)),
            onTap: () => _confirmClearAll(context, ref),
          ),
          const Divider(),
          _SectionHeader('À propos', tokens),
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
              'Colectio v1.0.0\nFait avec ❤️ par Guezz',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.ink.withOpacity(0.5),
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
      BadgeChecker.afterExport(context);
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
          const SnackBar(
              content: Text('Toutes les données ont été effacées.')),
        );
      }
    }
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final bool dark;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.color,
    required this.active,
    this.dark = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1C1A17) : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white70 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        setState(() => _url = p.getString('remote_collection_base_url') ?? '');
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
            helperText: 'Le slug est ajouté : …/{nom-collection}.json',
            helperMaxLines: 2,
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
                'Serveur Node.js local (server/index.js). Lance-le avec : node server/index.js',
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
        ),
        onTap: _edit,
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeTokens tokens;
  const _SectionHeader(this.title, this.tokens);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: tokens.accentDeep,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
