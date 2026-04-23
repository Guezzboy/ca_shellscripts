import 'package:go_router/go_router.dart';
import 'features/collection/screens/collections_list_screen.dart';
import 'features/collection/screens/collection_detail_screen.dart';
import 'features/add_item/screens/add_item_screen.dart';
import 'features/add_item/screens/add_photo_screen.dart';
import 'features/download/screens/download_screen.dart';
import 'features/settings/screens/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const CollectionsListScreen(),
    ),
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
      path: '/download',
      builder: (context, state) => const DownloadScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
