# Wanderweg — Multi-City Walking Tour Guide

A walking-first virtual tour guide app for an unhurried, multi-city trip to Germany.
**Walking only. No booking. No checkouts. No payments. No affiliate links. Just a great walk.**

Built with Flutter following the Wanderweg specification.

---

## Wednesday Demo Status

### Cities & Content Packs
- **Berlin**: Code- and test-verified prototype. Includes 3 walks and all confirmed anchors (*Brandenburg Gate, Reichstag, Unter den Linden, Checkpoint Charlie, East Side Gallery*). East Side Gallery is handled as an eastward finish / separate transit segment, never forced on foot into the central walk. Bundled with 7.0 MB SQLite MBTiles (236 genuine OpenStreetMap pedestrian tiles) for full airplane-mode offline navigation.
- **Dresden (Demo Proposal)**: Approved 1-day Baroque Spine (*Frauenkirche → Brühl's Terrace → Zwinger → Semperoper → Residenzschloss*) with Innere Neustadt extension across the Elbe. Marked as demo proposal until ground-walked.
- **Leipzig (Demo Proposal)**: Approved 1-day central spine weaving Bach's musical legacy and the 1989 Peaceful Revolution (*Markt / Altes Rathaus → Nikolaikirche → Mädler Passage → Thomaskirche → Augustusplatz*). Marked as demo proposal until ground-walked.
- **Austria (Schema Stub)**: Pure stub country in the manifest to demonstrate multi-country schema readiness with zero invented cities, anchors, or packs.

> [!NOTE]
> **Ground Verification Honesty**: Content packs are code- and automated-test verified. Food hours, prices, and walking timings have not yet been walked on the ground in Germany.

---

## Core Features

1. **Manifest-Driven Country & Multi-City Trip Planner**:
   - Pick a country dynamically from `city-manifest.json` (zero hardcoding).
   - Reorder trip cities with `[▲]` / `[▼]`.
   - Set stay length per city (defaults to 1 day, adjustable 1–7 days). Daily plans resize dynamically instead of cramming.
2. **Offline-First Airplane Mode Architecture**:
   - Bundles Berlin map tiles in SQLite MBTiles format (7.0 MB).
   - Seamless airplane-mode map navigation with honest status indicators.
3. **Appearance & Background**:
   - **Moon Mode Default**: High-contrast dark background (`#101418` dark canvas, `#192027` elevated cards, `#F2F5F8` text) optimized for outdoor night-walk readability and OLED battery saving.
   - **1-Tap Quick Toggle**: Sun/Moon (`☀`/`☾`) icon in the top AppBar across all tabs.
   - **Preferences**: Selectable `[ ☀ Light BG ]` and `[ 🌙 Dark BG ]` chips in Saved → Preferences.
4. **Live Walk Mode**:
   - Plain-language pedestrian directions.
   - 1-minute stop cards answering the 5 core spec questions.
   - Off-route recovery and "End early to nearest station" shortcut.
   - Multi-city Trip Journal logging distance and dwell times across cities.

---

## Local Development & Testing

```bash
# Run static analysis (0 issues)
flutter analyze

# Run unit and widget test suite (37 tests)
flutter test

# Launch on Chrome Web
flutter run -d chrome

# Build for Web Release
flutter build web --release --base-href /Wanderweg/
```
