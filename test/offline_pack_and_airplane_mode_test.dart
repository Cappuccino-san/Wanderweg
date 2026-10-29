import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderweg/models/city.dart';
import 'package:wanderweg/services/offline_tile_provider.dart';
import 'package:wanderweg/services/pack_download_manager.dart';
import 'package:wanderweg/state/app_state.dart';
import 'package:wanderweg/ui/tabs/cities_tab.dart';
import 'package:wanderweg/ui/tabs/map_tab.dart';
import 'package:wanderweg/ui/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Tile Packaging & MBTiles Specification Gate', () {
    test('berlin-tiles.mbtiles exists, is packaged, and matches manifest checksum', () {
      final mbtilesFile = File('assets/content/berlin-tiles.mbtiles');
      expect(mbtilesFile.existsSync(), isTrue,
          reason: 'Berlin offline tiles MBTiles archive must exist in assets/content/');

      final sizeBytes = mbtilesFile.lengthSync();
      expect(sizeBytes, greaterThan(1024 * 1024),
          reason: 'MBTiles file should contain actual map tile database');

      // Verify manifest entry
      final manifestFile = File('assets/content/city-manifest.json');
      final manifest = json.decode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final cities = (manifest['cities'] as List<dynamic>)
          .map((c) => CitySummary.fromJson(c as Map<String, dynamic>))
          .toList();

      final berlin = cities.firstWhere((c) => c.id == 'berlin');
      expect(berlin.tilesFile, 'content/berlin-tiles.mbtiles');
      expect(berlin.tilesSizeBytes, sizeBytes);
      expect(berlin.tilesSha256, isNotNull);
      expect(berlin.tilesSha256!.length, 64);

      // Verify honest formatted size
      expect(berlin.formattedSize, contains('MB'));
      expect(berlin.totalDownloadSizeMb, closeTo(7.04, 0.1));
    });

    test('Manifest supports per-country and per-city hierarchy for expansion readiness', () {
      final manifestFile = File('assets/content/city-manifest.json');
      final manifest = json.decode(manifestFile.readAsStringSync()) as Map<String, dynamic>;

      expect(manifest.containsKey('countries'), isTrue);
      final countries = (manifest['countries'] as List<dynamic>)
          .map((c) => Country.fromJson(c as Map<String, dynamic>))
          .toList();

      expect(countries.isNotEmpty, isTrue);
      final germany = countries.firstWhere((c) => c.id == 'de');
      expect(germany.nameEn, 'Germany');
      expect(germany.currency, 'EUR');
      expect(germany.transitTypes, containsAll(['S-Bahn', 'U-Bahn', 'Tram', 'Bus']));

      // Germany contains Berlin, Dresden, and Leipzig
      final cityIds = germany.cities.map((c) => c.id).toList();
      expect(cityIds, containsAll(['berlin', 'dresden', 'leipzig']));

      final berlin = germany.cities.firstWhere((c) => c.id == 'berlin');
      expect(berlin.isPrototype, isTrue);
      expect(berlin.anchorsConfirmed.length, 5);

      final dresden = germany.cities.firstWhere((c) => c.id == 'dresden');
      expect(dresden.status, 'demo');
      expect(dresden.anchorsConfirmed, contains('Frauenkirche'));

      final leipzig = germany.cities.firstWhere((c) => c.id == 'leipzig');
      expect(leipzig.status, 'demo');
      expect(leipzig.anchorsConfirmed, contains('Nikolaikirche'));
    });

    test('OfflineTileProvider covers all key Berlin walk anchors with packaged tiles', () {
      // Brandenburg Gate: lat 52.516275, lon 13.377704
      // Zoom 14: x=8800, y=5373
      expect(OfflineTileProvider.isWithinBerlinPack(14, 8800, 5373), isTrue);

      // Museum Island: lat 52.520556, lon 13.397778
      // Zoom 14: x=8801, y=5372
      expect(OfflineTileProvider.isWithinBerlinPack(14, 8801, 5372), isTrue);

      // Checkpoint Charlie: lat 52.507443, lon 13.390391
      // Zoom 14: x=8801, y=5374
      expect(OfflineTileProvider.isWithinBerlinPack(14, 8801, 5374), isTrue);

      // East Side Gallery: lat 52.505000, lon 13.444000
      // Zoom 14: x=8803, y=5374
      expect(OfflineTileProvider.isWithinBerlinPack(14, 8803, 5374), isTrue);

      // Zoom 15 check
      expect(OfflineTileProvider.isWithinBerlinPack(15, 17602, 10747), isTrue);

      // Out of bounds check: Paris / London coordinates are outside Berlin pack
      expect(OfflineTileProvider.isWithinBerlinPack(14, 8300, 5600), isFalse);
    });
  });

  group('PackDownloadManager: Resumability, Integrity & Clean Delete', () {
    test('Resumable chunked download can pause, retain offset, and resume to completion', () async {
      final manager = PackDownloadManager();

      final city = CitySummary(
        id: 'test_city',
        nameEn: 'Test City',
        nameDe: 'Teststadt',
        status: 'ready',
        isPrototype: false,
        packSizeBytes: 1024,
        tilesSizeBytes: 3000000, // 3 MB: ~45 chunks of 64KB
        totalDownloadSizeMb: 3.0,
        stayDaysDefault: 1,
        stayDaysUser: 1,
        stayDaysAdjustable: true,
        anchorsConfirmed: [],
        notes: '',
      );

      // 1. Initially not downloaded
      expect(manager.getStatus('test_city'), PackStatus.notDownloaded);

      // 2. Start download in background
      final downloadFuture = manager.startDownload(city);

      // Wait briefly for download to advance through a few chunks
      await Future<void>.delayed(const Duration(milliseconds: 10));
      manager.pauseDownload('test_city');
      await downloadFuture;

      expect(manager.getStatus('test_city'), PackStatus.paused);
      final pausedProgress = manager.getProgress('test_city');
      expect(pausedProgress, isNotNull);
      expect(pausedProgress!.bytesReceived, greaterThan(0));
      expect(pausedProgress.percent, lessThan(1.0));

      // 3. Resume download from saved byte offset
      final resumeFuture = manager.resumeDownload(city);
      await resumeFuture;

      expect(manager.getStatus('test_city'), PackStatus.downloaded);
      final finalProgress = manager.getProgress('test_city');
      expect(finalProgress!.percent, 1.0);
      expect(finalProgress.bytesReceived, finalProgress.totalBytes);
    });

    test('Integrity verification rejects corrupted checksum without corrupting pack', () async {
      final manager = PackDownloadManager();

      const expectedSha256 = '3eb79309b14e6f9de1bbee60e7d21b48be836b5d6e64e18f898994da14c0d0d2';
      final corruptBytes = [1, 2, 3, 4, 99];

      final isValidCorrupt = await manager.verifyIntegrity('berlin', corruptBytes, expectedSha256);
      expect(isValidCorrupt, isFalse, reason: 'Corrupt bytes must fail checksum verification');
    });

    test('Clean deletion frees pack status cleanly', () async {
      final manager = PackDownloadManager();
      expect(manager.isDownloaded('berlin'), isTrue);

      await manager.deletePack('berlin');
      expect(manager.isDownloaded('berlin'), isFalse);
      expect(manager.getStatus('berlin'), PackStatus.notDownloaded);
      expect(manager.getProgress('berlin'), isNull);
    });
  });

  group('Airplane Mode Release Gate: Complete Walk Execution', () {
    test('A downloaded Berlin pack completes a full walk in airplane mode with 0 degraded features', () async {
      final state = AppState();
      await state.initialize();

      // Enable Airplane Mode: turns off all cellular & Wi-Fi data
      state.setAirplaneMode(true);
      expect(state.isAirplaneMode, isTrue);
      expect(state.isWifiConnected, isFalse);

      // 1. Map & Route Lines work offline
      final walk = state.selectedWalk;
      expect(walk, isNotNull);
      expect(walk!.id, 'berlin-mitte-essentials');

      final polylinePoints = state.repo.getWalkPathCoordinates(walk);
      expect(polylinePoints.length, greaterThan(15),
          reason: 'Pedestrian geometry follows actual streets and footpaths');

      // 2. Stop Cards answer all 5 questions offline
      for (final stopId in walk.stops) {
        final stop = state.repo.getStop(stopId);
        expect(stop, isNotNull);
        expect(stop!.whatAmILookingAt.isNotEmpty, isTrue);
        expect(stop.whyItMatters.isNotEmpty, isTrue);
        expect(stop.whatToNotice.isNotEmpty, isTrue);
        expect(stop.dwellTimeMinutes, greaterThan(0));
        expect(stop.localTip.isNotEmpty, isTrue);
        expect(stop.entryCostBand.isNotEmpty, isTrue);
      }

      // 3. Food positions work offline with dietary and payment flags
      expect(walk.foodPositions.isNotEmpty, isTrue);
      final foodStop = state.repo.getFoodStop(walk.foodPositions.first.foodStopId);
      expect(foodStop, isNotNull);
      expect(foodStop!.cuisine.isNotEmpty, isTrue);
      expect(foodStop.priceBand.isNotEmpty, isTrue);
      expect(foodStop.goodInRain, isTrue);
      expect(foodStop.goodWithTiredFeet, isTrue);

      // 4. Full Live Walk Mode in Airplane Mode: Start, Next stops, Dwell, End early, Journal
      state.startLiveWalk(walk);
      expect(state.isLiveWalking, isTrue);
      expect(state.currentStopIndex, 0);
      expect(state.currentStop?.nameEn, contains('Brandenburg Gate'));

      // Next leg
      state.advanceToNextStop();
      expect(state.currentStopIndex, 1);
      expect(state.currentStop?.nameEn, contains('Reichstag'));
      expect(state.completedStopIds.contains('brandenburg-gate'), isTrue);

      // Test End Early to Nearest Station in Airplane Mode
      final endEarly = state.getEndEarlyInfo();
      expect(endEarly.nearestStation.isNotEmpty, isTrue);
      expect(endEarly.directions.isNotEmpty, isTrue);

      // Advance remaining stops
      state.advanceToNextStop(); // Stop 2
      state.advanceToNextStop(); // Stop 3
      state.advanceToNextStop(); // Stop 4

      // Finish walk in airplane mode
      state.finishWalk();
      expect(state.isLiveWalking, isFalse);

      // 5. Trip journal logs locally on device in Airplane Mode
      expect(state.journal.length, 1);
      final entry = state.journal.first;
      expect(entry.walkId, 'berlin-mitte-essentials');
      expect(entry.stopsVisited, greaterThanOrEqualTo(4));
      expect(entry.distanceKm, closeTo(3.4, 0.5));
    });

    testWidgets('MapTab and CitiesTab render cleanly in Airplane Mode', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      await state.initialize();
      state.setAirplaneMode(true);

      // Render MapTab in Airplane Mode with offline tiles
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MapTab(
            state: state,
            enableTileNetwork: false, // Strict offline test
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('AIRPLANE MODE'), findsOneWidget);
      expect(find.text('START LIVE WALK'), findsOneWidget);

      // Render CitiesTab in Airplane Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CitiesTab(state: state),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Airplane Mode ON'), findsOneWidget);
      expect(find.text('Berlin (Berlin)'), findsWidgets);
      expect(find.text('PACK VERIFIED'), findsWidgets);
      expect(find.textContaining('Honest Size:'), findsWidgets);
    });
  });
}
