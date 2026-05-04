import 'package:go_router/go_router.dart';
import 'shared/widgets/app_shell.dart';
import 'features/home/screens/home_screen.dart';
import 'features/collection/screens/collections_list_screen.dart';
import 'features/collection/screens/collection_detail_screen.dart';
import 'features/collection/screens/create_collection_screen.dart';
import 'features/add_item/screens/add_item_screen.dart';
import 'features/add_item/screens/add_photo_screen.dart';
import 'features/download/screens/download_screen.dart';
import 'features/scanner/screens/scanner_screen.dart';
import 'features/catalogue/screens/catalogue_screen.dart';
import 'features/settings/screens/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        // ── Tab 0: Accueil ──
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // ── Tab 1: Collections ──
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/collections',
              builder: (context, state) => const CollectionsListScreen(),
            ),
          ],
        ),
        // ── Tab 2: Scanner (FAB) — dummy, scanner opens as push route ──
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/scan',
              builder: (context, state) => const ScannerScreen(),
            ),
          ],
        ),
        // ── Tab 3: Catalogue ──
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/catalogue',
              builder: (context, state) => const CatalogueScreen(),
            ),
          ],
        ),
        // ── Tab 4: Réglages ──
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // ── Push routes (no bottom nav) ──
    GoRoute(
      path: '/collection/:id',
      builder: (context, state) => CollectionDetailScreen(
        collectionId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/add-item/:collectionId',
      builder: (context, state) => AddItemScreen(
        collectionId: state.pathParameters['collectionId']!,
      ),
    ),
    GoRoute(
      path: '/add-photo/:collectionId',
      builder: (context, state) => AddPhotoScreen(
        collectionId: state.pathParameters['collectionId']!,
      ),
    ),
    GoRoute(
      path: '/create-collection',
      builder: (context, state) => const CreateCollectionScreen(),
    ),
    GoRoute(
      path: '/download',
      builder: (context, state) => const DownloadScreen(),
    ),
  ],
);
