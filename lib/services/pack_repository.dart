import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../models/city.dart';
import '../models/food_stop.dart';
import '../models/practical_note.dart';
import '../models/route_leg.dart';
import '../models/stop.dart';
import '../models/walk.dart';

class PackRepository {
  List<Country> _countries = [];
  List<CitySummary> _cities = [];
  final Map<String, CityPackMeta> _cityMetas = {};
  List<Walk> _walks = [];
  final Map<String, Stop> _stopMap = {};
  final Map<String, FoodStop> _foodMap = {};
  final List<RouteLeg> _legs = [];
  List<PracticalNote> _practicalNotes = [];

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  List<Country> get countries => _countries;
  List<CitySummary> get cities => _cities;
  CityPackMeta? get berlinMeta => _cityMetas['berlin'];
  List<Walk> get walks => _walks;
  List<Stop> get stops => _stopMap.values.toList();
  List<FoodStop> get foodStops => _foodMap.values.toList();
  List<RouteLeg> get routeLegs => _legs;
  List<PracticalNote> get practicalNotes => _practicalNotes;

  CityPackMeta? getCityMeta(String cityId) => _cityMetas[cityId];

  CitySummary? getCitySummary(String cityId) {
    try {
      return _cities.firstWhere((c) => c.id == cityId);
    } catch (_) {
      return null;
    }
  }

  List<Walk> getWalksForCity(String cityId) {
    return _walks.where((w) => w.cityId == cityId).toList();
  }

  Future<void> init({String? manifestOverride, String? berlinPackOverride}) async {
    try {
      String manifestRaw;

      if (manifestOverride != null) {
        manifestRaw = manifestOverride;
      } else if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
        manifestRaw = File('assets/content/city-manifest.json').readAsStringSync();
      } else {
        manifestRaw =
            await rootBundle.loadString('assets/content/city-manifest.json');
      }

      // 1. Load city manifest
      final manifestJson = json.decode(manifestRaw) as Map<String, dynamic>;

      if (manifestJson.containsKey('countries')) {
        _countries = (manifestJson['countries'] as List<dynamic>)
            .map((c) => Country.fromJson(c as Map<String, dynamic>))
            .toList();
      }

      if (manifestJson.containsKey('cities')) {
        final citiesList = (manifestJson['cities'] as List<dynamic>)
            .map((c) => CitySummary.fromJson(c as Map<String, dynamic>))
            .toList();
        _cities = citiesList;
      } else if (_countries.isNotEmpty) {
        _cities = _countries.expand((c) => c.cities).toList();
      }

      // Clear existing state before loading packs
      _cityMetas.clear();
      _practicalNotes = [];
      _stopMap.clear();
      _foodMap.clear();
      _legs.clear();
      _walks = [];

      // Helper to read asset content safely across web, test, and release
      Future<String?> readAssetContent(String assetPath) async {
        try {
          if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
            final file = File(assetPath);
            if (file.existsSync()) {
              return file.readAsStringSync();
            }
          }
          return await rootBundle.loadString(assetPath);
        } catch (e) {
          return null;
        }
      }

      // 2. Load all available city packs (Berlin, Dresden, Leipzig, etc.)
      for (final city in _cities) {
        if (city.packFile == null) continue;

        String? packRaw;
        if (city.id == 'berlin' && berlinPackOverride != null) {
          packRaw = berlinPackOverride;
        } else {
          final path = 'assets/${city.packFile}';
          packRaw = await readAssetContent(path);
        }

        if (packRaw == null) continue;

        try {
          final packJson = json.decode(packRaw) as Map<String, dynamic>;

          if (packJson.containsKey('city')) {
            final meta = CityPackMeta.fromJson(packJson['city'] as Map<String, dynamic>);
            _cityMetas[city.id] = meta;
          }

          // Practical notes
          if (packJson.containsKey('practical_notes')) {
            final notes = (packJson['practical_notes'] as List<dynamic>)
                .map((p) => PracticalNote.fromJson(p as Map<String, dynamic>))
                .toList();
            _practicalNotes.addAll(notes);
          }

          // Stops
          if (packJson.containsKey('stops')) {
            for (final s in (packJson['stops'] as List<dynamic>)) {
              final stop = Stop.fromJson(s as Map<String, dynamic>);
              _stopMap[stop.id] = stop;
            }
          }

          // Food Stops
          if (packJson.containsKey('food_stops')) {
            for (final f in (packJson['food_stops'] as List<dynamic>)) {
              final food = FoodStop.fromJson(f as Map<String, dynamic>);
              _foodMap[food.id] = food;
            }
          }

          // Route Legs
          if (packJson.containsKey('route_legs')) {
            for (final l in (packJson['route_legs'] as List<dynamic>)) {
              _legs.add(RouteLeg.fromJson(l as Map<String, dynamic>));
            }
          }

          // Walks
          if (packJson.containsKey('walks')) {
            final cityWalks = (packJson['walks'] as List<dynamic>)
                .map((w) => Walk.fromJson(w as Map<String, dynamic>))
                .toList();
            _walks.addAll(cityWalks);
          }
        } catch (e) {
          // ignore: avoid_print
          print('Warning: Failed to parse pack for ${city.id}: $e');
        }
      }

      _isLoaded = true;
    } catch (e, stack) {
      // ignore: avoid_print
      print('Error loading pack repository: $e\n$stack');
    }
  }

  Stop? getStop(String id) => _stopMap[id];
  FoodStop? getFoodStop(String id) => _foodMap[id];
  Walk? getWalk(String id) {
    try {
      return _walks.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  RouteLeg? getLeg(String fromId, String toId) {
    try {
      return _legs.firstWhere(
        (l) => l.fromStopId == fromId && l.toStopId == toId,
      );
    } catch (_) {
      return null;
    }
  }

  List<LatLng> getWalkPathCoordinates(Walk walk) {
    final List<LatLng> fullPath = [];
    for (int i = 0; i < walk.stops.length - 1; i++) {
      final fromId = walk.stops[i];
      final toId = walk.stops[i + 1];
      final leg = getLeg(fromId, toId);
      if (leg != null && leg.pathCoordinates.isNotEmpty) {
        if (fullPath.isNotEmpty && fullPath.last == leg.pathCoordinates.first) {
          fullPath.addAll(leg.pathCoordinates.skip(1));
        } else {
          fullPath.addAll(leg.pathCoordinates);
        }
      } else {
        final s1 = getStop(fromId);
        final s2 = getStop(toId);
        if (s1 != null && s2 != null) {
          if (fullPath.isEmpty) fullPath.add(LatLng(s1.latitude, s1.longitude));
          fullPath.add(LatLng(s2.latitude, s2.longitude));
        }
      }
    }
    return fullPath;
  }
}
