# Collection App

> Application Flutter de gestion de collections physiques (vignettes style Panini).
> Offline-first · SQLite · Riverpod · go_router

## Architecture

```
lib/
├── main.dart                    # Entry point + DB init
├── app.dart                     # MaterialApp.router
├── router.dart                  # go_router routes
├── shared/theme/app_theme.dart  # Thème cardboard Panini
├── core/
│   ├── database/database_helper.dart   # sqflite setup
│   ├── models/                         # PODO (plain Dart)
│   ├── repositories/                   # Accès BDD
│   ├── providers/                      # Riverpod providers
│   └── services/                       # HTTP download service
└── features/
    ├── collection/                      # Écrans principaux
    ├── add_item/                        # Ajout manuel + photo
    ├── download/                        # Téléchargement JSON
    └── settings/                        # Paramètres
```

## Stack

| Composant | Package |
|-----------|---------|
| State | flutter_riverpod |
| Navigation | go_router |
| DB | sqflite |
| HTTP | dio |
| Photo | image_picker |

## Format JSON (download)

```json
{
  "id": "stable-collection-id",
  "name": "Ma Collection",
  "version": 1,
  "items": [
    { "id": "item-001", "name": "Mickey Mouse", "number": "001", "image_url": "..." }
  ]
}
```

## Phases

- [x] Phase 1 — Core: grille Panini, ajout manuel, marqueur possédé, SQLite
- [ ] Phase 2 — OCR: Google ML Kit (hooks prêts dans `add_photo_screen.dart`)
- [ ] Phase 3 — Sync: export/import JSON, Syncthing

## Build

```bash
flutter pub get
flutter run                  # debug
flutter build apk --split-per-abi   # release APK
```

## Données de démo

Les fichiers JSON dans `sample_data/` peuvent être hébergés sur GitHub Pages
ou tout serveur statique pour tester le téléchargement de collections.
