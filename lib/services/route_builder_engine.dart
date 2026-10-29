import 'dart:math';
import '../models/stop.dart';

enum EastSideGalleryOption {
  transitExtension, // 12-min U-Bahn / S-Bahn link to Warschauer Straße
  riversideWalkEast, // 45-min scenic pedestrian walk along Spree
  separateSegment, // Saved as an afternoon or Day 2 segment
}

class SuggestedAddition {
  final Stop stop;
  final String reason;

  SuggestedAddition({required this.stop, required this.reason});
}

class BuiltRouteResult {
  final List<Stop> orderedStops;
  final List<SuggestedAddition> availableSuggestions;
  final double totalDistanceKm;
  final int totalWalkingMinutes;
  final int totalDwellMinutes;
  final bool includesEastSideGallery;
  final EastSideGalleryOption? eastSideOption;
  final String? eastSideWarning;
  final bool exceedsSingleDay;
  final String daySizingRecommendation;

  BuiltRouteResult({
    required this.orderedStops,
    required this.availableSuggestions,
    required this.totalDistanceKm,
    required this.totalWalkingMinutes,
    required this.totalDwellMinutes,
    required this.includesEastSideGallery,
    this.eastSideOption,
    this.eastSideWarning,
    required this.exceedsSingleDay,
    required this.daySizingRecommendation,
  });

  int get totalMinutes => totalWalkingMinutes + totalDwellMinutes;
}

