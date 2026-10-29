import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderweg/state/app_state.dart';
import 'package:wanderweg/ui/tabs/saved_tab.dart';
import 'package:wanderweg/ui/tabs/today_tab.dart';
import 'package:wanderweg/ui/theme/app_theme.dart';

void main() {
  group('Light & Dark Background Theme Support', () {
    test('AppState defaults to dark background (Moon) and switches to light cleanly', () {
      final state = AppState();
      expect(state.isDarkMode, isTrue);
      expect(AppTheme.isDark, isTrue);

      // Verify dark palette values
      expect(AppTheme.warmCanvas, const Color(0xFF101418));
      expect(AppTheme.cardSurface, const Color(0xFF192027));
      expect(AppTheme.inkBlack, const Color(0xFFF2F5F8));

      // Toggle to light mode
      state.toggleDarkMode();
      expect(state.isDarkMode, isFalse);
      expect(AppTheme.isDark, isFalse);

      // Verify light palette values
      expect(AppTheme.warmCanvas, const Color(0xFFF7F8FA));
      expect(AppTheme.cardSurface, const Color(0xFFFFFFFF));
      expect(AppTheme.inkBlack, const Color(0xFF111418));

      // Toggle back to dark mode
      state.setDarkMode(true);
      expect(state.isDarkMode, isTrue);
      expect(AppTheme.isDark, isTrue);
      expect(AppTheme.warmCanvas, const Color(0xFF101418));
    });

    testWidgets('SavedTab displays Appearance & Background options and toggles theme',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      await state.initialize();
      state.setDarkMode(false);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: Scaffold(
            body: ListenableBuilder(
              listenable: state,
              builder: (context, _) => SavedTab(
                state: state,
                onStartLiveWalk: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Preferences tab (index 2)
      final prefsTabFinder = find.text('Preferences');
      expect(prefsTabFinder, findsOneWidget);
      await tester.tap(prefsTabFinder);
      await tester.pumpAndSettle();

      // Verify Appearance & Background card renders
      expect(find.text('Appearance & Background'), findsOneWidget);
      expect(find.text('Light BG'), findsOneWidget);
      expect(find.text('Dark BG'), findsOneWidget);

      // Tap Dark BG chip
      await tester.tap(find.text('Dark BG'));
      await tester.pumpAndSettle();

      expect(state.isDarkMode, isTrue);
      expect(AppTheme.isDark, isTrue);
      expect(find.text('Dark background active (night walks & OLED battery saving)'), findsOneWidget);

      // Tap Light BG chip
      await tester.tap(find.text('Light BG'));
      await tester.pumpAndSettle();

      expect(state.isDarkMode, isFalse);
      expect(AppTheme.isDark, isFalse);
      expect(find.text('Light background active (outdoor daylight & sunlight readability)'), findsOneWidget);
    });

    testWidgets('AppBar quick-toggle icon toggles light and dark theme mode',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      await state.initialize();
      expect(state.isDarkMode, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: Scaffold(
            body: ListenableBuilder(
              listenable: state,
              builder: (context, _) => TodayTab(
                state: state,
                onStartLiveWalk: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Since default is Dark (Moon), quick-toggle in AppBar initially offers switch to Light
      final lightToggleFinder = find.byTooltip('Switch to Light Background');
      expect(lightToggleFinder, findsOneWidget);

      // Tap quick toggle to switch to Light Background
      await tester.tap(lightToggleFinder);
      await tester.pumpAndSettle();

      expect(state.isDarkMode, isFalse);
      expect(AppTheme.isDark, isFalse);

      // Verify tooltip updated to Dark Background
      final darkToggleFinder = find.byTooltip('Switch to Dark Background');
      expect(darkToggleFinder, findsOneWidget);

      // Tap again to switch back to Dark (Moon)
      await tester.tap(darkToggleFinder);
      await tester.pumpAndSettle();

      expect(state.isDarkMode, isTrue);
      expect(AppTheme.isDark, isTrue);
    });
  });
}
