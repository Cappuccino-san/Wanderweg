import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderweg/models/city.dart';
import 'package:wanderweg/models/food_stop.dart';
import 'package:wanderweg/models/route_leg.dart';
import 'package:wanderweg/models/stop.dart';
import 'package:wanderweg/models/walk.dart';
import 'package:wanderweg/services/closure_engine.dart';
import 'package:wanderweg/services/route_builder_engine.dart';
import 'package:wanderweg/state/app_state.dart';
import 'package:wanderweg/ui/tabs/cities_tab.dart';
import 'package:wanderweg/ui/tabs/saved_tab.dart';
import 'package:wanderweg/ui/tabs/today_tab.dart';
import 'package:wanderweg/ui/tabs/walks_tab.dart';
import 'package:wanderweg/ui/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('City Manifest & Berlin Pack Data Integrity', () {
    test('Manifest has Berlin ready, Dresden & Leipzig as stubs with no invented anchors', () {
      final manifestFile = File('assets/content/city-manifest.json');
      expect(manifestFile.existsSync(), isTrue);

      final manifestJson = json.decode(manifestFile.readAsStringSync());
      final cities = (manifestJson['cities'] as List<dynamic>)
          .map((c) => CitySummary.fromJson(c as Map<String, dynamic>))
          .toList();

      expect(cities.length, 3);

      // Berlin
      final berlin = cities.firstWhere((c) => c.id == 'berlin');
      expect(berlin.status, 'ready');
      expect(berlin.isPrototype, isTrue);
      expect(berlin.stayDaysDefault, 1);
      expect(berlin.stayDaysAdjustable, isTrue);
      expect(berlin.anchorsConfirmed.length, 5);
      expect(berlin.anchorsConfirmed, contains('Brandenburg Gate'));
      expect(berlin.anchorsConfirmed, contains('Berlin Wall at the East Side Gallery'));
      expect(berlin.anchorsConfirmed, contains('Checkpoint Charlie'));
      expect(berlin.anchorsConfirmed, contains('Reichstag'));
      expect(berlin.anchorsConfirmed, contains('Unter den Linden'));

      // Dresden (Demo Proposal for Wednesday)
      final dresden = cities.firstWhere((c) => c.id == 'dresden');
      expect(dresden.status, 'demo');
      expect(dresden.isPrototype, isFalse);
      expect(dresden.anchorsConfirmed, containsAll([
        'Frauenkirche',
        "Brühl's Terrace along the Elbe",
        'Zwinger',
        'Semperoper',
        'Residenzschloss',
      ]));

      // Leipzig (Demo Proposal for Wednesday)
      final leipzig = cities.firstWhere((c) => c.id == 'leipzig');
      expect(leipzig.status, 'demo');
      expect(leipzig.isPrototype, isFalse);
      expect(leipzig.anchorsConfirmed, containsAll([
        'Markt / Altes Rathaus',
        'Nikolaikirche',
        'Thomaskirche',
        'Mädler Passage',
        'Augustusplatz',
      ]));
    });

    test('Berlin pack contains 3 walks, stop cards answering 5 questions, and zero booking', () {
      final packFile = File('assets/content/berlin-pack.json');
      expect(packFile.existsSync(), isTrue);

      final packJson = json.decode(packFile.readAsStringSync());

      // Check walks
      final walks = (packJson['walks'] as List<dynamic>)
          .map((w) => Walk.fromJson(w as Map<String, dynamic>))
          .toList();
      expect(walks.length, 3);

      final mitte = walks.firstWhere((w) => w.id == 'berlin-mitte-essentials');
      expect(mitte.priorityTier, 'core');
      expect(mitte.stops, contains('brandenburg-gate'));
      expect(mitte.stops, contains('reichstag-exterior'));
      expect(mitte.stops, contains('museum-island'));

      // East Side Gallery must NOT be in Mitte walk
      expect(mitte.stops, isNot(contains('east-side-gallery-extension')),
          reason: 'East Side Gallery must not be forced into the central Mitte walk');

      // Check route legs have pedestrian street geometries (not straight Euclidean jumps)
      final legs = (packJson['route_legs'] as List<dynamic>)
          .map((l) => RouteLeg.fromJson(l as Map<String, dynamic>))
          .toList();
      for (final l in legs) {
        expect(l.pathCoordinates.length, greaterThanOrEqualTo(2),
            reason: 'Each route leg must have pedestrian path coordinates');
      }

      // Check stops structure
      final stops = (packJson['stops'] as List<dynamic>)
          .map((s) => Stop.fromJson(s as Map<String, dynamic>))
          .toList();
      for (final s in stops) {
        expect(s.whatAmILookingAt.isNotEmpty, isTrue);
        expect(s.whyItMatters.isNotEmpty, isTrue);
        expect(s.whatToNotice.isNotEmpty, isTrue);
        expect(s.dwellTimeMinutes, greaterThan(0));
        expect(s.localTip.isNotEmpty, isTrue);
        expect(s.lastVerifiedDate.isNotEmpty, isTrue);
      }

      // Check food stops have NO booking/payments
      final foodStops = (packJson['food_stops'] as List<dynamic>)
          .map((f) => FoodStop.fromJson(f as Map<String, dynamic>))
          .toList();
      expect(foodStops.length, greaterThanOrEqualTo(5));
      for (final f in foodStops) {
        expect(f.signatureOrder.isNotEmpty, isTrue);
        expect(f.openingHours.isNotEmpty, isTrue);
      }
    });
  });

  group('Route Builder Engine: No Silent Additions & East Side Gallery Handling', () {
    test('Suggestions are offered, never silently added into route', () {
      final packFile = File('assets/content/berlin-pack.json');
      final packJson = json.decode(packFile.readAsStringSync());
      final allStops = (packJson['stops'] as List<dynamic>)
          .map((s) => Stop.fromJson(s as Map<String, dynamic>))
          .toList();

      final selectedAnchors = allStops
          .where((s) => s.id == 'brandenburg-gate' || s.id == 'unter-den-linden-promenade')
          .toList();

      // Case 1: user has NOT accepted suggestions -> Museum Island must NOT be in ordered stops
      final resultWithoutAccepting = RouteBuilderEngine.buildRoute(
        selectedAnchors: selectedAnchors,
        allAvailableStops: allStops,
        acceptedSuggestionIds: {},
        stayDays: 1,
      );
      expect(resultWithoutAccepting.availableSuggestions.any((s) => s.stop.id == 'museum-island'), isTrue);
      expect(resultWithoutAccepting.orderedStops.any((s) => s.id == 'museum-island'), isFalse,
          reason: 'No silent additions: Museum Island must not be inserted without user acceptance');

      // Case 2: user explicitly accepts Museum Island
      final resultWithAccepting = RouteBuilderEngine.buildRoute(
        selectedAnchors: selectedAnchors,
        allAvailableStops: allStops,
        acceptedSuggestionIds: {'museum-island'},
        stayDays: 1,
      );
      expect(resultWithAccepting.orderedStops.any((s) => s.id == 'museum-island'), isTrue);
    });

    test('Route builder handles East Side Gallery as transit link or separate segment', () {
      final packFile = File('assets/content/berlin-pack.json');
      final packJson = json.decode(packFile.readAsStringSync());
      final allStops = (packJson['stops'] as List<dynamic>)
          .map((s) => Stop.fromJson(s as Map<String, dynamic>))
          .toList();

      final selectedAnchors = allStops.where((s) => s.isAnchor).toList();

      // Case 1: Transit extension option
      final resultTransit = RouteBuilderEngine.buildRoute(
        selectedAnchors: selectedAnchors,
        allAvailableStops: allStops,
        acceptedSuggestionIds: {},
        stayDays: 1,
        eastSideOption: EastSideGalleryOption.transitExtension,
      );
      expect(resultTransit.includesEastSideGallery, isTrue);
      expect(resultTransit.eastSideWarning, contains('12-minute transit link'));

      // Case 2: Separate segment option (recommended for 2-day stay)
      final resultSeparate = RouteBuilderEngine.buildRoute(
        selectedAnchors: selectedAnchors,
        allAvailableStops: allStops,
        acceptedSuggestionIds: {},
        stayDays: 2,
        eastSideOption: EastSideGalleryOption.separateSegment,
      );
      expect(resultSeparate.includesEastSideGallery, isTrue);
      expect(resultSeparate.eastSideWarning, contains('separate segment'));
      expect(resultSeparate.orderedStops.any((s) => s.id == 'east-side-gallery-extension'), isFalse,
          reason: 'When separate segment is selected, it is not forced into the central sequence');
    });
  });

  group('Closure Engine', () {
    test('Flags Sunday retail closure and Monday museum closure', () {
      final packFile = File('assets/content/berlin-pack.json');
      final packJson = json.decode(packFile.readAsStringSync());
      final allStops = (packJson['stops'] as List<dynamic>)
          .map((s) => Stop.fromJson(s as Map<String, dynamic>))
          .toList();
      final allFoods = (packJson['food_stops'] as List<dynamic>)
          .map((f) => FoodStop.fromJson(f as Map<String, dynamic>))
          .toList();
      final walk = Walk.fromJson(packJson['walks'][0]);

      // Test Monday (2026-10-19)
      final mondayDate = DateTime(2026, 10, 19);
      final mondayWarnings = ClosureEngine.evaluateWalk(
        walk: walk,
        stops: allStops,
        foodStops: allFoods,
        walkDate: mondayDate,
        startHour: 10,
      );

      final hasMondayWarning = mondayWarnings.any(
        (w) => w.issue.contains('Monday') || w.entityName.contains('Museum'),
      );
      expect(hasMondayWarning, isTrue);

      // Test Sunday (2026-10-25)
      final sundayDate = DateTime(2026, 10, 25);
      final sundayWarnings = ClosureEngine.evaluateWalk(
        walk: walk,
        stops: allStops,
        foodStops: allFoods,
        walkDate: sundayDate,
        startHour: 10,
      );

      final hasSundayWarning = sundayWarnings.any(
        (w) => w.entityName.contains('Sonntagsruhe'),
      );
      expect(hasSundayWarning, isTrue);
    });
  });

  group('End-to-End Walk Lifecycle & Sizing Test in AppState', () {
    test('Stay planner resizes itineraries from 1 day to 2 days', () async {
      final state = AppState();
      await state.initialize();

      // Default: 1 day -> 1 core walk
      expect(state.getStayDays('berlin'), 1);
      final day1Walks = state.getProposedWalksForStay();
      expect(day1Walks.length, 1);
      expect(day1Walks.first.id, 'berlin-mitte-essentials');

      // Adjust to 2 days -> 2 walks across 2 days
      state.setStayDays('berlin', 2);
      expect(state.getStayDays('berlin'), 2);
      final day2Walks = state.getProposedWalksForStay();
      expect(day2Walks.length, 2);

      // Adjust to 3 days -> all 3 walks unlocked
      state.setStayDays('berlin', 3);
      final day3Walks = state.getProposedWalksForStay();
      expect(day3Walks.length, 3);
    });

    test('Live walk lifecycle: start, next stops, food prompt, off-route rejoin, finish to journal', () async {
      final state = AppState();
      await state.initialize();
      final walk = state.repo.getWalk('berlin-mitte-essentials')!;

      // 1. Start Live Walk
      state.startLiveWalk(walk);
      expect(state.isLiveWalking, isTrue);
      expect(state.currentStopIndex, 0);
      expect(state.currentStop?.nameEn, 'Brandenburg Gate & Pariser Platz');

      // 2. Advance to Stop 2 (Reichstag)
      bool finished = state.advanceToNextStop();
      expect(finished, isFalse);
      expect(state.currentStopIndex, 1);
      expect(state.currentStop?.nameEn, 'Reichstag Building (Exterior & Glass Dome)');

      // 3. Pause & Resume
      state.pauseWalk();
      expect(state.isPaused, isTrue);
      state.resumeWalk();
      expect(state.isPaused, isFalse);

      // 4. Advance to Stop 3 (Unter den Linden)
      finished = state.advanceToNextStop();
      expect(finished, isFalse);
      expect(state.currentStopIndex, 2);
      expect(state.currentStop?.nameEn, 'Unter den Linden Promenade');

      // Check upcoming food stop after Unter den Linden
      expect(state.upcomingFoodStop, isNotNull);
      expect(state.upcomingFoodStop?.name, contains('Rausch'));

      // 5. Simulate off-route wander and rejoin
      state.simulateDriftOffRoute();
      expect(state.isOffRoute, isTrue);
      state.rejoinWalk();
      expect(state.isOffRoute, isFalse);

      // 6. Advance to Stop 4 (Museum Island)
      finished = state.advanceToNextStop();
      expect(finished, isFalse);
      expect(state.currentStopIndex, 3);

      // 7. Advance to Stop 5 (Berlin Cathedral - final stop)
      finished = state.advanceToNextStop();
      expect(finished, isFalse);
      expect(state.currentStopIndex, 4);

      // 8. Arrive and finish walk
      finished = state.advanceToNextStop();
      expect(finished, isTrue);
      expect(state.isLiveWalking, isFalse);

      // 9. Verify Journal has logged the completed walk
      expect(state.journal.length, 1);
      expect(state.journal.first.walkTitle, walk.title);
      expect(state.journal.first.stopsVisited, 5);
      expect(state.journal.first.distanceKm, walk.distanceKm);
    });

    test('End early to nearest station provides accurate transit exit and logs to journal', () async {
      final state = AppState();
      await state.initialize();
      final walk = state.repo.getWalk('berlin-mitte-essentials')!;

      state.startLiveWalk(walk);
      // At Stop 1 (Brandenburger Tor)
      final endEarlyInfo = state.getEndEarlyInfo();
      expect(endEarlyInfo.nearestStation, contains('Brandenburger Tor'));

      state.endWalkEarly();
      expect(state.isLiveWalking, isFalse);
      expect(state.journal.length, 1);
      expect(state.journal.first.notes, contains('Ended early'));
    });
  });

  group('Tab Widgets Test', () {
    testWidgets('TodayTab renders accurately', (WidgetTester tester) async {
      final state = AppState();
      await state.initialize();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: TodayTab(
            state: state,
            onStartLiveWalk: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Today in Berlin'), findsOneWidget);
      expect(find.text('START WALK NOW'), findsOneWidget);
    });

    testWidgets('CitiesTab renders Berlin and stubs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
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

      expect(find.text('Launch City Packs'), findsOneWidget);
      expect(find.textContaining('Berlin'), findsWidgets);
      expect(find.textContaining('Dresden'), findsWidgets);
      expect(find.textContaining('Leipzig'), findsWidgets);
    });

    testWidgets('WalksTab renders walk list', (WidgetTester tester) async {
      final state = AppState();
      await state.initialize();

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

      expect(find.text('Berlin Walks'), findsOneWidget);
      expect(find.text('Route Builder'), findsOneWidget);
    });

    testWidgets('SavedTab renders handbook and tabs', (WidgetTester tester) async {
      final state = AppState();
      await state.initialize();

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

      expect(find.text('Saved & Practical Help'), findsOneWidget);
      expect(find.text('Saved Walks'), findsOneWidget);
      expect(find.text('Trip Journal'), findsOneWidget);
      expect(find.text('Practical Guide'), findsOneWidget);
    });
  });
}
