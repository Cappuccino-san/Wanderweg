class Country {
  final String id;
  final String nameEn;
  final String nameDe;
  final String currency;
  final String holidayCalendar;
  final List<String> transitTypes;
  final List<CitySummary> cities;

  Country({
    required this.id,
    required this.nameEn,
    required this.nameDe,
    required this.currency,
    required this.holidayCalendar,
    required this.transitTypes,
    required this.cities,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    final citiesList = (json['cities'] as List<dynamic>?)
            ?.map((c) => CitySummary.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];

    return Country(
      id: json['id'] as String,
      nameEn: json['name_en'] as String,
      nameDe: json['name_de'] as String,
      currency: json['currency'] as String? ?? 'EUR',
      holidayCalendar: json['holiday_calendar'] as String? ?? 'de-DE',
      transitTypes: (json['transit_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['S-Bahn', 'U-Bahn', 'Tram', 'Bus'],
      cities: citiesList,
    );
  }
}

class CitySummary {
  final String id;
  final String nameEn;
  final String nameDe;
  final String countryId;
  final String status;
  final bool isPrototype;
  final bool isOfflineVerified;
  final String? packVersion;
  final String? packFile;
  final String? tilesFile;
  final int packSizeBytes;
  final int tilesSizeBytes;
  final double totalDownloadSizeMb;
  final double downloadSizeMb; // Backward compatibility
  final String? packSha256;
  final String? tilesSha256;
  final int stayDaysDefault;
  final int stayDaysUser;
  final bool stayDaysAdjustable;
  final List<String> anchorsConfirmed;
  final String notes;

  CitySummary({
    required this.id,
    required this.nameEn,
    required this.nameDe,
    this.countryId = 'de',
    required this.status,
    required this.isPrototype,
    this.isOfflineVerified = false,
    this.packVersion,
    this.packFile,
    this.tilesFile,
    this.packSizeBytes = 0,
    this.tilesSizeBytes = 0,
    required this.totalDownloadSizeMb,
    double? downloadSizeMb,
    this.packSha256,
    this.tilesSha256,
    required this.stayDaysDefault,
    required this.stayDaysUser,
    required this.stayDaysAdjustable,
    required this.anchorsConfirmed,
    required this.notes,
  }) : downloadSizeMb = downloadSizeMb ?? totalDownloadSizeMb;

  int get totalSizeBytes => packSizeBytes + tilesSizeBytes;

  bool get hasOfflineTiles => tilesFile != null && tilesSizeBytes > 0;

  String get formattedSize {
    if (totalSizeBytes > 0) {
      if (totalSizeBytes < 1024 * 1024) {
        return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
      }
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${totalDownloadSizeMb.toStringAsFixed(1)} MB';
  }

  factory CitySummary.fromJson(Map<String, dynamic> json) {
    final packSize = json['pack_size_bytes'] as int? ?? 0;
    final tilesSize = json['tiles_size_bytes'] as int? ?? 0;
    final totalMb = json['total_download_size_mb'] != null
        ? (json['total_download_size_mb'] as num).toDouble()
        : (json['download_size_mb'] as num?)?.toDouble() ?? 0.0;

    return CitySummary(
      id: json['id'] as String,
      nameEn: json['name_en'] as String,
      nameDe: json['name_de'] as String,
      countryId: json['country_id'] as String? ?? 'de',
      status: json['status'] as String,
      isPrototype: json['is_prototype'] as bool? ?? false,
      isOfflineVerified: json['is_offline_verified'] as bool? ?? (json['id'] == 'berlin'),
      packVersion: json['pack_version'] as String?,
      packFile: json['pack_file'] as String?,
      tilesFile: json['tiles_file'] as String?,
      packSizeBytes: packSize,
      tilesSizeBytes: tilesSize,
      totalDownloadSizeMb: totalMb,
      downloadSizeMb: totalMb,
      packSha256: json['pack_sha256'] as String?,
      tilesSha256: json['tiles_sha256'] as String?,
      stayDaysDefault: json['stay_days_default'] as int? ?? 1,
      stayDaysUser: json['stay_days_user'] as int? ?? 1,
      stayDaysAdjustable: json['stay_days_adjustable'] as bool? ?? true,
      anchorsConfirmed: (json['anchors_confirmed'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      notes: json['notes'] as String? ?? '',
    );
  }
}

class CityPackMeta {
  final String id;
  final String nameEn;
  final String nameDe;
  final String country;
  final double latitude;
  final double longitude;
  final String timezone;
  final String packVersion;
  final double downloadSizeMb;
  final String lastVerifiedDate;
  final int stayDaysDefault;
  final int stayDaysUser;
  final bool stayDaysAdjustable;
  final String status;
  final String transitSummary;
  final List<String> anchorsConfirmed;

  CityPackMeta({
    required this.id,
    required this.nameEn,
    required this.nameDe,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.packVersion,
    required this.downloadSizeMb,
    required this.lastVerifiedDate,
    required this.stayDaysDefault,
    required this.stayDaysUser,
    required this.stayDaysAdjustable,
    required this.status,
    required this.transitSummary,
    required this.anchorsConfirmed,
  });

  factory CityPackMeta.fromJson(Map<String, dynamic> json) {
    final coords = json['center_coordinates'] as Map<String, dynamic>;
    return CityPackMeta(
      id: json['id'] as String,
      nameEn: json['name_en'] as String,
      nameDe: json['name_de'] as String,
      country: json['country'] as String,
      latitude: (coords['latitude'] as num).toDouble(),
      longitude: (coords['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String,
      packVersion: json['pack_version'] as String,
      downloadSizeMb: (json['download_size_mb'] as num).toDouble(),
      lastVerifiedDate: json['last_verified_date'] as String,
      stayDaysDefault: json['stay_days_default'] as int? ?? 1,
      stayDaysUser: json['stay_days_user'] as int? ?? 1,
      stayDaysAdjustable: json['stay_days_adjustable'] as bool? ?? true,
      status: json['status'] as String? ?? 'ready',
      transitSummary: json['transit_summary'] as String? ?? '',
      anchorsConfirmed: (json['anchors_confirmed'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
