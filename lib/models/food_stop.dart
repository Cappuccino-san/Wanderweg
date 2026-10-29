class FoodStop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String type; // cafe, traditional_restaurant, quick_bite, market_hall
  final String cuisine;
  final String priceBand; // '€', '€€', '€€€'
  final String signatureOrder;
  final String openingHours;
  final List<String> closingDays;
  final bool cashOnly;
  final bool cardsAccepted;
  final bool closedSundays;
  final bool kitchenClosesEarly;
  final bool goodInRain;
  final bool goodWithTiredFeet;
  final List<String> dietaryFlags;
  final String lastVerifiedDate;

  FoodStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.cuisine,
    required this.priceBand,
    required this.signatureOrder,
    required this.openingHours,
    required this.closingDays,
    required this.cashOnly,
    required this.cardsAccepted,
    required this.closedSundays,
    required this.kitchenClosesEarly,
    required this.goodInRain,
    required this.goodWithTiredFeet,
    required this.dietaryFlags,
    required this.lastVerifiedDate,
  });

  factory FoodStop.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as Map<String, dynamic>;
    return FoodStop(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (coords['latitude'] as num).toDouble(),
      longitude: (coords['longitude'] as num).toDouble(),
      type: json['type'] as String,
      cuisine: json['cuisine'] as String,
      priceBand: json['price_band'] as String? ?? '€',
      signatureOrder: json['signature_order'] as String,
      openingHours: json['opening_hours'] as String,
      closingDays: (json['closing_days'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      cashOnly: json['cash_only'] as bool? ?? false,
      cardsAccepted: json['cards_accepted'] as bool? ?? true,
      closedSundays: json['closed_sundays'] as bool? ?? false,
      kitchenClosesEarly: json['kitchen_closes_early'] as bool? ?? false,
      goodInRain: json['good_in_rain'] as bool? ?? true,
      goodWithTiredFeet: json['good_with_tired_feet'] as bool? ?? true,
      dietaryFlags: (json['dietary_flags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      lastVerifiedDate: json['last_verified_date'] as String? ?? '',
    );
  }

  String get typeLabel {
    switch (type) {
      case 'cafe':
        return 'Café & Bakery';
      case 'traditional_restaurant':
        return 'Traditional Restaurant';
      case 'quick_bite':
        return 'Quick Bite / Imbiss';
      case 'market_hall':
        return 'Covered Market Hall';
      default:
        return 'Food Stop';
    }
  }
}

