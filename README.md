# 📦 Collection App

> Application mobile **Flutter** pour suivre vos collections physiques — style vignettes Panini.  
> **Offline-first · SQLite · Riverpod · go_router**

---

## ✨ Fonctionnalités

- 🗂️ **Multi-collections** — gérez autant de collections que vous voulez (verres moutarde, cartes, figurines, vignettes...)
- 🖼️ **Grille visuelle** — affichage style album Panini avec images grisées pour les items manquants
- ✅ **Marqueur de possession** — appui long sur un item pour l'ajouter à votre collection, badge vert instantané
- 🔍 **Fiche détail** — galerie photo swipeable, infos techniques, notes personnelles
- 📥 **Import JSON** — téléchargez une collection existante depuis une URL ou un fichier local
- 📷 **Photo personnalisée** — ajoutez vos propres photos depuis l'appareil photo ou la galerie
- 💾 **100% offline** — toutes les données stockées localement en SQLite, aucun compte requis

---

## 📱 Captures d'écran

> *(à venir)*

---

## 🚀 Démarrage rapide

### Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.2.0`
- Android SDK ou iOS Simulator

### Installation

```bash
git clone https://github.com/Guezzboy/ca_shellscripts.git
cd ca_shellscripts
flutter pub get
flutter run
```

### Build APK (Android)

```bash
flutter build apk --split-per-abi
```

L'APK se trouve dans `build/app/outputs/flutter-apk/`.

---

## 🗂️ Architecture

```
lib/
├── main.dart                         # Point d'entrée + init BDD
├── app.dart                          # MaterialApp.router
├── router.dart                       # Routes go_router
├── shared/theme/app_theme.dart       # Thème cardboard Panini
├── core/
│   ├── database/database_helper.dart # Setup sqflite
│   ├── models/                       # Modèles Dart (PODO)
│   ├── repositories/                 # Accès base de données
│   ├── providers/                    # Providers Riverpod
│   └── services/                     # Service téléchargement HTTP
└── features/
    ├── collection/                   # Écrans principaux (grille, liste)
    ├── add_item/                     # Ajout manuel + photo
    ├── download/                     # Import JSON distant
    └── settings/                     # Paramètres
```

---

## 🧰 Stack technique

| Composant       | Package                    | Version   |
|-----------------|----------------------------|-----------|
| State           | `flutter_riverpod`         | ^2.5.1    |
| Navigation      | `go_router`                | ^13.2.0   |
| Base de données | `sqflite`                  | ^2.3.2    |
| HTTP            | `dio`                      | ^5.4.3    |
| Photo mobile    | `image_picker`             | ^1.1.2    |
| Fichiers bureau | `file_picker`              | ^8.0.0    |
| Préférences     | `shared_preferences`       | ^2.2.3    |
| UUID            | `uuid`                     | ^4.4.0    |

---

## 📄 Format JSON des collections

Les collections peuvent être importées via une URL ou un fichier `.json` local.  
Format attendu :

```json
{
  "id": "identifiant-stable",
  "name": "Nom de la collection",
  "version": 1,
  "items": [
    {
      "id": "item-001",
      "name": "Pikachu",
      "number": "001",
      "image_url": "https://example.com/pikachu.png",
      "year": "1999",
      "series": "Vague 1",
      "description": "Verre moutarde Amora édition Pokémon gen 1"
    }
  ]
}
```

---

## 🗃️ Données de démo

Le dossier [`sample_data/`](./sample_data/) contient plusieurs collections prêtes à l'emploi :

| Fichier                  | Collection                        | Items |
|--------------------------|-----------------------------------|-------|
| `amora_pokemon.json`     | 🟡 Verres moutarde Pokémon Amora  | ~66   |
| `amora_disney.json`      | 🏰 Verres moutarde Disney Amora   | ~20   |
| `panini_fifa2026.json`   | ⚽ Vignettes Panini FIFA 2026     | ~20   |
| `nintendo_smash.json`    | 🎮 Figurines Smash Bros Nintendo  | ~20   |
| `magic_mtg.json`         | 🧙 Cartes Magic The Gathering     | ~20   |

Ces fichiers peuvent être hébergés sur **GitHub Pages** ou tout serveur statique pour tester l'import distant.

---

## 🗺️ Roadmap

- [x] **Phase 1 — Core** : grille Panini, ajout manuel, marqueur possédé, SQLite
- [ ] **Phase 2 — UX** : fiche détail avec galerie, appui long pour possession, barre de progression
- [ ] **Phase 3 — Import intelligent** : recherche automatique de collection par nom
- [ ] **Phase 4 — OCR** : Google ML Kit (hooks prêts dans `add_photo_screen.dart`)
- [ ] **Phase 5 — Sync** : export/import JSON, Syncthing

---

## 📝 Licence

Projet personnel — usage libre.

---

> Vibe coded avec ❤️ et [Claude Code](https://claude.ai/code)
