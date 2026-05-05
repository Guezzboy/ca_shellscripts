# 📦 Collection App

> Application mobile **Flutter** pour suivre vos collections physiques — style vignettes Panini.  
> **Offline-first · SQLite · Riverpod · go_router**

---

## ✨ Fonctionnalités

- 🏠 **Écran d'accueil** — progression globale, journal d'activité (dernier ajout, badges débloqués, résumé de la veille)
- 🗂️ **Multi-collections** — gérez autant de collections que vous voulez (verres moutarde, cartes, figurines, vignettes...)
- 🖼️ **Grille visuelle** — affichage style album Panini avec images grisées pour les items manquants
- ✅ **3 états par item** — neutre / recherché (🔍 badge ambre) / possédé (✓ badge vert). Cycle par appui long
- 📱 **Scan ISBN** — scannez un code-barres de livre, récupération automatique des métadonnées via Open Library / Google Books
- 📋 **Mode Vide-Grenier** — vue liste compacte avec swipe actions (droite → possédé, gauche → retirer), partage de wishlist
- 🔍 **Fiche détail** — galerie photo swipeable, infos techniques, notes personnelles, double CTA (chercher / posséder)
- 📥 **Import JSON** — téléchargez une collection existante depuis une URL ou un fichier local (4 formats supportés)
- 📤 **Export JSON** — exportez toutes vos collections avec état owned/wanted pour round-trip
- 📷 **Photo + OCR** — ajoutez des items via appareil photo, reconnaissance automatique du texte avec Google ML Kit
- 🏆 **Badges** — 7 badges à débloquer (Premier pas, Collectionneur, Chasseur, Photographe, Expert, Détective, Sauvegarde)
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
├── shared/theme/app_theme.dart       # 3 thèmes (Solaire, Naturel, Nuit)
├── core/
│   ├── database/database_helper.dart # Setup sqflite
│   ├── models/                       # Modèles Dart (PODO)
│   ├── repositories/                 # Accès base de données
│   ├── providers/                    # Providers Riverpod
│   └── services/                     # HTTP, export, badges, ISBN
└── features/
    ├── home/                         # Accueil — progression + journal
    ├── collection/                   # Écrans principaux (grille, liste, fiche)
    ├── add_item/                     # Ajout manuel + photo + OCR
    ├── download/                     # Import JSON distant/local
    ├── scanner/                      # Scan ISBN + photo
    ├── catalogue/                    # Catalogue de collections publiques
    ├── badges/                       # Overlay de badges
    ├── onboarding/                   # Wizard 3 étapes
    └── settings/                     # Paramètres (thème, import/export, proxy)
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
| Scan code-barre | `mobile_scanner`           | ^5.0.0    |
| Partage texte   | `share_plus`               | ^9.0.0    |
| OCR / Texte     | `google_mlkit_text_recognition` | ^0.14.0 |

---

## 🔍 Recherche de collections

L'écran **Découvrir** propose une recherche par nom parmi les collections populaires (Pokémon, Disney, FIFA, Nintendo, MTG). Les collections sont téléchargées directement depuis GitHub — aucune configuration ni serveur requis.

- Tape un nom de collection → les résultats apparaissent avec le nombre d'items
- Clique sur "Charger" → la collection est importée avec tous ses items
- Tu peux aussi importer un fichier JSON local ou une URL personnalisée

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
- [x] **Phase 2 — UX enrichie** : galerie swipeable, 3 états item (recherché/possédé), double CTA, scan ISBN, mode Vide-Grenier
- [x] **Phase 3 — Import intelligent** : recherche de collection par nom + GitHub, import JSON local/URL
- [x] **Phase 4 — OCR** : Google ML Kit text recognition, suggestion auto du nom depuis les photos
- [x] **Phase 5 — Sync** : export JSON avec état owned/wanted, partage via share sheet, import existant
- [x] **Phase 6 — Accueil vivant** : progression réelle, journal d'activité (derniers ajouts, badges, résumé quotidien)

---

## 📝 Licence

Projet personnel — usage libre.

---

> Vibe coded avec ❤️ et [Claude Code](https://claude.ai/code)
