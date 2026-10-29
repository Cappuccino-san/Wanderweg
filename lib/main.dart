import 'package:flutter/material.dart';
import 'state/app_state.dart';
import 'ui/tabs/cities_tab.dart';
import 'ui/tabs/map_tab.dart';
import 'ui/tabs/saved_tab.dart';
import 'ui/tabs/today_tab.dart';
import 'ui/tabs/walks_tab.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.initialize();
  runApp(WanderwegApp(appState: appState));
}

class WanderwegApp extends StatefulWidget {
  final AppState appState;
  final bool enableMapTileNetwork;

  const WanderwegApp({
    super.key,
    required this.appState,
    this.enableMapTileNetwork = true,
  });

  @override
  State<WanderwegApp> createState() => _WanderwegAppState();
}

class _WanderwegAppState extends State<WanderwegApp> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _switchToTab(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.appState;

    final tabs = [
      TodayTab(
        state: state,
        onStartLiveWalk: () => _switchToTab(3), // Switch to Map
      ),
      CitiesTab(state: state),
      WalksTab(
        state: state,
        onStartLiveWalk: () => _switchToTab(3), // Switch to Map
        onNavigateToMap: () => _switchToTab(3), // Switch to Map
      ),
      MapTab(state: state, enableTileNetwork: widget.enableMapTileNetwork),
      SavedTab(
        state: state,
        onStartLiveWalk: () => _switchToTab(3), // Switch to Map
      ),
    ];

    return MaterialApp(
      title: 'Wanderweg — Germany Tour Guide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: IndexedStack(
          index: _currentTabIndex,
          children: tabs,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: _switchToTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.wb_sunny_outlined),
              activeIcon: Icon(Icons.wb_sunny),
              label: 'Today',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_city_outlined),
              activeIcon: Icon(Icons.location_city),
              label: 'Cities',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_walk_outlined),
              activeIcon: Icon(Icons.directions_walk),
              label: 'Walks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline),
              activeIcon: Icon(Icons.bookmark),
              label: 'Saved',
            ),
          ],
        ),
      ),
    );
  }
}
