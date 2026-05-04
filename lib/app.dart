import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/theme_provider.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'router.dart';
import 'shared/theme/app_theme.dart';

/// Root widget that gates the app behind the onboarding flow.
class AppWithOnboarding extends ConsumerStatefulWidget {
  const AppWithOnboarding({super.key});

  @override
  ConsumerState<AppWithOnboarding> createState() => _AppWithOnboardingState();
}

class _AppWithOnboardingState extends ConsumerState<AppWithOnboarding> {
  bool _onboardingDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOnboarding());
  }

  Future<void> _maybeShowOnboarding() async {
    if (_onboardingDone) return;
    if (await OnboardingScreen.shouldShow()) {
      if (!mounted) return;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => OnboardingScreen(
            onDone: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }
    if (mounted) setState(() => _onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    return const CollectionApp();
  }
}

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
