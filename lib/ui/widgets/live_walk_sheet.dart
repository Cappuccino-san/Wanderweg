import 'package:flutter/material.dart';
import '../../models/food_stop.dart';
import '../../models/route_leg.dart';
import '../../models/stop.dart';
import '../../models/walk.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import 'food_stop_dialog.dart';
import 'stop_card_dialog.dart';

class LiveWalkSheet extends StatelessWidget {
  final AppState state;

  const LiveWalkSheet({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final Walk? walk = state.selectedWalk;
    if (walk == null) return const SizedBox.shrink();

    final Stop? currentStop = state.currentStop;
    final RouteLeg? leg = state.currentLeg;
    final FoodStop? food = state.upcomingFoodStop;
    final int totalStops = walk.stops.length;
    final double progress = (state.currentStopIndex + 1) / totalStops;
    final bool isLastStop = state.currentStopIndex == totalStops - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar: Status + Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: state.isPaused
                        ? AppTheme.warningAmber.withValues(alpha: 0.15)
                        : AppTheme.forestGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: state.isPaused
                              ? AppTheme.warningAmber
                              : AppTheme.forestGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.isPaused ? 'WALK PAUSED' : 'LIVE WALK MODE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: state.isPaused
                              ? AppTheme.warningAmber
                              : AppTheme.forestGreen,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Stop ${state.currentStopIndex + 1} of $totalStops',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.borderOutline,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.inkBlack),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 12),

            // Off-route gentle banner (Zero scolding alert!)
            if (state.isOffRoute)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warmCanvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.germanGold, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.explore, size: 18, color: AppTheme.germanGold),
                        SizedBox(width: 8),
                        Text(
                          'Wandering off route',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppTheme.inkBlack,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enjoy exploring side streets! Rejoin whenever you are ready, or keep this as your path.',
                      style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => state.rejoinWalk(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(36),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Rejoin Walk',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => state.makeThisTheRoute(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.inkBlack,
                              minimumSize: const Size.fromHeight(36),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Make this route',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Next instruction in plain words a human would speak
            if (leg != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warmCanvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderOutline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_walk,
                            size: 18, color: AppTheme.inkBlack),
                        const SizedBox(width: 6),
                        Text(
                          'Next Leg Direction',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${leg.distanceM}m • ~${leg.walkMinutes} min',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkBlack,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      leg.plainInstruction,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkBlack,
                        height: 1.3,
                      ),
                    ),
                    if (leg.indoorAlternative != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.umbrella,
                                size: 14, color: AppTheme.transitBlue),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Rain option: ${leg.indoorAlternative}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.transitBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // Current Stop Card row (One-tap 1-minute read)
            if (currentStop != null)
              InkWell(
                onTap: () => StopCardDialog.show(context, currentStop),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderOutline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: currentStop.isAnchor
                              ? AppTheme.germanGold
                              : AppTheme.inkBlack,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${state.currentStopIndex + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentStop.nameEn,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.inkBlack,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${currentStop.dwellTimeMinutes}m dwell • Tap for 1-minute story',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppTheme.inkBlack),
                    ],
                  ),
                ),
              ),

            // Food recommendation prompt (if near)
            if (food != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InkWell(
                  onTap: () => FoodStopDialog.show(context, food),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.forestGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.forestGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.restaurant,
                            size: 16, color: AppTheme.forestGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Food nearby: ${food.name} (${food.cuisine})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.forestGreen,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            size: 12, color: AppTheme.forestGreen),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 14),

            // Navigation Controls: Arrive / Finish, Pause, Skip, End Early
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final completed = state.advanceToNextStop();
                      if (completed) {
                        _showCompletionDialog(context);
                      }
                    },
                    icon: Icon(
                      isLastStop ? Icons.emoji_events : Icons.check_circle,
                      size: 20,
                    ),
                    label: Text(
                      isLastStop ? 'Finish Walk' : 'Arrived at Stop',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: state.isPaused ? 'Resume Walk' : 'Pause Walk',
                  icon: Icon(
                    state.isPaused ? Icons.play_arrow : Icons.pause,
                    color: AppTheme.inkBlack,
                  ),
                  onPressed: () {
                    if (state.isPaused) {
                      state.resumeWalk();
                    } else {
                      state.pauseWalk();
                    }
                  },
                ),
                IconButton.outlined(
                  tooltip: 'Skip Stop',
                  icon: Icon(Icons.skip_next, color: AppTheme.inkBlack),
                  onPressed: () => state.skipStop(),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppTheme.inkBlack),
                  onSelected: (val) {
                    if (val == 'drift') {
                      state.simulateDriftOffRoute();
                    } else if (val == 'end_early') {
                      _showEndEarlyDialog(context);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'drift',
                      child: Text('Simulate Off-Route Drift'),
                    ),
                    const PopupMenuItem(
                      value: 'end_early',
                      child: Text('End Early to Nearest Station'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEndEarlyDialog(BuildContext context) {
    final info = state.getEndEarlyInfo();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_transit,
                    color: AppTheme.transitBlue, size: 24),
                SizedBox(width: 8),
                Text(
                  'End Early to Nearest Station',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.inkBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warmCanvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderOutline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From: ${info.stopName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.train,
                          size: 18, color: AppTheme.transitBlue),
                      const SizedBox(width: 6),
                      Text(
                        info.nearestStation,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.transitBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    info.directions,
                    style: TextStyle(fontSize: 13, color: AppTheme.inkBlack),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                state.endWalkEarly();
              },
              child: const Text('Conclude Walk & Save to Journal'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Keep Walking'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.forestGreen, size: 28),
                SizedBox(width: 10),
                Text(
                  'Walk Completed!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.inkBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'You finished ${state.selectedWalk?.title ?? 'the walk'}. Great job seeing the city properly on foot.',
              style: TextStyle(fontSize: 14, color: AppTheme.mutedText),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warmCanvas,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${state.selectedWalk?.distanceKm ?? 0} km',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                      Text('Distance',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.mutedText)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${state.selectedWalk?.stops.length ?? 0}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkBlack,
                        ),
                      ),
                      Text('Stops Seen',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.mutedText)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Return to Today Overview'),
            ),
          ],
        ),
      ),
    );
  }
}