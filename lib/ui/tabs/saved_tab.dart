import 'package:flutter/material.dart';
import '../../models/practical_note.dart';
import '../../models/walk.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';

class SavedTab extends StatefulWidget {
  final AppState state;
  final VoidCallback onStartLiveWalk;

  const SavedTab({
    super.key,
    required this.state,
    required this.onStartLiveWalk,
  });

  @override
  State<SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends State<SavedTab> {
  String _practicalFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final savedWalks = state.savedWalkIds
        .map((id) => state.repo.getWalk(id))
        .whereType<Walk>()
        .toList();
    final journal = state.journal;
    final practicalNotes = state.repo.practicalNotes;

    final filteredNotes = _practicalFilter == 'all'
        ? practicalNotes
        : practicalNotes.where((n) => n.topic == _practicalFilter).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saved & Practical Help'),
          actions: [
            IconButton(
              icon: Icon(
                state.isDarkMode ? Icons.light_mode : Icons.dark_mode_outlined,
                color: AppTheme.inkBlack,
              ),
              tooltip: state.isDarkMode
                  ? 'Switch to Light Background'
                  : 'Switch to Dark Background',
              onPressed: () => state.toggleDarkMode(),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppTheme.inkBlack,
            unselectedLabelColor: AppTheme.mutedText,
            indicatorColor: AppTheme.inkBlack,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: [
              Tab(text: 'Saved Walks'),
              Tab(text: 'Trip Journal'),
              Tab(text: 'Preferences'),
              Tab(text: 'Practical Guide'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. Saved Walks
            _buildSavedWalksList(context, savedWalks),

            // 2. Trip Journal (carries across all cities in trip)
            _buildJournalList(journal),

            // 3. User Preferences (carries across all cities in trip)
            _buildPreferencesView(),

            // 4. Practical Germany & City Handbook
            _buildPracticalNotesList(filteredNotes),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedWalksList(BuildContext context, List<Walk> walks) {
    if (walks.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No saved walks yet. Tap the bookmark icon on any walk to save it for offline reference.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.mutedText),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: walks.length,
      itemBuilder: (ctx, idx) {
        final walk = walks[idx];
        final city = widget.state.repo.getCitySummary(walk.cityId);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.berlinBrick.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (city?.nameEn ?? walk.cityId).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.berlinBrick,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        walk.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.bookmark,
                          color: AppTheme.germanGold),
                      onPressed: () => widget.state.toggleSaveWalk(walk.id),
                    ),
                  ],
                ),
                Text('${walk.distanceKm} km • ~${walk.totalMinutesWithStops} min total'),
                const SizedBox(height: 2),
                Text('Start: ${walk.startTransit}',
                    style: TextStyle(
                        color: AppTheme.mutedText, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.state.startLiveWalk(walk);
                          widget.onStartLiveWalk();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Start Walk',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJournalList(List<JournalEntry> journal) {
    if (journal.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book, size: 48, color: AppTheme.mutedText),
              const SizedBox(height: 12),
              Text(
                'Your Trip Journal is Empty',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.inkBlack,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Completed walks and distance walked across all trip cities are logged here automatically. No account required.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.mutedText, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: journal.length,
      itemBuilder: (ctx, idx) {
        final entry = journal[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.forestGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.cityName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.walkTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.distanceKm.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Completed on ${entry.completedAt.day}/${entry.completedAt.month}/${entry.completedAt.year} • ${entry.stopsVisited} stops',
                  style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.warmCanvas,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note,
                          size: 16, color: AppTheme.mutedText),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry.notes,
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.inkBlack),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreferencesView() {
    final state = widget.state;
    final prefs = [
      {
        'key': 'step_free',
        'title': 'Step-Free / Accessible Routes',
        'desc': 'Prioritize level granite pathways, elevators, and curb ramps.'
      },
      {
        'key': 'rain_shelter',
        'title': 'Rain-Sheltered Corridors',
        'desc': 'Highlight museum colonnades and historic covered shopping passages.'
      },
      {
        'key': 'vegetarian',
        'title': 'Vegetarian Options',
        'desc': 'Highlight plant-based local bakeries and cafes along walk routes.'
      },
      {
        'key': 'gluten_free',
        'title': 'Gluten-Free Friendly',
        'desc': 'Filter for food pauses providing gluten-conscious menus.'
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Theme & Display Background Card
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      state.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: state.isDarkMode ? AppTheme.germanGold : AppTheme.inkBlack,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appearance & Background',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.inkBlack,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.isDarkMode
                                ? 'Dark background active (night walks & OLED battery saving)'
                                : 'Light background active (outdoor daylight & sunlight readability)',
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
                Row(
                  children: [
                    // Light Background Option
                    Expanded(
                      child: InkWell(
                        onTap: () => state.setDarkMode(false),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: !state.isDarkMode
                                ? AppTheme.inkBlack
                                : AppTheme.warmCanvas,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !state.isDarkMode
                                  ? AppTheme.inkBlack
                                  : AppTheme.borderOutline,
                              width: !state.isDarkMode ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wb_sunny,
                                size: 16,
                                color: !state.isDarkMode
                                    ? AppTheme.warmCanvas
                                    : AppTheme.inkBlack,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Light BG',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: !state.isDarkMode
                                      ? AppTheme.warmCanvas
                                      : AppTheme.inkBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Dark Background Option
                    Expanded(
                      child: InkWell(
                        onTap: () => state.setDarkMode(true),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: state.isDarkMode
                                ? AppTheme.inkBlack
                                : AppTheme.warmCanvas,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: state.isDarkMode
                                  ? AppTheme.germanGold
                                  : AppTheme.borderOutline,
                              width: state.isDarkMode ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.dark_mode,
                                size: 16,
                                color: state.isDarkMode
                                    ? AppTheme.germanGold
                                    : AppTheme.inkBlack,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Dark BG',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: state.isDarkMode
                                      ? AppTheme.warmCanvas
                                      : AppTheme.inkBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
              Icon(Icons.sync, size: 20, color: AppTheme.inkBlack),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Universal Trip Preferences',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.inkBlack,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your travel preferences carry across all cities in your multi-city trip (Berlin, Dresden, Leipzig, and future stops). Stored on-device with zero tracking.',
                      style: TextStyle(fontSize: 12, color: AppTheme.mutedText, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...prefs.map((p) {
          final isEnabled = state.hasPreference(p['key']!);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: SwitchListTile(
              value: isEnabled,
              activeTrackColor: AppTheme.forestGreen,
              onChanged: (_) => state.togglePreference(p['key']!),
              title: Text(
                p['title']!,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              subtitle: Text(
                p['desc']!,
                style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPracticalNotesList(List<PracticalNote> notes) {
    return Column(
      children: [
        // Topic filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _practicalChip('all', 'All Topics'),
              _practicalChip('closures', 'Closures'),
              _practicalChip('money_and_tipping', 'Cash & Tips'),
              _practicalChip('water_and_toilets', 'WC & Water'),
              _practicalChip('manners_and_language', 'German Phrases'),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (ctx, idx) {
              final note = notes[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note.shortText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        note.longerText,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.inkBlack,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Verified: ${note.lastVerified}',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.mutedText),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _practicalChip(String topic, String label) {
    final isSelected = _practicalFilter == topic;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (_) => setState(() => _practicalFilter = topic),
        selectedColor: AppTheme.inkBlack,
        backgroundColor: AppTheme.warmCanvas,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.inkBlack,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppTheme.inkBlack : AppTheme.borderOutline,
          ),
        ),
      ),
    );
  }
}