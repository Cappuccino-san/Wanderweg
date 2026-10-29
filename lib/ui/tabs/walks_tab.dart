import 'package:flutter/material.dart';
import '../../models/stop.dart';
import '../../models/walk.dart';
import '../../services/route_builder_engine.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/food_stop_dialog.dart';
import '../widgets/stop_card_dialog.dart';

class WalksTab extends StatefulWidget {
  final AppState state;
  final VoidCallback onStartLiveWalk;
  final VoidCallback onNavigateToMap;

  const WalksTab({
    super.key,
    required this.state,
    required this.onStartLiveWalk,
    required this.onNavigateToMap,
  });

  @override
  State<WalksTab> createState() => _WalksTabState();
}

class _WalksTabState extends State<WalksTab> {
  String _selectedThemeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final activeCity = widget.state.activeCitySummary;
    final activeCityName = activeCity?.nameEn ?? 'Berlin';
    final cityWalks = widget.state.repo.getWalksForCity(widget.state.activeCityId);
    final walks = cityWalks.isNotEmpty ? cityWalks : widget.state.repo.walks;
    final filtered = _selectedThemeFilter == 'all'
        ? walks
        : walks
            .where((w) => w.themes.contains(_selectedThemeFilter))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('$activeCityName Walks'),
        actions: [
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
                    color: widget.state.activeCityId == 'berlin'
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
            onSelected: (cityId) {
              widget.state.setActiveCity(cityId);
              setState(() {});
            },
            itemBuilder: (context) => widget.state.tripCities.map((c) {
              final isCurrent = c.id == widget.state.activeCityId;
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
                      '${c.nameEn} (${widget.state.getStayDays(c.id)}d)',
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed: () => _openRouteBuilder(context),
            icon: Icon(Icons.handyman_outlined,
                size: 18, color: AppTheme.inkBlack),
            label: Text(
              'Route Builder',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.inkBlack,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              widget.state.isDarkMode ? Icons.light_mode : Icons.dark_mode_outlined,
              color: AppTheme.inkBlack,
              size: 20,
            ),
            tooltip: widget.state.isDarkMode
                ? 'Switch to Light Background'
                : 'Switch to Dark Background',
            onPressed: () => widget.state.toggleDarkMode(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip('all', 'All Walks'),
                _filterChip('history', 'History'),
                _filterChip('food and markets', 'Food & Markets'),
                _filterChip('war and division', 'War & Division'),
                _filterChip('rivers and views', 'River & Views'),
              ],
            ),
          ),

          // Walk List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (ctx, index) {
                final walk = filtered[index];
                return Column(
                  children: [
                    if (index == 0 && activeCity?.status == 'demo')
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.germanGold.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.germanGold),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Color(0xFF8A6500)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Demo Proposals for $activeCityName: Walks, stop orders, and sample food stops are approved proposals for the Wednesday review.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5A4300),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildWalkCard(walk),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String themeKey, String label) {
    final isSelected = _selectedThemeFilter == themeKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (_) {
          setState(() {
            _selectedThemeFilter = themeKey;
          });
        },
        selectedColor: AppTheme.inkBlack,
        backgroundColor: AppTheme.warmCanvas,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.inkBlack,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppTheme.inkBlack : AppTheme.borderOutline,
          ),
        ),
      ),
    );
  }

  Widget _buildWalkCard(Walk walk) {
    final bool isSaved = widget.state.isWalkSaved(walk.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: walk.priorityTier == 'core'
                        ? AppTheme.forestGreen.withValues(alpha: 0.12)
                        : AppTheme.warmCanvas,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: walk.priorityTier == 'core'
                          ? AppTheme.forestGreen.withValues(alpha: 0.4)
                          : AppTheme.borderOutline,
                    ),
                  ),
                  child: Text(
                    walk.priorityTier == 'core' ? 'CORE WALK' : 'EXTENDED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: walk.priorityTier == 'core'
                          ? AppTheme.forestGreen
                          : AppTheme.mutedText,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? AppTheme.germanGold : AppTheme.mutedText,
                    size: 22,
                  ),
                  onPressed: () => widget.state.toggleSaveWalk(walk.id),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              walk.title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.inkBlack,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              walk.editorialIntroduction,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.mutedText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),

            // Honest audience guidance
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warmCanvas,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Best for: ${walk.whoWillLoveIt}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick another if: ${walk.whoShouldPickAnother}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Metrics row
            Wrap(
              spacing: 12,
              children: [
                _metric(Icons.straighten, '${walk.distanceKm} km'),
                _metric(Icons.directions_walk, '~${walk.walkingMinutes} min walk'),
                _metric(Icons.timer_outlined, '~${walk.totalMinutesWithStops} min total'),
              ],
            ),
            const SizedBox(height: 16),

            // Stop chips
            Text(
              'Stops in order:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.inkBlack,
              ),
            ),
            const SizedBox(height: 6),
            ...walk.stops.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final stopId = entry.value;
              final stop = widget.state.repo.getStop(stopId);
              if (stop == null) return const SizedBox.shrink();

              // Check if food sits after this stop
              final foodPos = walk.foodPositions
                  .where((fp) => fp.afterStopId == stopId)
                  .firstOrNull;
              final food = foodPos != null
                  ? widget.state.repo.getFoodStop(foodPos.foodStopId)
                  : null;

              return Column(
                children: [
                  InkWell(
                    onTap: () => StopCardDialog.show(context, stop),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: stop.isAnchor
                                  ? AppTheme.germanGold
                                  : AppTheme.warmCanvas,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.borderOutline),
                            ),
                            child: Center(
                              child: Text(
                                '$idx',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: stop.isAnchor
                                      ? Colors.white
                                      : AppTheme.inkBlack,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              stop.nameEn,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.inkBlack,
                              ),
                            ),
                          ),
                          Icon(Icons.info_outline,
                              size: 16, color: AppTheme.mutedText),
                        ],
                      ),
                    ),
                  ),
                  if (food != null)
                    InkWell(
                      onTap: () => FoodStopDialog.show(context, food),
                      child: Container(
                        margin: const EdgeInsets.only(left: 30, top: 2, bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.forestGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.forestGreen.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restaurant,
                                size: 12, color: AppTheme.forestGreen),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Food break: ${food.name} (${food.typeLabel})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.forestGreen,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.state.selectWalk(walk);
                      widget.onNavigateToMap();
                    },
                    child: const Text('View on Map'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.state.startLiveWalk(walk);
                      widget.onStartLiveWalk();
                    },
                    child: const Text('Start Walk'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.mutedText),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.inkBlack,
          ),
        ),
      ],
    );
  }

  void _openRouteBuilder(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RouteBuilderModal(
        state: widget.state,
        onStartWalk: () {
          Navigator.of(context).pop();
          widget.onStartLiveWalk();
        },
      ),
    );
  }
}

