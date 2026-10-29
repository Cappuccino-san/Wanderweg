class FoodPosition {
  final int positionOrder;
  final String afterStopId;
  final String foodStopId;
  final String contextNote;

  FoodPosition({
    required this.positionOrder,
    required this.afterStopId,
    required this.foodStopId,
    required this.contextNote,
  });

  factory FoodPosition.fromJson(Map<String, dynamic> json) {
    return FoodPosition(
      positionOrder: json['position_order'] as int? ?? 1,
      afterStopId: json['after_stop_id'] as String,
      foodStopId: json['food_stop_id'] as String,
      contextNote: json['context_note'] as String? ?? '',
    );
  }
}

class Walk {
  final String id;
  final String title;
  final String cityId;
  final String priorityTier; // 'core' or 'extended'
  final List<String> themes;
  final String editorialIntroduction;
  final String whoWillLoveIt;
  final String whoShouldPickAnother;
  final double distanceKm;
  final int walkingMinutes;
  final int totalMinutesWithStops;
  final String elevation;
  final String surfaces;
  final String startTransit;
  final String endTransit;
  final Map<String, String> nearestStationsByStop;
  final String bestTimeOfDay;
  final List<String> unsuitableDays;
  final String weatherVariantNote;
  final List<String> stops;
  final List<FoodPosition> foodPositions;

  Walk({
    required this.id,
    required this.title,
    required this.cityId,
    required this.priorityTier,
    required this.themes,
    required this.editorialIntroduction,
    required this.whoWillLoveIt,
    required this.whoShouldPickAnother,
    required this.distanceKm,
    required this.walkingMinutes,
    required this.totalMinutesWithStops,
    required this.elevation,
    required this.surfaces,
    required this.startTransit,
    required this.endTransit,
    required this.nearestStationsByStop,
    required this.bestTimeOfDay,
    required this.unsuitableDays,
    required this.weatherVariantNote,
    required this.stops,
    required this.foodPositions,
  });

  factory Walk.fromJson(Map<String, dynamic> json) {
    final Map<String, String> stations = {};
    if (json.containsKey('nearest_stations_by_stop') &&
        json['nearest_stations_by_stop'] is Map) {
      (json['nearest_stations_by_stop'] as Map).forEach((k, v) {
        stations[k.toString()] = v.toString();
      });
    }

    return Walk(
      id: json['id'] as String,
      title: json['title'] as String,
      cityId: json['city_id'] as String,
      priorityTier: json['priority_tier'] as String? ?? 'core',
      themes: (json['themes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      editorialIntroduction: json['editorial_introduction'] as String,
      whoWillLoveIt: json['who_will_love_it'] as String? ?? '',
      whoShouldPickAnother: json['who_should_pick_another'] as String? ?? '',
      distanceKm: (json['distance_km'] as num).toDouble(),
      walkingMinutes: json['walking_minutes'] as int,
      totalMinutesWithStops: json['total_minutes_with_stops'] as int,
      elevation: json['elevation'] as String? ?? 'Flat',
      surfaces: json['surfaces'] as String? ?? 'Paved',
      startTransit: json['start_transit'] as String,
      endTransit: json['end_transit'] as String,
      nearestStationsByStop: stations,
      bestTimeOfDay: json['best_time_of_day'] as String? ?? 'Morning',
      unsuitableDays: (json['unsuitable_days'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      weatherVariantNote: json['weather_variant_note'] as String? ?? '',
      stops: (json['stops'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      foodPositions: (json['food_positions'] as List<dynamic>?)
              ?.map((e) => FoodPosition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
