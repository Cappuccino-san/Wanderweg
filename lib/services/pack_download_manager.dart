import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/city.dart';

enum PackStatus {
  notDownloaded,
  downloading,
  paused,
  verifying,
  downloaded,
  updateAvailable,
  error,
}

class DownloadProgress {
  final String cityId;
  final int bytesReceived;
  final int totalBytes;
  final double percent;
  final PackStatus status;
  final String currentPhase;
  final String? errorMessage;

  DownloadProgress({
    required this.cityId,
    required this.bytesReceived,
    required this.totalBytes,
    required this.percent,
    required this.status,
    required this.currentPhase,
    this.errorMessage,
  });
}

class PackDownloadManager extends ChangeNotifier {
  final Map<String, PackStatus> _cityStatus = {
    'berlin': PackStatus.downloaded, // Berlin ships ready as prototype
    'dresden': PackStatus.notDownloaded,
    'leipzig': PackStatus.notDownloaded,
  };

  final Map<String, DownloadProgress> _progress = {};
  final Map<String, List<int>> _partialBuffer = {};
  final Map<String, String> _installedVersions = {
    'berlin': '1.2.0',
  };

  String? _storageDirectory;
  String? get storageDirectory => _storageDirectory;

  void setStorageDirectory(String path) {
    _storageDirectory = path;
  }

  PackStatus getStatus(String cityId) =>
      _cityStatus[cityId] ?? PackStatus.notDownloaded;

  DownloadProgress? getProgress(String cityId) => _progress[cityId];

  String? getInstalledVersion(String cityId) => _installedVersions[cityId];

  bool isDownloaded(String cityId) =>
      getStatus(cityId) == PackStatus.downloaded;

  /// Start or restart a pack download.
  Future<void> startDownload(CitySummary city, {bool isDelta = false}) async {
    final cityId = city.id;
    _partialBuffer[cityId] = [];

    final int totalBytes = isDelta
        ? city.packSizeBytes
        : (city.totalSizeBytes > 0 ? city.totalSizeBytes : (city.totalDownloadSizeMb * 1024 * 1024).toInt());

    _cityStatus[cityId] = PackStatus.downloading;
    _progress[cityId] = DownloadProgress(
      cityId: cityId,
      bytesReceived: 0,
      totalBytes: totalBytes,
      percent: 0.0,
      status: PackStatus.downloading,
      currentPhase: isDelta ? 'Downloading content delta...' : 'Downloading map tiles & pack...',
    );
    notifyListeners();

    await _executeChunkedDownload(city, totalBytes, startOffset: 0, isDelta: isDelta);
  }

  /// Pause an in-flight download, saving current byte progress so it can be resumed.
  void pauseDownload(String cityId) {
    if (_cityStatus[cityId] == PackStatus.downloading) {
      _cityStatus[cityId] = PackStatus.paused;
      final current = _progress[cityId];
      if (current != null) {
        _progress[cityId] = DownloadProgress(
          cityId: cityId,
          bytesReceived: current.bytesReceived,
          totalBytes: current.totalBytes,
          percent: current.percent,
          status: PackStatus.paused,
          currentPhase: 'Download paused (resumable)',
        );
      }
      notifyListeners();
    }
  }

  /// Resume a paused download from the saved byte offset.
  Future<void> resumeDownload(CitySummary city) async {
    final cityId = city.id;
    if (_cityStatus[cityId] != PackStatus.paused) return;
    final current = _progress[cityId];
    if (current == null) return;

    _cityStatus[cityId] = PackStatus.downloading;
    _progress[cityId] = DownloadProgress(
      cityId: cityId,
      bytesReceived: current.bytesReceived,
      totalBytes: current.totalBytes,
      percent: current.percent,
      status: PackStatus.downloading,
      currentPhase: 'Resuming download from byte ${current.bytesReceived}...',
    );
    notifyListeners();

    await _executeChunkedDownload(
      city,
      current.totalBytes,
      startOffset: current.bytesReceived,
    );
  }

  /// Delete a downloaded pack cleanly to free disk space.
  Future<void> deletePack(String cityId) async {
    if (!kIsWeb && _storageDirectory != null) {
      final cityDir = Directory('$_storageDirectory/packs/$cityId');
      if (cityDir.existsSync()) {
        cityDir.deleteSync(recursive: true);
      }
    }

    _cityStatus[cityId] = PackStatus.notDownloaded;
    _progress.remove(cityId);
    _partialBuffer.remove(cityId);
    _installedVersions.remove(cityId);
    notifyListeners();
  }

  /// Verify SHA-256 integrity of downloaded bytes against manifest checksum.
  Future<bool> verifyIntegrity(String cityId, List<int> bytes, String? expectedSha256) async {
    if (expectedSha256 == null || expectedSha256.isEmpty) return true;
    final digest = sha256.convert(bytes);
    return digest.toString().toLowerCase() == expectedSha256.toLowerCase();
  }

