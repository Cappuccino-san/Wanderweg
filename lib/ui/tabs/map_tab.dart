import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/food_stop.dart';
import '../../models/stop.dart';
import '../../models/walk.dart';
import '../../services/offline_tile_provider.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/food_stop_dialog.dart';
import '../widgets/live_walk_sheet.dart';
import '../widgets/stop_card_dialog.dart';

class MapTab extends StatefulWidget {
  final AppState state;
  final bool enableTileNetwork;

  const MapTab({
    super.key,
    required this.state,
    this.enableTileNetwork = true,
  });

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();
  bool _showFood = true;
  final bool _showAllStops = true;
  String? _lastCityId;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final walk = state.selectedWalk;
    final bool isBerlin = state.activeCityId == 'berlin';

    // Collect stops for current walk or all city stops
    final List<Stop> visibleStops = walk != null
        ? walk.stops
            .map((id) => state.repo.getStop(id))
            .whereType<Stop>()
            .toList()
        : state.repo.stops;

    // Collect food stops
    final List<FoodStop> visibleFood = walk != null
        ? walk.foodPositions
            .map((fp) => state.repo.getFoodStop(fp.foodStopId))
            .whereType<FoodStop>()
            .toList()
        : state.repo.foodStops;

    // Pedestrian path geometry: follows actual street footpaths, NOT straight lines!
    final List<LatLng> polylinePoints = walk != null
        ? state.repo.getWalkPathCoordinates(walk)
        : visibleStops.map((s) => LatLng(s.latitude, s.longitude)).toList();

    // Map Center
    final center = visibleStops.isNotEmpty
        ? LatLng(visibleStops.first.latitude, visibleStops.first.longitude)
        : (state.activeCityMeta != null
            ? LatLng(state.activeCityMeta!.latitude, state.activeCityMeta!.longitude)
            : const LatLng(52.516275, 13.377704));