class _RouteBuilderModal extends StatefulWidget {
  final AppState state;
  final VoidCallback onStartWalk;

  const _RouteBuilderModal({
    required this.state,
    required this.onStartWalk,
  });

  @override
  State<_RouteBuilderModal> createState() => _RouteBuilderModalState();
}

class _RouteBuilderModalState extends State<_RouteBuilderModal> {
  // Starts with confirmed Berlin anchors
  final Set<String> _selectedAnchorIds = {
    'brandenburg-gate',
    'reichstag-exterior',
    'unter-den-linden-promenade',
    'checkpoint-charlie',
    'east-side-gallery-extension',
  };

  // Accepted suggestions (Explicitly accepted by user, never silent)
  final Set<String> _acceptedSuggestionIds = {};

  EastSideGalleryOption _eastSideOpt = EastSideGalleryOption.transitExtension;

  @override
  Widget build(BuildContext context) {
    final allStops = widget.state.repo.stops;
    final selectedStops = _selectedAnchorIds
        .map((id) => widget.state.repo.getStop(id))
        .whereType<Stop>()
        .toList();

    final stayDays = widget.state.getStayDays('berlin');

    final result = RouteBuilderEngine.buildRoute(
      selectedAnchors: selectedStops,
      allAvailableStops: allStops,
      acceptedSuggestionIds: _acceptedSuggestionIds,
      stayDays: stayDays,
      eastSideOption: _eastSideOpt,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppTheme.borderOutline,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anchor Route Builder',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkBlack,
                        ),
                      ),
                      Text(
                        'Builds on what you know • Zero backtracking • No silent additions',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.inkBlack),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(height: 20, thickness: 1, color: AppTheme.borderOutline),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Anchor selection toggles
                Text(
                  'Your Selected Anchors:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.inkBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allStops.where((s) => s.isAnchor).map((s) {
                    final isChecked = _selectedAnchorIds.contains(s.id);
                    return FilterChip(
                      selected: isChecked,
                      label: Text(s.nameEn),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedAnchorIds.add(s.id);
                          } else {
                            if (_selectedAnchorIds.length > 2) {
                              _selectedAnchorIds.remove(s.id);
                            }
                          }
                        });
                      },
                      selectedColor: AppTheme.germanGold,
                      backgroundColor: AppTheme.warmCanvas,
                      labelStyle: TextStyle(
                        color: isChecked ? Colors.white : AppTheme.inkBlack,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Suggested Additions (Explicitly Offered, Never Silently Added)
                if (result.availableSuggestions.isNotEmpty) ...[
                  Text(
                    'Suggested Additions (Between Anchors):',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.inkBlack,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...result.availableSuggestions.map((sug) {
                    final isAccepted =
                        _acceptedSuggestionIds.contains(sug.stop.id);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warmCanvas,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAccepted
                              ? AppTheme.forestGreen
                              : AppTheme.borderOutline,
                          width: isAccepted ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sug.stop.nameEn,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.inkBlack,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sug.reason,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                if (isAccepted) {
                                  _acceptedSuggestionIds.remove(sug.stop.id);
                                } else {
                                  _acceptedSuggestionIds.add(sug.stop.id);
                                }
                              });
                            },
                            icon: Icon(
                              isAccepted
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              color: isAccepted
                                  ? AppTheme.forestGreen
                                  : AppTheme.inkBlack,
                              size: 18,
                            ),
                            label: Text(
                              isAccepted ? 'Added' : 'Add',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isAccepted
                                    ? AppTheme.forestGreen
                                    : AppTheme.inkBlack,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // East Side Gallery special handling (Mandatory Spec Feature)
                if (_selectedAnchorIds.contains('east-side-gallery-extension')) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.transitBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.transitBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.east,
                                size: 18, color: AppTheme.transitBlue),
                            SizedBox(width: 8),
                            Text(
                              'East Side Gallery Treatment',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppTheme.transitBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The Wall at the East Side Gallery is 3.2 km east of Mitte. Choose how you want to connect it:',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.inkBlack,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _eastSideOptionTile(
                          title: 'Transit connection (12 min U/S-Bahn)',
                          value: EastSideGalleryOption.transitExtension,
                        ),
                        _eastSideOptionTile(
                          title: 'Riverside walk east along Spree (45 min on foot)',
                          value: EastSideGalleryOption.riversideWalkEast,
                        ),
                        _eastSideOptionTile(
                          title: 'Separate segment (leave for afternoon or Day 2)',
                          value: EastSideGalleryOption.separateSegment,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Live Route Metrics
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.warmCanvas,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderOutline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Optimized Route Metrics',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.inkBlack,
                            ),
                          ),
                          Text(
                            '${result.totalDistanceKm.toStringAsFixed(1)} km • ~${result.totalMinutes} min',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.forestGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        result.daySizingRecommendation,
                        style: TextStyle(
                          fontSize: 12,
                          color: result.exceedsSingleDay
                              ? AppTheme.warningAmber
                              : AppTheme.mutedText,
                          fontWeight: result.exceedsSingleDay
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Ordered Stops
                Text(
                  'Sequenced Stops (No backtracking):',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.inkBlack,
                  ),
                ),
                const SizedBox(height: 8),
                ...result.orderedStops.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final stop = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: stop.isAnchor
                              ? AppTheme.germanGold
                              : AppTheme.inkBlack,
                          child: Text(
                            '$idx',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            stop.nameEn,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.inkBlack,
                            ),
                          ),
                        ),
                        if (stop.isAnchor)
                          Text(
                            'Anchor',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.germanGold,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Actions: Walk Custom Route & Save
                ElevatedButton.icon(
                  onPressed: () {
                    // Create a dynamic custom walk
                    final customWalk = Walk(
                      id: 'custom-built-route',
                      title: 'Custom Anchor Route (${result.orderedStops.length} stops)',
                      cityId: 'berlin',
                      priorityTier: 'core',
                      themes: ['history', 'custom'],
                      editorialIntroduction:
                          'A personalized walk sequenced around your anchors with minimal backtracking.',
                      whoWillLoveIt: 'Travellers who want to explore their specific chosen sights.',
                      whoShouldPickAnother: '',
                      distanceKm: double.parse(result.totalDistanceKm.toStringAsFixed(1)),
                      walkingMinutes: result.totalWalkingMinutes,
                      totalMinutesWithStops: result.totalMinutes,
                      elevation: 'Flat',
                      surfaces: 'Paved granite flagstones and sidewalk',
                      startTransit: result.orderedStops.isNotEmpty
                          ? result.orderedStops.first.nameEn
                          : 'Berlin Center',
                      endTransit: result.orderedStops.isNotEmpty
                          ? result.orderedStops.last.nameEn
                          : 'Berlin Center',
                      nearestStationsByStop: {},
                      bestTimeOfDay: 'Morning to Midday',
                      unsuitableDays: [],
                      weatherVariantNote: 'Standard city walk',
                      stops: result.orderedStops.map((s) => s.id).toList(),
                      foodPositions: [],
                    );
                    widget.state.startLiveWalk(customWalk);
                    widget.onStartWalk();
                  },
                  icon: const Icon(Icons.directions_walk),
                  label: const Text('WALK THIS CUSTOM ROUTE'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    widget.state.toggleSaveWalk('custom-built-route');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Custom route saved to your Saved tab!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Save to Saved Walks'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eastSideOptionTile({
    required String title,
    required EastSideGalleryOption value,
  }) {
    final isSelected = _eastSideOpt == value;
    return InkWell(
      onTap: () => setState(() => _eastSideOpt = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.transitBlue : AppTheme.mutedText,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppTheme.transitBlue : AppTheme.inkBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}