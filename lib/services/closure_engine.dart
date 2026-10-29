import '../models/food_stop.dart';
import '../models/stop.dart';
import '../models/walk.dart';

class ClosureWarning {
  final String entityName;
  final String issue;
  final String recommendation;
  final bool isSevere;

  ClosureWarning({
    required this.entityName,
    required this.issue,
    required this.recommendation,
    this.isSevere = false,
  });
}

class ClosureEngine {
  static const List<String> weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  /// Official statutory public holidays in Berlin (Feiertage)
  static bool isGermanPublicHoliday(DateTime date) {
    final m = date.month;
    final d = date.day;

    // Fixed holidays
    if (m == 1 && d == 1) return true; // Neujahr
    if (m == 3 && d == 8) return true; // Frauentag (Berlin public holiday)
    if (m == 5 && d == 1) return true; // Tag der Arbeit
    if (m == 10 && d == 3) return true; // Tag der Deutschen Einheit
    if (m == 12 && d == 25) return true; // 1. Weihnachtstag
    if (m == 12 && d == 26) return true; // 2. Weihnachtstag

    // Movable Christian holidays for 2026:
    // Karfreitag: April 3, 2026; Ostermontag: April 6, 2026; Christi Himmelfahrt: May 14, 2026; Pfingstmontag: May 25, 2026
    if (date.year == 2026) {
      if (m == 4 && (d == 3 || d == 6)) return true;
      if (m == 5 && (d == 14 || d == 25)) return true;
    }

    return false;
  }

  static List<ClosureWarning> evaluateWalk({
    required Walk walk,
    required List<Stop> stops,
    required List<FoodStop> foodStops,
    required DateTime walkDate,
    required int startHour, // 24-hr format
  }) {
    final List<ClosureWarning> warnings = [];
    final currentDay = weekdayNames[walkDate.weekday - 1];
    final isSunday = walkDate.weekday == DateTime.sunday;
    final isHoliday = isGermanPublicHoliday(walkDate);

    // 1. Public Holiday or Sunday warning
    if (isHoliday) {
      warnings.add(
        ClosureWarning(
          entityName: 'Gesetzlicher Feiertag (Public Holiday)',
          issue: 'Today is an official German public holiday.',
          recommendation:
              'Retail shops are closed by law. State monuments and parks remain open, but museum hours may follow Sunday timetables.',
          isSevere: true,
        ),
      );
    } else if (isSunday) {
      warnings.add(
        ClosureWarning(
          entityName: 'Sonntagsruhe (Sunday Retail Shutdown)',
          issue: 'German law requires all regular retail stores, supermarkets, and markets to close on Sundays.',
          recommendation:
              'Bakeries, cafes, and outdoor memorial grounds remain open. The streets are peacefully pedestrian.',
          isSevere: false,
        ),
      );
    }

    // 2. Check walk unsuitable days
    if (walk.unsuitableDays.contains(currentDay)) {
      warnings.add(
        ClosureWarning(
          entityName: walk.title,
          issue: 'Today is $currentDay, which is marked as unsuitable for this walk.',
          recommendation: 'Key stops along this route observe Ruhetag (closing day) on $currentDay.',
          isSevere: true,
        ),
      );
    }

    // 3. Check individual stops
    for (final stop in stops) {
      if (stop.closingDays.contains(currentDay)) {
        warnings.add(
          ClosureWarning(
            entityName: stop.nameEn,
            issue: 'Interior closed on $currentDay (Ruhetag).',
            recommendation: 'Exterior view and grounds are still accessible on foot.',
            isSevere: false,
          ),
        );
      }
    }

    // 4. Check food stops
    for (final food in foodStops) {
      if (food.closingDays.contains(currentDay)) {
        warnings.add(
          ClosureWarning(
            entityName: food.name,
            issue: 'Closed on $currentDay.',
            recommendation: 'Alternative bakeries and cafes are located along the route legs.',
            isSevere: false,
          ),
        );
      } else if (food.closedSundays && isSunday) {
        warnings.add(
          ClosureWarning(
            entityName: food.name,
            issue: 'Closed on Sundays.',
            recommendation: 'Grab an alternative bite at a local open Imbiss or bakery.',
            isSevere: false,
          ),
        );
      }
    }

    // 5. Daylight check for evening walkers
    if (startHour >= 17) {
      warnings.add(
        ClosureWarning(
          entityName: 'Daylight & Closing Hours',
          issue: 'Starting at or after 17:00 leaves limited daylight for open-air memorials.',
          recommendation: 'Expect museum interiors to close by 18:00.',
          isSevere: false,
        ),
      );
    }

    return warnings;
  }
}