    // Move map when city changes
    if (_lastCityId != state.activeCityId) {
      _lastCityId = state.activeCityId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (visibleStops.isNotEmpty) {
          _mapController.move(
            LatLng(visibleStops.first.latitude, visibleStops.first.longitude),
            14.4,
          );
        }
      });
    }

    final cityWalks = state.repo.getWalksForCity(state.activeCityId);
    final availableWalks = cityWalks.isNotEmpty ? cityWalks : state.repo.walks;

    return Scaffold(
      body: Stack(
        children: [
          // FlutterMap rendering OpenStreetMap tiles
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14.4,
              maxZoom: 18.0,
              minZoom: 11.0,
            ),
            children: [
              // Offline-first Map Tiles per Section 10:
              // Bundled and cached tiles load with zero HTTP streaming in airplane mode
              TileLayer(
                key: ValueKey('tile_layer_${state.activeCityId}_${state.isAirplaneMode}_${state.isDarkMode}'),
                urlTemplate: (state.isAirplaneMode || isBerlin)
                    ? 'assets/tiles/${state.activeCityId}/{z}/{x}/{y}.png'
                    : (state.isDarkMode
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png'),
                subdomains: const ['a', 'b', 'c', 'd'],
                tileProvider: (state.isAirplaneMode || isBerlin)
                    ? OfflineTileProvider(
                        cityId: state.activeCityId,
                        forceOfflineGrid: !state.packManager.isDownloaded(state.activeCityId),
                      )
                    : NetworkTileProvider(),
                maxZoom: 16.0,
                minZoom: 13.0,
                maxNativeZoom: 16,
                tileBuilder: (context, tileWidget, tile) {
                  if (state.isDarkMode && (state.isAirplaneMode || isBerlin)) {
                    return ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        -0.85, 0, 0, 0, 235,
                        0, -0.85, 0, 0, 235,
                        0, 0, -0.85, 0, 235,
                        0, 0, 0, 1, 0,
                      ]),
                      child: tileWidget,
                    );
                  }
                  return tileWidget;
                },
              ),

              // Polyline connecting the pedestrian walk
              if (polylinePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    // Outer contrasting casing line
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 6.0,
                      color: Colors.white,
                    ),
                    // Inner route line
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 4.0,
                      color: AppTheme.inkBlack,
                    ),
                  ],
                ),

              // Stop Markers
              if (_showAllStops)
                MarkerLayer(
                  markers: visibleStops.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final stop = entry.value;
                    final isCurrentInWalk = state.isLiveWalking &&
                        state.currentStop?.id == stop.id;

                    return Marker(
                      point: LatLng(stop.latitude, stop.longitude),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => StopCardDialog.show(context, stop),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: isCurrentInWalk
                                ? AppTheme.berlinBrick
                                : (stop.isAnchor
                                    ? AppTheme.inkBlack
                                    : AppTheme.cardSurface),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCurrentInWalk
                                  ? Colors.white
                                  : (stop.isAnchor
                                      ? AppTheme.germanGold
                                      : AppTheme.inkBlack),
                              width: isCurrentInWalk ? 3.0 : 2.0,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$idx',
                              style: TextStyle(
                                color: isCurrentInWalk || stop.isAnchor
                                    ? Colors.white
                                    : AppTheme.inkBlack,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Food Stop Markers
              if (_showFood)
                MarkerLayer(
                  markers: visibleFood.map((food) {
                    return Marker(
                      point: LatLng(food.latitude, food.longitude),
                      width: 32,
                      height: 32,
                      child: GestureDetector(
                        onTap: () => FoodStopDialog.show(context, food),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.forestGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          // Top walk-selector chip & toggles
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Airplane mode / offline status pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => state.setAirplaneMode(!state.isAirplaneMode),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: state.isAirplaneMode
                                ? const Color(0xFF1B3A27) // Forest dark
                                : AppTheme.cardSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: state.isAirplaneMode
                                  ? AppTheme.forestGreen
                                  : AppTheme.borderOutline,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                state.isAirplaneMode ? Icons.airplanemode_active : Icons.wifi,
                                size: 14,
                                color: state.isAirplaneMode ? Colors.white : AppTheme.forestGreen,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                state.isAirplaneMode
                                    ? (isBerlin
                                        ? 'AIRPLANE MODE • OFFLINE MAP (ZERO DATA)'
                                        : 'AIRPLANE MODE • DEMO PACK (MAP TILES PENDING)')
                                    : (isBerlin
                                        ? 'ONLINE • OFFLINE PACK READY (7.0 MB)'
                                        : 'ONLINE • DEMO PACK (WEB TILES)'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: state.isAirplaneMode ? Colors.white : AppTheme.inkBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => state.toggleDarkMode(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.cardSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.borderOutline),
                              ),
                              child: Icon(
                                state.isDarkMode ? Icons.light_mode : Icons.dark_mode_outlined,
                                size: 14,
                                color: AppTheme.inkBlack,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.cardSurface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.borderOutline),
                            ),
                            child: Text(
                              state.activeCityMeta?.packVersion ?? '1.0.0-demo',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.mutedText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // City Switcher + Walk Selector Row
                  Row(
                    children: [
                      // City Switcher Pill
                      PopupMenuButton<String>(
                        tooltip: 'Switch Trip City',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderOutline),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_city,
                                size: 14,
                                color: isBerlin ? AppTheme.berlinBrick : AppTheme.forestGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                state.activeCitySummary?.nameEn ?? 'City',
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
                          state.setActiveCity(cityId);
                          final walks = state.repo.getWalksForCity(cityId);
                          if (walks.isNotEmpty && walks.first.stops.isNotEmpty) {
                            final stop = state.repo.getStop(walks.first.stops.first);
                            if (stop != null) {
                              _mapController.move(LatLng(stop.latitude, stop.longitude), 14.4);
                            }
                          }
                        },
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
                                  c.nameEn,
                                  style: TextStyle(
                                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(width: 8),

                      // Walk Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.cardSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderOutline),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Walk>(
                              value: walk,
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down,
                                  color: AppTheme.inkBlack),
                              items: availableWalks.map((w) {
                                return DropdownMenuItem(
                                  value: w,
                                  child: Text(
                                    w.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppTheme.inkBlack,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (w) {
                                if (w != null) {
                                  state.selectWalk(w);
                                  if (w.stops.isNotEmpty) {
                                    final firstStop =
                                        state.repo.getStop(w.stops.first);
                                    if (firstStop != null) {
                                      _mapController.move(
                                        LatLng(firstStop.latitude,
                                            firstStop.longitude),
                                        14.4,
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Layer toggle: Food
                      IconButton.filledTonal(
                        tooltip: 'Toggle Food Markers',
                        style: IconButton.styleFrom(
                          backgroundColor: _showFood
                              ? AppTheme.forestGreen.withValues(alpha: 0.15)
                              : AppTheme.cardSurface,
                          foregroundColor: _showFood
                              ? AppTheme.forestGreen
                              : AppTheme.mutedText,
                        ),
                        icon: const Icon(Icons.restaurant, size: 20),
                        onPressed: () {
                          setState(() {
                            _showFood = !_showFood;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Live Walk Control Sheet or Walk Overview Sheet
          if (walk != null && !state.isLiveWalking)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              walk.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.inkBlack,
                              ),
                            ),
                          ),
                          Text(
                            '${walk.distanceKm} km',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${walk.stops.length} stops • Start: ${walk.startTransit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                state.startLiveWalk(walk);
                              },
                              icon: const Icon(Icons.navigation_outlined, size: 18),
                              label: const Text('START LIVE WALK'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Live Walk Active Sheet
          if (state.isLiveWalking)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LiveWalkSheet(state: state),
            ),
        ],
      ),
    );
  }
}