import 'package:latlong2/latlong.dart';

class RouteLeg {
  final String fromStopId;
  final String toStopId;
  final int distanceM;
  final int walkMinutes;
  final String plainInstruction;
  final String surfaceNotes;
  final String? indoorAlternative;
  final List<LatLng> pathCoordinates;

  RouteLeg({
    required this.fromStopId,
    required this.toStopId,
    required this.distanceM,
    required this.walkMinutes,
    required this.plainInstruction,
    required this.surfaceNotes,
    this.indoorAlternative,
    required this.pathCoordinates,
  });

  factory RouteLeg.fromJson(Map<String, dynamic> json) {
    final List<LatLng> coords = [];
    if (json.containsKey('path_coordinates') &&
        json['path_coordinates'] is List) {
      for (final pt in (json['path_coordinates'] as List<dynamic>)) {
        if (pt is List && pt.length >= 2) {
          coords.add(
            LatLng((pt[0] as num).toDouble(), (pt[1] as num).toDouble()),
          );
        }
      }
    }

    return RouteLeg(
      fromStopId: json['from_stop_id'] as String,
      toStopId: json['to_stop_id'] as String,
      distanceM: json['distance_m'] as int? ?? 500,
      walkMinutes: json['walk_minutes'] as int? ?? 7,
      plainInstruction: json['plain_instruction'] as String,
      surfaceNotes: json['surface_notes'] as String? ?? 'Paved pedestrian path',
      indoorAlternative: json['indoor_alternative'] as String?,
      pathCoordinates: coords,
    );
  }
}
