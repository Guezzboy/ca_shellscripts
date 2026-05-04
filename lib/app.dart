import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/theme_provider.dart';
import 'router.dart';
import 'shared/theme/app_theme.dart';

class CollectionApp extends ConsumerWidget {
  const CollectionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeKey = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Colectio',
      theme: AppTheme.buildTheme(themeKey),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