class RouteBuilderEngine {
  /// Confirmed Berlin anchors:
  /// 1. Brandenburg Gate
  /// 2. Reichstag
  /// 3. Unter den Linden
  /// 4. Checkpoint Charlie
  /// 5. Berlin Wall at the East Side Gallery
  static BuiltRouteResult buildRoute({
    required List<Stop> selectedAnchors,
    required List<Stop> allAvailableStops,
    required Set<String> acceptedSuggestionIds,
    required int stayDays,
    EastSideGalleryOption eastSideOption = EastSideGalleryOption.transitExtension,
  }) {
    // 1. Identify if East Side Gallery is selected
    final bool hasEastSide = selectedAnchors.any(
      (s) => s.id == 'east-side-gallery-extension',
    );

    // Filter central anchors (leave East Side Gallery for eastward finish)
    final List<Stop> centralStops = selectedAnchors.where((s) {
      if (s.id == 'east-side-gallery-extension') return false;
      return true;
    }).toList();

    // 2. Order central anchors to minimize backtracking (West-to-East historical line)
    final List<Stop> ordered = _orderMinimizingBacktrack(centralStops);

    // 3. Detect available suggestions between anchors (OFFERED, NEVER SILENTLY ADDED)
    final List<SuggestedAddition> availableSuggestions = [];

    final hasGate = ordered.any((s) => s.id == 'brandenburg-gate');
    final hasLinden = ordered.any((s) => s.id == 'unter-den-linden-promenade');
    final hasIslandSelected = ordered.any((s) => s.id == 'museum-island') ||
        acceptedSuggestionIds.contains('museum-island');

    if ((hasGate || hasLinden) && !hasIslandSelected) {
      final islandStop =
          allAvailableStops.where((s) => s.id == 'museum-island').firstOrNull;
      if (islandStop != null) {
        availableSuggestions.add(
          SuggestedAddition(
            stop: islandStop,
            reason:
                'Museum Island sits directly at the eastern foot of Unter den Linden.',
          ),
        );
      }
    }

    final hasCharlie = ordered.any((s) => s.id == 'checkpoint-charlie');
    final hasTerrorSelected = ordered.any((s) => s.id == 'topography-of-terror') ||
        acceptedSuggestionIds.contains('topography-of-terror');

    if (hasCharlie && !hasTerrorSelected) {
      final terrorStop = allAvailableStops
          .where((s) => s.id == 'topography-of-terror')
          .firstOrNull;
      if (terrorStop != null) {
        availableSuggestions.add(
          SuggestedAddition(
            stop: terrorStop,
            reason:
                'Topography of Terror is 500m west along the preserved Wall trench.',
          ),
        );
      }
    }

    // 4. Construct final sequence: only include explicitly accepted suggestions!
    final List<Stop> finalSequence = [];
    for (final stop in ordered) {
      finalSequence.add(stop);

      // If user explicitly accepted Museum Island and we just added Unter den Linden
      if (stop.id == 'unter-den-linden-promenade' &&
          acceptedSuggestionIds.contains('museum-island')) {
        final islandStop =
            allAvailableStops.where((s) => s.id == 'museum-island').firstOrNull;
        if (islandStop != null && !finalSequence.contains(islandStop)) {
          finalSequence.add(islandStop);
        }
      }

      // If user explicitly accepted Topography of Terror before Checkpoint Charlie
      if (stop.id == 'topography-of-terror' &&
          acceptedSuggestionIds.contains('topography-of-terror')) {
        // already added
      }
    }

    // If Topography was accepted and Charlie is present, insert before Charlie
    if (acceptedSuggestionIds.contains('topography-of-terror')) {
      final terrorStop = allAvailableStops
          .where((s) => s.id == 'topography-of-terror')
          .firstOrNull;
      if (terrorStop != null && !finalSequence.contains(terrorStop)) {
        final cIdx =
            finalSequence.indexWhere((s) => s.id == 'checkpoint-charlie');
        if (cIdx != -1) {
          finalSequence.insert(cIdx, terrorStop);
        } else {
          finalSequence.add(terrorStop);
        }
      }
    }

    // 5. Append East Side Gallery according to user's selected option
    String? eastSideWarning;
    if (hasEastSide) {
      final esgStop = selectedAnchors.firstWhere(
        (s) => s.id == 'east-side-gallery-extension',
      );

      switch (eastSideOption) {
        case EastSideGalleryOption.transitExtension:
          if (!finalSequence.contains(esgStop)) {
            finalSequence.add(esgStop);
          }
          eastSideWarning =
              'East Side Gallery is reached via a 12-minute transit link from Mitte (U-Bahn/S-Bahn to Warschauer Straße).';
          break;
        case EastSideGalleryOption.riversideWalkEast:
          if (!finalSequence.contains(esgStop)) {
            finalSequence.add(esgStop);
          }
          eastSideWarning =
              'Leg to East Side Gallery is 3.2 km (~45 mins walk). The Spree riverside promenade is scenic but adds significant distance.';
          break;
        case EastSideGalleryOption.separateSegment:
          eastSideWarning =
              'East Side Gallery is reserved as a separate segment (ideal for afternoon or Day 2 of your stay).';
          break;
      }
    }

    // 6. Calculate total distances and walking times
    double distKm = 0.0;
    int walkMins = 0;
    int dwellMins = 0;

    for (int i = 0; i < finalSequence.length; i++) {
      dwellMins += finalSequence[i].dwellTimeMinutes;
      if (i > 0) {
        final prev = finalSequence[i - 1];
        final curr = finalSequence[i];
        final d = _haversineDistanceKm(
          prev.latitude,
          prev.longitude,
          curr.latitude,
          curr.longitude,
        );
        distKm += d;
        walkMins += ((d / 4.2) * 60).round();
      }
    }

    final totalMins = walkMins + dwellMins;
    final bool exceedsSingleDay = totalMins > 270 && stayDays == 1; // > 4.5 hours
    String dayRec = 'Fits well within your 1-day itinerary.';
    if (exceedsSingleDay) {
      dayRec =
          'Total time (~${(totalMins / 60).toStringAsFixed(1)} hrs) is tight for 1 day. Recommend splitting across 2 days rather than rushing.';
    } else if (stayDays > 1) {
      dayRec =
          'Sized comfortably for your $stayDays-day stay in Berlin. Central sights on Day 1, extension on Day 2.';
    }

    return BuiltRouteResult(
      orderedStops: finalSequence,
      availableSuggestions: availableSuggestions,
      totalDistanceKm: distKm,
      totalWalkingMinutes: walkMins,
      totalDwellMinutes: dwellMins,
      includesEastSideGallery: hasEastSide,
      eastSideOption: eastSideOption,
      eastSideWarning: eastSideWarning,
      exceedsSingleDay: exceedsSingleDay,
      daySizingRecommendation: dayRec,
    );
  }

  static List<Stop> _orderMinimizingBacktrack(List<Stop> stops) {
    if (stops.length <= 2) return List.from(stops);

    final list = List<Stop>.from(stops);
    final startIndex = list.indexWhere(
      (s) => s.id == 'brandenburg-gate' || s.id == 'reichstag-exterior',
    );
    if (startIndex > 0) {
      final start = list.removeAt(startIndex);
      list.insert(0, start);
    }

    final ordered = <Stop>[list.removeAt(0)];

    while (list.isNotEmpty) {
      final current = ordered.last;
      int nearestIdx = 0;
      double nearestDist = double.infinity;

      for (int i = 0; i < list.length; i++) {
        final d = _haversineDistanceKm(
          current.latitude,
          current.longitude,
          list[i].latitude,
          list[i].longitude,
        );
        if (d < nearestDist) {
          nearestDist = d;
          nearestIdx = i;
        }
      }

      ordered.add(list.removeAt(nearestIdx));
    }

    return ordered;
  }

  static double _haversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }
}
