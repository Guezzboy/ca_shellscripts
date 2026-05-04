# Colectio

> Application Flutter de gestion de collections physiques (vignettes style Panini).
> Offline-first · SQLite · Riverpod · go_router

## Architecture

```
lib/
├── main.dart                    # Entry point + DB init
├── app.dart                     # MaterialApp.router
├── router.dart                  # go_router — StatefulShellRoute (5 tabs) + push routes
├── shared/
│   ├── theme/app_theme.dart     # 3-theme system (Solaire/Naturel/Nuit) + ThemeTokens
│   └── widgets/
│       ├── app_shell.dart       # Bottom nav + center-docked scan FAB
│       └── progress_ring.dart   # Animated SVG-style ring
├── core/
│   ├── database/database_helper.dart
│   ├── models/
│   ├── repositories/
│   ├── providers/               # Riverpod providers (incl. theme_provider.dart)
│   └── services/                # HTTP, export, search, ISBN lookup
└── features/
    ├── home/                     # Accueil — progress ring + journal feed
    ├── collection/               # Liste, détail, création, item detail
    ├── add_item/                 # Ajout manuel + photo + OCR
    ├── download/                 # Téléchargement JSON
    ├── scanner/                  # Scanner code-barres + photo
    ├── catalogue/                # Bibliothèque de catalogues
    ├── badges/                   # Badge overlay
    ├── onboarding/               # Onboarding 3-step wizard
    └── settings/                 # Thème, export, import, about
```

## Stack

| Composant | Package |
|-----------|---------|
| State | flutter_riverpod |
| Navigation | go_router (StatefulShellRoute) |
| DB | sqflite |
| HTTP | dio |
| Photo | image_picker |
| OCR | google_mlkit_text_recognition |
| Scan | mobile_scanner |
| Share | share_plus |
| Prefs | shared_preferences |

## Themes

3 themes sélectionnables via Settings: Solaire (default amber), Naturel (sage green), Nuit (dark).
ThemeProvider persiste le choix dans SharedPreferences. Extension `context.themeTokens`
disponible sur tous les BuildContext.

## Build

```bash
flutter pub get
flutter run                  # debug
flutter build apk --split-per-abi   # release APK
```

## Données de démo

Les fichiers JSON dans `sample_data/` peuvent être hébergés sur GitHub Pages
ou tout serveur statique pour tester le téléchargement de collections.
