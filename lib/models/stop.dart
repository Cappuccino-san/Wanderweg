class Stop {
  final String id;
  final String nameEn;
  final String nameDe;
  final bool isAnchor;
  final double latitude;
  final double longitude;
  final String category;
  final String whatAmILookingAt;
  final String whyItMatters;
  final String whatToNotice;
  final int dwellTimeMinutes;
  final String localTip;
  final String entryCostBand; // 'free', 'paid', 'free_to_view_outside'
  final String openingHours;
  final List<String> closingDays;
  final bool stepFreeAccess;
  final String stepFreeNotes;
  final String lastVerifiedDate;

  Stop({
    required this.id,
    required this.nameEn,
    required this.nameDe,
    required this.isAnchor,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.whatAmILookingAt,
    required this.whyItMatters,
    required this.whatToNotice,
    required this.dwellTimeMinutes,
    required this.localTip,
    required this.entryCostBand,
    required this.openingHours,
    required this.closingDays,
    required this.stepFreeAccess,
    required this.stepFreeNotes,
    required this.lastVerifiedDate,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as Map<String, dynamic>;
    return Stop(
      id: json['id'] as String,
      nameEn: json['name_en'] as String,
      nameDe: json['name_de'] as String,
      isAnchor: json['is_anchor'] as bool? ?? false,
      latitude: (coords['latitude'] as num).toDouble(),
      longitude: (coords['longitude'] as num).toDouble(),
      category: json['category'] as String,
      whatAmILookingAt: json['what_am_i_looking_at'] as String,
      whyItMatters: json['why_it_matters'] as String,
      whatToNotice: json['what_to_notice'] as String,
      dwellTimeMinutes: json['dwell_time_minutes'] as int? ?? 15,
      localTip: json['local_tip'] as String,
      entryCostBand: json['entry_cost_band'] as String? ?? 'free',
      openingHours: json['opening_hours'] as String? ?? 'Open daily',
      closingDays: (json['closing_days'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      stepFreeAccess: json['step_free_access'] as bool? ?? true,
      stepFreeNotes: json['step_free_notes'] as String? ?? '',
      lastVerifiedDate: json['last_verified_date'] as String? ?? '',
    );
  }

  String get costLabel {
    switch (entryCostBand) {
      case 'free':
        return 'Free entry';
      case 'paid':
        return 'Paid entry (no in-app booking)';
      case 'free_to_view_outside':
        return 'Free exterior view';
      default:
        return 'Free';
    }
  }
}

