import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/stop_card_dialog.dart';

class TodayTab extends StatelessWidget {
  final AppState state;
  final VoidCallback onStartLiveWalk;

  const TodayTab({
    super.key,
    required this.state,
    required this.onStartLiveWalk,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.repo.isLoaded) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.inkBlack),
        ),
      );
    }

    final activeCity = state.activeCitySummary;
    final activeCityName = activeCity?.nameEn ?? 'Berlin';
    final isDemoCity = activeCity?.status == 'demo';
    final proposed = state.getProposedWalksForStay();
    final primaryWalk = proposed.isNotEmpty ? proposed.first : state.selectedWalk;
    final warnings = state.getTodayClosureWarnings();
    final stayDays = state.getStayDays(state.activeCityId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Today in $activeCityName'),
        actions: [
          // City Switcher Dropdown in AppBar
          PopupMenuButton<String>(
            tooltip: 'Switch Trip City',
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warmCanvas,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderOutline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_city,
                    size: 14,
                    color: state.activeCityId == 'berlin'
                        ? AppTheme.berlinBrick
                        : AppTheme.forestGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    activeCityName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.inkBlack,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.inkBlack),
                ],
              ),
            ),
            onSelected: (cityId) => state.setActiveCity(cityId),
            itemBuilder: (context) => state.tripCities.map((c) {
              final isCurrent = c.id == state.activeCityId;
              return PopupMenuItem(
                value: c.id,
                child: Row(
                  children: [
                    Icon(
                      isCurrent ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: isCurrent ? AppTheme.forestGreen : AppTheme.mutedText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${c.nameEn} (${state.getStayDays(c.id)}d)',
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          // Trip Progress Pill
          Container(
            margin: const EdgeInsets.only(left: 8, right: 6, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warmCanvas,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderOutline),
            ),
            child: Row(
              children: [
                Icon(Icons.flight_takeoff,
                    size: 14, color: AppTheme.forestGreen),
                const SizedBox(width: 6),
                Text(
                  'Trip Day ${state.activeCityTripStartDay} of ${state.totalTripDays}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkBlack,
                  ),
                ),
              ],
            ),
          ),

          // Theme mode toggle
          IconButton(
            icon: Icon(
              state.isDarkMode ? Icons.light_mode : Icons.dark_mode_outlined,
              color: AppTheme.inkBlack,
              size: 20,
            ),
            tooltip: state.isDarkMode
                ? 'Switch to Light Background'
                : 'Switch to Dark Background',
            onPressed: () => state.toggleDarkMode(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Demo proposal banner if Dresden or Leipzig
          if (isDemoCity)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.germanGold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.germanGold),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Color(0xFF8A6500)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Wednesday Demo Proposal: $activeCityName walk, stops, and sample food pauses are approved proposals marked unverified until walked.',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A4300),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Resume banner if active
          if (state.isLiveWalking)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.inkBlack,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_walk,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Walk in Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Tap Map tab to view your live navigation.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onStartLiveWalk,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.germanGold,
                    ),
                    child: const Text('RESUME',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),

          // Airplane Mode Active Banner
          if (state.isAirplaneMode)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3A27),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.airplanemode_active, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Airplane Mode Active (Zero Cellular Data)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.activeCityId == 'berlin'
                              ? 'Berlin offline pack in use (7.0 MB MBTiles). Maps, stops, food, and journal run offline.'
                              : '$activeCityName demo pack in use. Neutral offline map canvas active (offline tiles pending).',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Stay Sizing Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.warmCanvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderOutline),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome,
                    size: 20, color: AppTheme.germanGold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stayDays == 1
                        ? '1-Day Plan in $activeCityName: 1 core walk curated for today. Sized so you see the city properly without rushing.'
                        : '$stayDays-Day Plan in $activeCityName: Walks distributed across your stay. Core on Day 1, extensions on Day 2+.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Interactive Date & Day Simulator (for testing closures)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderOutline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulation & Time Check:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.mutedText,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Start time chips
                Row(
                  children: [
                    const Text('Start:',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    _timeChip(9, '09:00'),
                    const SizedBox(width: 6),
                    _timeChip(12, '12:00'),
                    const SizedBox(width: 6),
                    _timeChip(15, '15:00'),
                    const SizedBox(width: 6),
                    _timeChip(18, '18:00 (Late)'),
                  ],
                ),
                const SizedBox(height: 8),

                // Day simulation chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Day:',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    _daySimulatorChip('Today', DateTime.now()),
                    _daySimulatorChip(
                        'Sunday', DateTime(2026, 10, 25)), // Sunday
                    _daySimulatorChip(
                        'Monday', DateTime(2026, 10, 26)), // Monday
                    _daySimulatorChip('Holiday',
                        DateTime(2026, 10, 3)), // German Unity Day
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Closure & Schedule Warnings
          if (warnings.isNotEmpty) ...[
            ...warnings.map(
              (w) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: w.isSevere
                      ? AppTheme.berlinBrick.withValues(alpha: 0.1)
                      : AppTheme.warningAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: w.isSevere
                        ? AppTheme.berlinBrick.withValues(alpha: 0.4)
                        : AppTheme.warningAmber.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      w.isSevere ? Icons.warning_amber : Icons.info_outline,
                      color: w.isSevere
                          ? AppTheme.berlinBrick
                          : AppTheme.warningAmber,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.entityName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: w.isSevere
                                  ? AppTheme.berlinBrick
                                  : AppTheme.inkBlack,
                            ),
                          ),
                          Text(
                            w.issue,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.inkBlack,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            w.recommendation,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Primary Walk Card
          if (primaryWalk != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.forestGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PROPOSED TODAY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.forestGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${primaryWalk.distanceKm} km • ~${primaryWalk.totalMinutesWithStops} min total',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      primaryWalk.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.inkBlack,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      primaryWalk.editorialIntroduction,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedText,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Transit details
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.warmCanvas,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.train,
                                  size: 16, color: AppTheme.transitBlue),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Start: ${primaryWalk.startTransit}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.inkBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.flag_outlined,
                                  size: 16, color: AppTheme.forestGreen),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'End: ${primaryWalk.endTransit}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.inkBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stops pill row
                    Text(
                      'Stops along this route:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.inkBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...primaryWalk.stops.map((stopId) {
                      final stop = state.repo.getStop(stopId);
                      if (stop == null) return const SizedBox.shrink();
                      return InkWell(
                        onTap: () => StopCardDialog.show(context, stop),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: stop.isAnchor
                                      ? AppTheme.germanGold
                                      : AppTheme.inkBlack,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  stop.nameEn,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.inkBlack,
                                  ),
                                ),
                              ),
                              Text(
                                '${stop.dwellTimeMinutes}m',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.mutedText,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right,
                                  size: 16, color: AppTheme.mutedText),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // Big Action Button
                    ElevatedButton.icon(
                      onPressed: () {
                        state.startLiveWalk(primaryWalk);
                        onStartLiveWalk();
                      },
                      icon: const Icon(Icons.play_arrow, size: 24),
                      label: const Text('START WALK NOW'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeChip(int hour, String label) {
    final isSelected = state.todayStartHour == hour;
    return InkWell(
      onTap: () => state.setTodayStartHour(hour),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.inkBlack : AppTheme.warmCanvas,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.inkBlack : AppTheme.borderOutline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.inkBlack,
          ),
        ),
      ),
    );
  }

  Widget _daySimulatorChip(String label, DateTime date) {
    final isSelected = state.selectedDate.year == date.year &&
        state.selectedDate.month == date.month &&
        state.selectedDate.day == date.day;
    return InkWell(
      onTap: () => state.setSelectedDate(date),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.forestGreen : AppTheme.warmCanvas,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.forestGreen : AppTheme.borderOutline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.inkBlack,
          ),
        ),
      ),
    );
  }
}