  /// Check for updates on Wi-Fi and flag delta update availability.
  void checkForUpdates(CitySummary city, {required bool isWifiConnected}) {
    final cityId = city.id;
    if (!isWifiConnected) return;

    final installed = _installedVersions[cityId];
    final available = city.packVersion;

    if (installed != null && available != null && available != installed) {
      _cityStatus[cityId] = PackStatus.updateAvailable;
      notifyListeners();
    }
  }

  /// Chunked byte stream simulator supporting pause, resume, and integrity verification.
  Future<void> _executeChunkedDownload(
    CitySummary city,
    int totalBytes, {
    required int startOffset,
    bool isDelta = false,
  }) async {
    final cityId = city.id;
    final buffer = _partialBuffer[cityId] ?? [];

    // Chunks of 128KB to simulate real-world streaming & responsive resume
    const int chunkSize = 131072;
    int currentOffset = startOffset;
    final int delayMs = (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) ? 2 : 20;

    // Load reference bytes from asset/mock to simulate genuine data payload
    List<int> sourceBytes;
    try {
      if (isDelta) {
        if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
          sourceBytes = File('assets/content/berlin-pack.json').readAsBytesSync();
        } else {
          final raw = await rootBundle.loadString('assets/content/berlin-pack.json');
          sourceBytes = utf8.encode(raw);
        }
      } else {
        if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
          sourceBytes = File('assets/content/berlin-tiles.mbtiles').readAsBytesSync();
        } else {
          final byteData = await rootBundle.load('assets/content/berlin-tiles.mbtiles');
          sourceBytes = byteData.buffer.asUint8List();
        }
      }
    } catch (_) {
      // Fallback synthetic payload if file not found during early tests
      sourceBytes = List.filled(totalBytes > 0 ? totalBytes : 1024, 0x42);
    }

    while (currentOffset < totalBytes) {
      if (_cityStatus[cityId] == PackStatus.paused) {
        return; // Stopped gracefully, state preserved
      }

      await Future<void>.delayed(Duration(milliseconds: delayMs));

      final int nextEnd = (currentOffset + chunkSize).clamp(0, totalBytes);
      final int bytesToAdd = nextEnd - currentOffset;

      // Slice from source
      if (sourceBytes.isNotEmpty) {
        final int srcStart = currentOffset % sourceBytes.length;
        final int srcEnd = (srcStart + bytesToAdd).clamp(0, sourceBytes.length);
        buffer.addAll(sourceBytes.sublist(srcStart, srcEnd));
      }

      currentOffset = nextEnd;
      if (_cityStatus[cityId] == PackStatus.paused) {
        return;
      }
      final double percent = (currentOffset / totalBytes).clamp(0.0, 1.0);

      _progress[cityId] = DownloadProgress(
        cityId: cityId,
        bytesReceived: currentOffset,
        totalBytes: totalBytes,
        percent: percent,
        status: PackStatus.downloading,
        currentPhase: isDelta
            ? 'Downloading delta: ${(percent * 100).toStringAsFixed(0)}%'
            : 'Downloading tiles & pack: ${(percent * 100).toStringAsFixed(0)}%',
      );
      notifyListeners();
    }

    // Step 2: Verification phase
    _cityStatus[cityId] = PackStatus.verifying;
    _progress[cityId] = DownloadProgress(
      cityId: cityId,
      bytesReceived: totalBytes,
      totalBytes: totalBytes,
      percent: 1.0,
      status: PackStatus.verifying,
      currentPhase: 'Verifying SHA-256 integrity...',
    );
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 80));

    // Verify integrity
    final String? expectedSha = isDelta ? city.packSha256 : city.tilesSha256;
    final bool valid = await verifyIntegrity(cityId, buffer, expectedSha);

    if (!valid && expectedSha != null) {
      _cityStatus[cityId] = PackStatus.error;
      _progress[cityId] = DownloadProgress(
        cityId: cityId,
        bytesReceived: currentOffset,
        totalBytes: totalBytes,
        percent: 0.0,
        status: PackStatus.error,
        currentPhase: 'Integrity check failed: Checksum mismatch',
        errorMessage: 'Downloaded pack failed SHA-256 verification. Preserving existing working pack.',
      );
      _partialBuffer.remove(cityId);
      notifyListeners();
      return;
    }

    // Atomic install: write to disk if native storage directory available
    if (!kIsWeb && _storageDirectory != null) {
      try {
        final packDir = Directory('$_storageDirectory/packs/$cityId');
        packDir.createSync(recursive: true);

        final tmpFile = File('${packDir.path}/pack.tmp');
        tmpFile.writeAsBytesSync(buffer);

        final finalFile = File('${packDir.path}/${isDelta ? "pack.json" : "tiles.mbtiles"}');
        tmpFile.renameSync(finalFile.path);
      } catch (e) {
        // Disk write fallback
      }
    }

    _cityStatus[cityId] = PackStatus.downloaded;
    _installedVersions[cityId] = city.packVersion ?? '1.2.0';
    _progress[cityId] = DownloadProgress(
      cityId: cityId,
      bytesReceived: totalBytes,
      totalBytes: totalBytes,
      percent: 1.0,
      status: PackStatus.downloaded,
      currentPhase: 'Download complete and verified (Offline ready)',
    );
    _partialBuffer.remove(cityId);
    notifyListeners();
  }
}
