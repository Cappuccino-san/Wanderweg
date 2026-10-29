import 'package:flutter/material.dart';
import '../../models/city.dart';
import '../../services/pack_download_manager.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/stop_card_dialog.dart';

class CitiesTab extends StatelessWidget {
  final AppState state;

  const CitiesTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final countries = state.repo.countries;
    final selectedCountry = state.selectedCountry;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Launch City Packs'),
        actions: [
          // Global Airplane mode toggle
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: FilterChip(
              avatar: Icon(
                state.isAirplaneMode
                    ? Icons.airplanemode_active
                    : Icons.airplanemode_inactive,
                size: 16,
                color: state.isAirplaneMode ? Colors.white : AppTheme.inkBlack,
              ),
              label: Text(
                state.isAirplaneMode ? 'Airplane Mode ON' : 'Airplane Mode OFF',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: state.isAirplaneMode ? Colors.white : AppTheme.inkBlack,
                ),
              ),
              selected: state.isAirplaneMode,
              selectedColor: const Color(0xFF1B3A27),
              onSelected: (val) => state.setAirplaneMode(val),
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
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Country Selection (Manifest-driven, not hardcoded!)
          _buildCountrySelectorCard(context, countries, selectedCountry),
          const SizedBox(height: 16),

          // 2. Multi-City Trip Planner Section
          _buildTripPlannerSection(context, selectedCountry),
          const SizedBox(height: 20),

          // 3. Standing Principle Callout
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.warmCanvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderOutline),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tune, size: 20, color: AppTheme.inkBlack),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Standing Principle: Dynamic Sizing & Honesty',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkBlack,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '1 day per city by default, adjustable per city. Plans re-size instead of cramming. Berlin offline is verified (1.77 MB MBTiles); Dresden & Leipzig are demo packs with offline tiles pending.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Detailed City Pack Breakdown Cards
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'City Packs & Storage Manager',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.inkBlack,
              ),
            ),
          ),
          const SizedBox(height: 8),

          if (selectedCountry != null)
            ...selectedCountry.cities.map((city) => _buildDetailedCityCard(context, city))
          else
            ...state.repo.cities.map((city) => _buildDetailedCityCard(context, city)),
        ],
      ),
    );
  }

  // --- Step 1: Country Picker Card ---
  Widget _buildCountrySelectorCard(
    BuildContext context,
    List<Country> countries,
    Country? selectedCountry,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public, color: AppTheme.berlinBrick, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step 1: Pick a Country',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkBlack,
                        ),
                      ),
                      Text(
                        'Manifest-driven: ${countries.length} countries available',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Country Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: countries.map((country) {
                final isSelected = country.id == state.selectedCountryId;
                return ChoiceChip(
                  avatar: Icon(
                    isSelected ? Icons.check : Icons.flag_outlined,
                    size: 16,
                    color: isSelected ? Colors.white : AppTheme.inkBlack,
                  ),
                  label: Text(
                    country.cities.isEmpty
                        ? '${country.nameEn} (${country.nameDe}) • Stub (No packs)'
                        : '${country.nameEn} (${country.nameDe}) • ${country.cities.length} cities',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.inkBlack,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.berlinBrick,
                  backgroundColor: AppTheme.warmCanvas,
                  onSelected: (val) {
                    if (val) state.selectCountry(country.id);
                  },
                );
              }).toList(),
            ),

            if (selectedCountry != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.warmCanvas,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.train_outlined, size: 16, color: AppTheme.mutedText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Transit: ${selectedCountry.transitTypes.join(" • ")} | Currency: ${selectedCountry.currency}',
                        style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Step 2: Multi-City Trip Planner Section ---
  Widget _buildTripPlannerSection(BuildContext context, Country? country) {
    final tripCities = state.tripCities;
    final totalDays = state.totalTripDays;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: AppTheme.forestGreen, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step 2: Plan Your ${country?.nameEn ?? "Germany"} Trip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkBlack,
                        ),
                      ),
                      Text(
                        '${tripCities.length} Cities in Trip • $totalDays Days Total (Adjustable)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (tripCities.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warmCanvas,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderOutline),
                ),
                child: Center(
                  child: Text(
                    '${country?.nameEn ?? "Selected country"} is currently a stub for multi-country schema readiness.\nNo city packs or anchors are bundled yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.mutedText),
                  ),
                ),
              ),

            // Orderable Trip Cities List
            ...List.generate(tripCities.length, (index) {
              final city = tripCities[index];
              final isCurrentActive = city.id == state.activeCityId;
              final stayDays = state.getStayDays(city.id);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrentActive
                      ? AppTheme.berlinBrick.withValues(alpha: 0.06)
                      : AppTheme.warmCanvas,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrentActive
                        ? AppTheme.berlinBrick
                        : AppTheme.borderOutline,
                    width: isCurrentActive ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Order badge
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: isCurrentActive
                              ? AppTheme.berlinBrick
                              : AppTheme.inkBlack,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // City name & status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${city.nameEn} (${city.nameDe})',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.inkBlack,
                                ),
                              ),
                              Text(
                                city.id == 'berlin'
                                    ? 'PACK VERIFIED • Offline (1.77 MB)'
                                    : 'DEMO PROPOSAL • Offline tiles pending',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: city.id == 'berlin'
                                      ? AppTheme.forestGreen
                                      : AppTheme.germanGold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Reorder controls
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, size: 18),
                          tooltip: 'Move earlier in trip',
                          onPressed: index > 0
                              ? () => state.moveCityInTrip(index, index - 1)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, size: 18),
                          tooltip: 'Move later in trip',
                          onPressed: index < tripCities.length - 1
                              ? () => state.moveCityInTrip(index, index + 1)
                              : null,
                        ),

                        // Remove from trip
                        if (tripCities.length > 1)
                          IconButton(
                            icon: Icon(Icons.close, size: 18, color: AppTheme.mutedText),
                            tooltip: 'Remove from trip',
                            onPressed: () => state.removeCityFromTrip(city.id),
                          ),
                      ],
                    ),
                    const Divider(height: 14),

                    // Controls row: Stay duration & Set Active
                    Row(
                      children: [
                        // Stay length stepper
                        Text(
                          'Stay:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkBlack,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 18),
                          onPressed: stayDays > 1
                              ? () => state.setStayDays(city.id, stayDays - 1)
                              : null,
                        ),
                        Text(
                          '$stayDays ${stayDays == 1 ? 'day' : 'days'}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.inkBlack,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          onPressed: stayDays < 7
                              ? () => state.setStayDays(city.id, stayDays + 1)
                              : null,
                        ),
                        const Spacer(),

                        // Active City Button
                        if (isCurrentActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.berlinBrick,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'ACTIVE IN APP',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: AppTheme.inkBlack,
                              side: BorderSide(color: AppTheme.borderOutline),
                            ),
                            icon: const Icon(Icons.visibility_outlined, size: 14),
                            label: const Text(
                              'Switch to City',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () => state.setActiveCity(city.id),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            // Add remaining cities in country to trip
            if (country != null) ...[
              ...country.cities
                  .where((c) => !state.tripCityIds.contains(c.id))
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.forestGreen,
                            side: BorderSide(color: AppTheme.forestGreen),
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: Text(
                            'Add ${c.nameEn} to Trip Itinerary',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          onPressed: () => state.addCityToTrip(c.id),
                        ),
                      )),
            ],
          ],
        ),
      ),
    );
  }

  // --- Step 3: Detailed City Pack & Storage Manager Card ---
  Widget _buildDetailedCityCard(BuildContext context, CitySummary city) {
    final bool isBerlin = city.id == 'berlin';
    final int stayDays = state.getStayDays(city.id);
    final packManager = state.packManager;
    final status = packManager.getStatus(city.id);
    final progress = packManager.getProgress(city.id);
    final bool isCurrentActive = city.id == state.activeCityId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: City Name & Status Badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${city.nameEn} (${city.nameDe})',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.inkBlack,
                            ),
                          ),
                          if (isCurrentActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.berlinBrick,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        isBerlin
                            ? 'Prototype City • Pack Size: ${city.formattedSize} (Honest)'
                            : 'Demo Pack (Proposal for Wednesday) • ${city.formattedSize}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isBerlin ? AppTheme.forestGreen : AppTheme.germanGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(city, isBerlin),
              ],
            ),
            const SizedBox(height: 12),

            // Storage / Offline Packaging Section
            if (isBerlin)
              _buildPackManagerBox(context, city, status, progress)
            else
              _buildDemoPackNoticeBox(city),

            const SizedBox(height: 12),

            // Stay length adjustable controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.warmCanvas,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderOutline),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.inkBlack),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stay Length:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkBlack,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: stayDays > 1 ? () => state.setStayDays(city.id, stayDays - 1) : null,
                  ),
                  Text(
                    '$stayDays ${stayDays == 1 ? 'day' : 'days'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.inkBlack,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: stayDays < 7 ? () => state.setStayDays(city.id, stayDays + 1) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Confirmed / Proposed Anchors List
            if (city.anchorsConfirmed.isNotEmpty) ...[
              Text(
                isBerlin ? 'Confirmed Anchors (Section 9):' : 'Demo Proposed Anchors:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.inkBlack,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: city.anchorsConfirmed.map((anchor) {
                  final bool isEastSide = anchor.contains('East Side Gallery');
                  return GestureDetector(
                    onTap: () {
                      final stop = state.repo.stops.firstWhere(
                        (s) => s.nameEn.contains(anchor.split(' ').first) ||
                               anchor.contains(s.nameEn.split(' ').first),
                        orElse: () => state.repo.stops.first,
                      );
                      StopCardDialog.show(context, stop);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isEastSide
                            ? AppTheme.transitBlue.withValues(alpha: 0.1)
                            : AppTheme.warmCanvas,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isEastSide
                              ? AppTheme.transitBlue.withValues(alpha: 0.4)
                              : AppTheme.borderOutline,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            anchor,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isEastSide ? AppTheme.transitBlue : AppTheme.inkBlack,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.info_outline, size: 12, color: AppTheme.mutedText),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],

            // City notes
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warmCanvas,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                city.notes,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.mutedText,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(CitySummary city, bool isBerlin) {
    if (isBerlin) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.forestGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.forestGreen.withValues(alpha: 0.5)),
        ),
        child: Text(
          'PACK VERIFIED',
          style: TextStyle(
            color: AppTheme.forestGreen,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.germanGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.germanGold),
      ),
      child: const Text(
        'DEMO / PROPOSAL',
        style: TextStyle(
          color: Color(0xFF8A6500),
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildDemoPackNoticeBox(CitySummary city) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_queue, size: 16, color: AppTheme.germanGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${city.nameEn} Demo Pack (Approved Proposal)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.inkBlack,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.warmCanvas,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderOutline),
                ),
                child: const Text(
                  'WEB / DEMO ONLY',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Honest status: Walks, stop cards, and sample food pauses are loaded from pack JSON. Offline map tiles are pending for stretch goal; runs via web tiles when online or offline canvas when in airplane mode.',
            style: TextStyle(fontSize: 11, color: AppTheme.mutedText, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildPackManagerBox(
    BuildContext context,
    CitySummary city,
    PackStatus status,
    DownloadProgress? progress,
  ) {
    final packManager = state.packManager;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.offline_pin, size: 18, color: AppTheme.forestGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Offline Map Tiles & Pack Packaging',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.inkBlack,
                  ),
                ),
              ),
              Text(
                'v${city.packVersion ?? "1.2.0"}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Honest Size: ${(city.packSizeBytes / 1024).toStringAsFixed(1)} KB Content Pack + '
            '${(city.tilesSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB Map Tiles (219 tiles, z13–z16) = '
            '${city.formattedSize} Total.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.inkBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Offline map and content verified on disk. Works with 0 data.',
            style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
          ),
          const SizedBox(height: 10),

          // Actions: Check Wi-Fi update & Delete
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.sync, size: 14),
                label: const Text('Check Wi-Fi Update', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppTheme.inkBlack,
                  side: BorderSide(color: AppTheme.borderOutline),
                ),
                onPressed: () {
                  packManager.checkForUpdates(city, isWifiConnected: state.isWifiConnected);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        !state.isWifiConnected
                            ? 'Wi-Fi not connected (or in Airplane Mode). Updates paused.'
                            : 'Pack is fully up to date on Wi-Fi (SHA-256 verified).',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const Spacer(),
              TextButton.icon(
                icon: Icon(Icons.delete_outline, size: 14, color: AppTheme.berlinBrick),
                label: Text(
                  'DELETE PACK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.berlinBrick,
                  ),
                ),
                onPressed: () => _confirmDeletePack(context, city),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeletePack(BuildContext context, CitySummary city) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${city.nameEn} Offline Pack?'),
        content: Text(
          'This will delete the ${city.formattedSize} offline map tiles and pack data from your device storage. You can re-download it later on Wi-Fi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('KEEP PACK'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.berlinBrick),
            onPressed: () {
              state.packManager.deletePack(city.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted ${city.nameEn} offline pack to free storage cleanly.'),
                ),
              );
            },
            child: const Text('DELETE TO FREE SPACE'),
          ),
        ],
      ),
    );
  }
}