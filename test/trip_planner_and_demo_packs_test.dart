import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderweg/models/city.dart';
import 'package:wanderweg/models/walk.dart';
import 'package:wanderweg/state/app_state.dart';
import 'package:wanderweg/ui/tabs/cities_tab.dart';
import 'package:wanderweg/ui/tabs/saved_tab.dart';
import 'package:wanderweg/ui/tabs/today_tab.dart';
import 'package:wanderweg/ui/tabs/walks_tab.dart';
import 'package:wanderweg/ui/theme/app_theme.dart';

void main() {
  group('Trip Planner & Demo Packs: Manifest & Content Verification', () {
    test('Manifest is dynamic, contains Germany and Austria with no hardcoding', () {
      final manifestFile = File('assets/content/city-manifest.json');
      expect(manifestFile.existsSync(), isTrue);

      final jsonMap = json.decode(manifestFile.readAsStringSync());
      final countries = (jsonMap['countries'] as List<dynamic>)
          .map((c) => Country.fromJson(c as Map<String, dynamic>))
          .toList();

      expect(countries.length, greaterThanOrEqualTo(2));
      final de = countries.firstWhere((c) => c.id == 'de');
      expect(de.nameEn, 'Germany');
      expect(de.cities.map((c) => c.id).toList(), containsAll(['berlin', 'dresden', 'leipzig']));

      final at = countries.firstWhere((c) => c.id == 'at');
      expect(at.nameEn, 'Austria');
      expect(at.cities, isEmpty); // Pure stub country for multi-country schema readiness, zero invented anchors/packs
    });

    test('Dresden demo pack contains 1-day Baroque spine and Neustadt extension', () {
      final packFile = File('assets/content/dresden-pack.json');
      expect(packFile.existsSync(), isTrue);

      final packJson = json.decode(packFile.readAsStringSync());
      expect(packJson['city']['status'], 'demo');
      expect(packJson['city']['id'], 'dresden');

      final walks = (packJson['walks'] as List<dynamic>)
          .map((w) => Walk.fromJson(w as Map<String, dynamic>))
          .toList();

      expect(walks.length, 2);
      final coreWalk = walks.firstWhere((w) => w.id == 'dresden-baroque-spine');
      expect(coreWalk.priorityTier, 'core');
      expect(coreWalk.distanceKm, 2.8);
      expect(coreWalk.stops, [
        'dresden-frauenkirche',
        'dresden-bruehls-terrace',
        'dresden-zwinger',
        'dresden-semperoper',
        'dresden-residenzschloss',
      ]);

      final extWalk = walks.firstWhere((w) => w.id == 'dresden-neustadt-extension');
      expect(extWalk.priorityTier, 'extension');
      expect(extWalk.stops, contains('dresden-goldener-reiter'));

      // Check all 5 questions on stop cards
      final stops = packJson['stops'] as List<dynamic>;
      expect(stops.length, greaterThanOrEqualTo(5));
      for (final s in stops) {
        expect(s['what_am_i_looking_at'], isNotNull);
        expect(s['why_it_matters'], isNotNull);
        expect(s['what_to_notice'], isNotNull);
        expect(s['dwell_time_minutes'], isNotNull);
        expect(s['local_tip'], isNotNull);
        expect(s['entry_cost_band'], isNotNull);
        expect(s['last_verified_date'], 'unverified_demo');
      }
    });

    test('Leipzig demo pack weaves Bach musical heritage and Peaceful Revolution', () {
      final packFile = File('assets/content/leipzig-pack.json');
      expect(packFile.existsSync(), isTrue);

      final packJson = json.decode(packFile.readAsStringSync());
      expect(packJson['city']['status'], 'demo');
      expect(packJson['city']['id'], 'leipzig');

      final walks = (packJson['walks'] as List<dynamic>)
          .map((w) => Walk.fromJson(w as Map<String, dynamic>))
          .toList();

      expect(walks.length, 1);
      final coreWalk = walks.first;
      expect(coreWalk.id, 'leipzig-bach-revolution');
      expect(coreWalk.priorityTier, 'core');
      expect(coreWalk.distanceKm, 2.6);
      expect(coreWalk.stops, [
        'leipzig-markt',
        'leipzig-nikolaikirche',
        'leipzig-maedler-passage',
        'leipzig-thomaskirche',
        'leipzig-augustusplatz',
      ]);

      // Verify Bach & Peaceful Revolution story in stops
      final stops = packJson['stops'] as List<dynamic>;
      final nikolai = stops.firstWhere((s) => s['id'] == 'leipzig-nikolaikirche');
      expect(nikolai['why_it_matters'], contains('Peaceful Revolution'));
      expect(nikolai['why_it_matters'], contains('Wir sind das Volk'));

      final thomas = stops.firstWhere((s) => s['id'] == 'leipzig-thomaskirche');
      expect(thomas['why_it_matters'], contains('Bach'));
      expect(thomas['what_to_notice'], contains('Bach'));
    });

    test('Offline status is reported honestly per city', () {
      final manifestFile = File('assets/content/city-manifest.json');
      final jsonMap = json.decode(manifestFile.readAsStringSync());
      final cities = (jsonMap['cities'] as List<dynamic>)
          .map((c) => CitySummary.fromJson(c as Map<String, dynamic>))
          .toList();

      final berlin = cities.firstWhere((c) => c.id == 'berlin');
      expect(berlin.isOfflineVerified, isTrue);
      expect(berlin.hasOfflineTiles, isTrue);
      expect(berlin.formattedSize, '1.77 MB');

      final dresden = cities.firstWhere((c) => c.id == 'dresden');
      expect(dresden.isOfflineVerified, isFalse);
      expect(dresden.hasOfflineTiles, isFalse);

      final leipzig = cities.firstWhere((c) => c.id == 'leipzig');
      expect(leipzig.isOfflineVerified, isFalse);
      expect(leipzig.hasOfflineTiles, isFalse);
    });
  });

  group('Multi-City Trip Planner Logic in AppState', () {
    late AppState state;

    setUp(() async {
      state = AppState();
      await state.initialize();
    });

    test('Initializes with default country Germany and 3 cities in trip', () {
      expect(state.selectedCountryId, 'de');
      expect(state.tripCityIds, ['berlin', 'dresden', 'leipzig']);
      expect(state.totalTripDays, 3); // 1 + 1 + 1 = 3 days
    });

    test('Reordering cities in trip functions correctly', () {
      expect(state.tripCityIds.first, 'berlin');
      state.moveCityInTrip(0, 1); // Move Berlin to second position
      expect(state.tripCityIds, ['dresden', 'berlin', 'leipzig']);

      state.moveCityInTrip(2, 0); // Move Leipzig to front
      expect(state.tripCityIds, ['leipzig', 'dresden', 'berlin']);
    });

    test('Adjusting stay days resizes trip total without hardcoded limits', () {
      expect(state.getStayDays('berlin'), 1);
      state.setStayDays('berlin', 3);
      state.setStayDays('dresden', 2);
      state.setStayDays('leipzig', 1);

      expect(state.totalTripDays, 6); // 3 + 2 + 1 = 6 days
    });

    test('Dynamic plan resizing: 1 day shows 1 core walk, 2 days shows extension', () {
      state.setActiveCity('dresden');
      state.setStayDays('dresden', 1);
      var proposed = state.getProposedWalksForStay();
      expect(proposed.length, 1);
      expect(proposed.first.id, 'dresden-baroque-spine');

      // Expand stay to 2 days
      state.setStayDays('dresden', 2);
      proposed = state.getProposedWalksForStay();
      expect(proposed.length, 2);
      expect(proposed.any((w) => w.id == 'dresden-neustadt-extension'), isTrue);
    });

    test('Trip journal carries entries across different cities', () {
      // Complete a walk in Berlin
      final berlinWalk = state.repo.getWalk('berlin-mitte-essentials')!;
      state.startLiveWalk(berlinWalk);
      state.finishWalk();

      expect(state.journal.length, 1);
      expect(state.journal.first.cityName, 'Berlin');

      // Switch to Dresden and complete a walk
      final dresdenWalk = state.repo.getWalk('dresden-baroque-spine')!;
      state.startLiveWalk(dresdenWalk);
      state.finishWalk();

      expect(state.journal.length, 2);
      expect(state.journal.last.cityName, 'Dresden');

      // Switch to Leipzig and end early
      final leipzigWalk = state.repo.getWalk('leipzig-bach-revolution')!;
      state.startLiveWalk(leipzigWalk);
      state.endWalkEarly();

      expect(state.journal.length, 3);
      expect(state.journal.last.cityName, 'Leipzig');
    });

    test('User preferences persist across all cities in trip', () {
      expect(state.hasPreference('step_free'), isTrue);
      state.togglePreference('vegetarian');
      expect(state.hasPreference('vegetarian'), isTrue);

      // Change active city: preferences remain intact
      state.setActiveCity('dresden');
      expect(state.hasPreference('vegetarian'), isTrue);
      state.setActiveCity('leipzig');
      expect(state.hasPreference('vegetarian'), isTrue);
    });
  });

  group('Trip Planner & Demo Tabs Widget Testing', () {
    testWidgets('CitiesTab shows Country selector and multi-city trip planner', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      await state.initialize();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CitiesTab(state: state),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Step 1: Pick a Country'), findsOneWidget);
      expect(find.textContaining('Germany'), findsWidgets);
      expect(find.textContaining('Austria'), findsWidgets);
      expect(find.text('Step 2: Plan Your Germany Trip'), findsOneWidget);
      expect(find.textContaining('3 Cities in Trip'), findsOneWidget);
    });

    testWidgets('TodayTab dynamically updates when active city switches', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      await state.initialize();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ListenableBuilder(
            listenable: state,
            builder: (ctx, _) => TodayTab(state: state, onStartLiveWalk: () {}),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Initially Berlin
      expect(find.text('Today in Berlin'), findsOneWidget);
      expect(find.textContaining('Trip Day 1 of 3'), findsOneWidget);

      // Switch to Dresden
      state.setActiveCity('dresden');
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Today in Dresden'), findsOneWidget);
      expect(find.textContaining('Trip Day 2 of 3'), findsOneWidget);
      expect(find.text('Dresden Baroque Spine: Frauenkirche, Zwinger & Elbe Terraces'), findsOneWidget);
      expect(find.textContaining('Wednesday Demo Proposal'), findsOneWidget);

      // Switch to Leipzig
      state.setActiveCity('leipzig');
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Today in Leipzig'), findsOneWidget);
      expect(find.textContaining('Trip Day 3 of 3'), findsOneWidget);
      expect(find.text('Leipzig Heritage: Bach, Passages & Peaceful Revolution'), findsOneWidget);
    });

    testWidgets('WalksTab displays active city walks and demo notice', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      await state.initialize();
      state.setActiveCity('dresden');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: WalksTab(
            state: state,
            onStartLiveWalk: () {},
            onNavigateToMap: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Dresden Walks'), findsOneWidget);
      expect(find.text('Dresden Baroque Spine: Frauenkirche, Zwinger & Elbe Terraces'), findsOneWidget);
      expect(find.text('Neustadt Extension: Augustusbrücke & Golden Rider'), findsOneWidget);
      expect(find.textContaining('Demo Proposals for Dresden'), findsOneWidget);
    });

    testWidgets('SavedTab displays multi-city Trip Journal and Preferences', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      await state.initialize();

      // Log a walk in Dresden
      state.setActiveCity('dresden');
      final walk = state.repo.getWalk('dresden-baroque-spine')!;
      state.startLiveWalk(walk);
      state.finishWalk();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SavedTab(
            state: state,
            onStartLiveWalk: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Trip Journal'), findsOneWidget);
      expect(find.text('Preferences'), findsOneWidget);

      // Switch to Trip Journal tab
      await tester.tap(find.text('Trip Journal'));
      await tester.pumpAndSettle();

      expect(find.text('DRESDEN'), findsOneWidget);
      expect(find.text('Dresden Baroque Spine: Frauenkirche, Zwinger & Elbe Terraces'), findsOneWidget);

      // Switch to Preferences tab
      await tester.tap(find.text('Preferences'));
      await tester.pumpAndSettle();

      expect(find.text('Universal Trip Preferences'), findsOneWidget);
      expect(find.text('Step-Free / Accessible Routes'), findsOneWidget);
      expect(find.text('Vegetarian Options'), findsOneWidget);
    });
  });
}
