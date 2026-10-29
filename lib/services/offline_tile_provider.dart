import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Offline tile provider that loads bundled and downloaded city map tiles
/// completely offline, with zero network HTTP requests in airplane mode.
class OfflineTileProvider extends TileProvider {
  final String cityId;
  final String? localPackDirectory;
  final bool forceOfflineGrid;

  OfflineTileProvider({
    this.cityId = 'berlin',
    this.localPackDirectory,
    this.forceOfflineGrid = false,
  });

  /// Check whether tile coordinates are covered by the Berlin Mitte & Spree offline pack.
  static bool isWithinBerlinPack(int z, int x, int y) {
    if (z == 13) {
      return x >= 4400 && x <= 4402 && y >= 2686 && y <= 2687;
    } else if (z == 14) {
      return x >= 8800 && x <= 8804 && y >= 5372 && y <= 5374;
    } else if (z == 15) {
      return x >= 17600 && x <= 17608 && y >= 10745 && y <= 10749;
    } else if (z == 16) {
      return x >= 35201 && x <= 35217 && y >= 21490 && y <= 21499;
    }
    return false;
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final z = coordinates.z;
    final x = coordinates.x;
    final y = coordinates.y;
    final bool isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

    if (forceOfflineGrid) {
      if (isTest && File('assets/tiles/berlin/offline_tile.png').existsSync()) {
        return FileImage(File('assets/tiles/berlin/offline_tile.png'));
      }
      return const AssetImage('assets/tiles/berlin/offline_tile.png');
    }

    final bool inBounds = isWithinBerlinPack(z, x, y);

    if (inBounds) {
      // 1. Check if user downloaded pack to local storage
      if (!kIsWeb && localPackDirectory != null) {
        final filePath = '$localPackDirectory/tiles/$z/$x/$y.png';
        final file = File(filePath);
        if (file.existsSync()) {
          return FileImage(file);
        }
      }

      // 2. Bundled assets inside the pack bundle
      final assetPath = 'assets/tiles/$cityId/$z/$x/$y.png';
      if (isTest && File(assetPath).existsSync()) {
        return FileImage(File(assetPath));
      }
      return AssetImage(assetPath);
    }

    // 3. For coordinates outside the packaged city boundary, display offline grid canvas
    if (isTest && File('assets/tiles/berlin/offline_tile.png').existsSync()) {
      return FileImage(File('assets/tiles/berlin/offline_tile.png'));
    }
    return const AssetImage('assets/tiles/berlin/offline_tile.png');
  }
}
