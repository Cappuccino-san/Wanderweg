import 'package:flutter/foundation.dart';
import '../models/city.dart';
import '../models/food_stop.dart';
import '../models/route_leg.dart';
import '../models/stop.dart';
import '../models/walk.dart';
import '../services/closure_engine.dart';
import '../services/pack_download_manager.dart';
import '../services/pack_repository.dart';
import '../ui/theme/app_theme.dart';

class JournalEntry {
  final String cityId;
  final String cityName;
  final String walkId;
  final String walkTitle;
  final DateTime completedAt;
  final double distanceKm;
  final int stopsVisited;
  String notes;

  JournalEntry({
    this.cityId = 'berlin',
    this.cityName = 'Berlin',
    required this.walkId,
    required this.walkTitle,
    required this.completedAt,
    required this.distanceKm,
    required this.stopsVisited,
    required this.notes,
  });
}

class EndEarlyInfo {
  final String stopName;
  final String nearestStation;
  final String directions;

  EndEarlyInfo({
    required this.stopName,
    required this.nearestStation,
    required this.directions,
  });
}

class AppState extends ChangeNotifier {
  final PackRepository repo = PackRepository();
  final PackDownloadManager packManager = PackDownloadManager();

  bool _isAirplaneMode = false;
  bool get isAirplaneMode => _isAirplaneMode;

  bool _isWifiConnected = true;
  bool get isWifiConnected => _isWifiConnected && !_isAirplaneMode;

  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  void setDarkMode(bool enabled) {
    if (_isDarkMode != enabled) {
      _isDarkMode = enabled;
      AppTheme.isDark = enabled;
      notifyListeners();
    }
  }

  void toggleDarkMode() {
    setDarkMode(!_isDarkMode);
  }

  void setAirplaneMode(bool enabled) {
    _isAirplaneMode = enabled;
    notifyListeners();
  }

  void setWifiConnected(bool connected) {
    _isWifiConnected = connected;
    notifyListeners();
  }

  // --- Country & Trip Planner State ---
  String _selectedCountryId = 'de';
  String get selectedCountryId => _selectedCountryId;

  Country? get selectedCountry {
    return repo.countries.where((c) => c.id == _selectedCountryId).firstOrNull ??
        repo.countries.firstOrNull;
  }

  // Ordered list of cities in current multi-city trip
  List<String> _tripCityIds = ['berlin', 'dresden', 'leipzig'];
  List<String> get tripCityIds => List.unmodifiable(_tripCityIds);

  List<CitySummary> get tripCities {
    return _tripCityIds
        .map((id) => repo.getCitySummary(id))
        .whereType<CitySummary>()
        .toList();
  }

  String _activeCityId = 'berlin';
  String get activeCityId => _activeCityId;

  CitySummary? get activeCitySummary => repo.getCitySummary(_activeCityId);
  CityPackMeta? get activeCityMeta => repo.getCityMeta(_activeCityId);

  final Map<String, int> _stayDays = {
    'berlin': 1,
    'dresden': 1,
    'leipzig': 1,
  };

  int getStayDays(String cityId) => _stayDays[cityId] ?? 1;

  int get totalTripDays {
    return _tripCityIds.fold(0, (sum, id) => sum + getStayDays(id));
  }

  // Overall day index of the active city in the trip
  int get activeCityTripStartDay {
    int day = 1;
    for (final id in _tripCityIds) {
      if (id == _activeCityId) break;
      day += getStayDays(id);
    }
    return day;
  }

  // Selected walk
  Walk? _selectedWalk;
  Walk? get selectedWalk => _selectedWalk;

  // Selected date & start hour for Today planning
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  int _todayStartHour = 10;
  int get todayStartHour => _todayStartHour;

  // Cross-city user preferences
  final Set<String> _userPreferences = {'step_free'};
  Set<String> get userPreferences => Set.unmodifiable(_userPreferences);

  void togglePreference(String prefKey) {
    if (_userPreferences.contains(prefKey)) {
      _userPreferences.remove(prefKey);
    } else {
      _userPreferences.add(prefKey);
    }
    notifyListeners();
  }

  bool hasPreference(String prefKey) => _userPreferences.contains(prefKey);

  // Live walk state
  bool _isLiveWalking = false;
  bool get isLiveWalking => _isLiveWalking;

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  int _currentStopIndex = 0;
  int get currentStopIndex => _currentStopIndex;

  int _currentLegIndex = 0;
  int get currentLegIndex => _currentLegIndex;

  final Set<String> _completedStopIds = {};
  Set<String> get completedStopIds => _completedStopIds;

  bool _isOffRoute = false;
  bool get isOffRoute => _isOffRoute;

  // Saved walks and journal (persists across all cities in trip)
  final Set<String> _savedWalkIds = {'berlin-mitte-essentials'};
  Set<String> get savedWalkIds => _savedWalkIds;

  final List<JournalEntry> _journal = [];
  List<JournalEntry> get journal => List.unmodifiable(_journal);

  Future<void> initialize() async {
    packManager.addListener(notifyListeners);
    await repo.init();

    // Initialize trip planner from manifest default country
    if (repo.countries.isNotEmpty) {
      final defaultCountry = repo.countries.first;
      _selectedCountryId = defaultCountry.id;
      final availableCityIds = defaultCountry.cities.map((c) => c.id).toList();
      if (availableCityIds.isNotEmpty) {
        _tripCityIds = availableCityIds;
        _activeCityId = _tripCityIds.first;
      }
    }

    final cityWalks = repo.getWalksForCity(_activeCityId);
    if (cityWalks.isNotEmpty) {
      _selectedWalk = cityWalks.first;
    } else if (repo.walks.isNotEmpty) {
      _selectedWalk = repo.walks.first;
    }
    notifyListeners();
  }

  // --- Trip Planner Operations ---
  void selectCountry(String countryId) {
    if (_selectedCountryId != countryId) {
      _selectedCountryId = countryId;
      final country = repo.countries.where((c) => c.id == countryId).firstOrNull;
      if (country != null && country.cities.isNotEmpty) {
        _tripCityIds = country.cities.map((c) => c.id).toList();
        _activeCityId = _tripCityIds.first;
        final walks = repo.getWalksForCity(_activeCityId);
        _selectedWalk = walks.isNotEmpty ? walks.first : null;
      }
      notifyListeners();
    }
  }

  void addCityToTrip(String cityId) {
    if (!_tripCityIds.contains(cityId)) {
      _tripCityIds.add(cityId);
      if (!_stayDays.containsKey(cityId)) {
        _stayDays[cityId] = 1;
      }
      notifyListeners();
    }
  }

  void removeCityFromTrip(String cityId) {
    if (_tripCityIds.length > 1 && _tripCityIds.contains(cityId)) {
      _tripCityIds.remove(cityId);
      if (_activeCityId == cityId) {
        _activeCityId = _tripCityIds.first;
        final walks = repo.getWalksForCity(_activeCityId);
        _selectedWalk = walks.isNotEmpty ? walks.first : null;
      }
      notifyListeners();
    }
  }

  void moveCityInTrip(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _tripCityIds.length) return;
    if (newIndex < 0 || newIndex >= _tripCityIds.length) return;
    final item = _tripCityIds.removeAt(oldIndex);
    _tripCityIds.insert(newIndex, item);
    notifyListeners();
  }

  void setActiveCity(String cityId) {
    if (_activeCityId != cityId) {
      _activeCityId = cityId;
      final cityWalks = repo.getWalksForCity(cityId);
      if (cityWalks.isNotEmpty) {
        _selectedWalk = cityWalks.first;
      } else {
        _selectedWalk = null;
      }
      _isLiveWalking = false;
      _completedStopIds.clear();
      notifyListeners();
    }
  }

  void nextCityInTrip() {
    final idx = _tripCityIds.indexOf(_activeCityId);
    if (idx != -1 && idx < _tripCityIds.length - 1) {
      setActiveCity(_tripCityIds[idx + 1]);
    }
  }

  void previousCityInTrip() {
    final idx = _tripCityIds.indexOf(_activeCityId);
    if (idx > 0) {
      setActiveCity(_tripCityIds[idx - 1]);
    }
  }

  void setStayDays(String cityId, int days) {
    if (days >= 1 && days <= 7) {
      _stayDays[cityId] = days;
      notifyListeners();
    }
  }

  void selectWalk(Walk walk) {
    _selectedWalk = walk;
    if (_activeCityId != walk.cityId) {
      _activeCityId = walk.cityId;
    }
    notifyListeners();
  }

  void setTodayStartHour(int hour) {
    _todayStartHour = hour;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void toggleSaveWalk(String walkId) {
    if (_savedWalkIds.contains(walkId)) {
      _savedWalkIds.remove(walkId);
    } else {
      _savedWalkIds.add(walkId);
    }
    notifyListeners();
  }

  bool isWalkSaved(String walkId) => _savedWalkIds.contains(walkId);

  // --- Dynamic Sizing Itinerary Logic (All Cities) ---
  List<Walk> getProposedWalksForStay() {
    final cityWalks = repo.getWalksForCity(_activeCityId);
    if (cityWalks.isEmpty) return [];

    final days = getStayDays(_activeCityId);
    if (days == 1) {
      // 1 day default: exactly 1 primary core walk
      final core = cityWalks.where((w) => w.priorityTier == 'core').toList();
      return core.isNotEmpty ? [core.first] : [cityWalks.first];
    } else if (days == 2) {
      // 2 days: both core walks or core + extension across 2 days
      final coreAndExt = cityWalks
          .where((w) => w.priorityTier == 'core' || w.priorityTier == 'extension')
          .take(2)
          .toList();
      return coreAndExt.isNotEmpty ? coreAndExt : cityWalks.take(2).toList();
    } else {
      // 3+ days: full pack unlocked for the city
      return cityWalks;
    }
  }

  List<ClosureWarning> getTodayClosureWarnings() {
    if (_selectedWalk == null) return [];
    final walkStops = _selectedWalk!.stops
        .map((id) => repo.getStop(id))
        .whereType<Stop>()
        .toList();
    final walkFoods = _selectedWalk!.foodPositions
        .map((fp) => repo.getFoodStop(fp.foodStopId))
        .whereType<FoodStop>()
        .toList();

    return ClosureEngine.evaluateWalk(
      walk: _selectedWalk!,
      stops: walkStops,
      foodStops: walkFoods,
      walkDate: _selectedDate,
      startHour: _todayStartHour,
    );
  }

  // --- Live Walking Actions ---
  void startLiveWalk(Walk walk) {
    _selectedWalk = walk;
    if (_activeCityId != walk.cityId) {
      _activeCityId = walk.cityId;
    }
    _isLiveWalking = true;
    _isPaused = false;
    _currentStopIndex = 0;
    _currentLegIndex = 0;
    _completedStopIds.clear();
    _isOffRoute = false;
    notifyListeners();
  }

  void pauseWalk() {
    _isPaused = true;
    notifyListeners();
  }

  void resumeWalk() {
    _isPaused = false;
    notifyListeners();
  }

  void skipStop() {
    if (_selectedWalk == null) return;
    if (_currentStopIndex < _selectedWalk!.stops.length - 1) {
      _currentStopIndex++;
      _currentLegIndex = _currentStopIndex;
      notifyListeners();
    }
  }

  bool advanceToNextStop() {
    if (_selectedWalk == null) return false;
    final currentId = _selectedWalk!.stops[_currentStopIndex];
    _completedStopIds.add(currentId);

    if (_currentStopIndex < _selectedWalk!.stops.length - 1) {
      _currentStopIndex++;
      _currentLegIndex = _currentStopIndex;
      notifyListeners();
      return false; // not finished yet
    } else {
      finishWalk();
      return true; // completed walk
    }
  }

  void simulateDriftOffRoute() {
    _isOffRoute = true;
    notifyListeners();
  }

  void rejoinWalk() {
    _isOffRoute = false;
    notifyListeners();
  }

  void makeThisTheRoute() {
    _isOffRoute = false;
    notifyListeners();
  }

  EndEarlyInfo getEndEarlyInfo() {
    final current = currentStop;
    final walk = _selectedWalk;

    String stopName = current?.nameEn ?? 'Current Location';
    String nearestStation = 'Nearest transit station';

    if (walk != null && current != null) {
      if (walk.nearestStationsByStop.containsKey(current.id)) {
        nearestStation = walk.nearestStationsByStop[current.id]!;
      } else {
        nearestStation = walk.endTransit;
      }
    }

    final transitName = activeCityMeta?.transitSummary.split('.').first ?? 'public transit';

    return EndEarlyInfo(
      stopName: stopName,
      nearestStation: nearestStation,
      directions:
          'Follow the posted signs toward $nearestStation ($transitName). Validate your paper ticket before boarding.',
    );
  }

  void endWalkEarly() {
    if (_selectedWalk != null) {
      final visitedCount = _completedStopIds.length;
      final dist = (_selectedWalk!.distanceKm *
          ((_currentStopIndex + 1) / _selectedWalk!.stops.length));
      final cityName = activeCitySummary?.nameEn ?? _activeCityId.toUpperCase();
      _journal.add(
        JournalEntry(
          cityId: _activeCityId,
          cityName: cityName,
          walkId: _selectedWalk!.id,
          walkTitle: _selectedWalk!.title,
          completedAt: DateTime.now(),
          distanceKm: dist,
          stopsVisited: visitedCount,
          notes: 'Ended early in $cityName toward ${getEndEarlyInfo().nearestStation}.',
        ),
      );
    }
    _isLiveWalking = false;
    _isPaused = false;
    notifyListeners();
  }

  void finishWalk() {
    if (_selectedWalk != null) {
      final cityName = activeCitySummary?.nameEn ?? _activeCityId.toUpperCase();
      _journal.add(
        JournalEntry(
          cityId: _activeCityId,
          cityName: cityName,
          walkId: _selectedWalk!.id,
          walkTitle: _selectedWalk!.title,
          completedAt: DateTime.now(),
          distanceKm: _selectedWalk!.distanceKm,
          stopsVisited: _selectedWalk!.stops.length,
          notes: 'Completed full walk in $cityName.',
        ),
      );
    }
    _isLiveWalking = false;
    _isPaused = false;
    notifyListeners();
  }

  void addCustomJournalNote(int index, String note) {
    if (index >= 0 && index < _journal.length) {
      _journal[index].notes = note;
      notifyListeners();
    }
  }

  Stop? get currentStop {
    if (_selectedWalk == null || _selectedWalk!.stops.isEmpty) return null;
    if (_currentStopIndex < _selectedWalk!.stops.length) {
      return repo.getStop(_selectedWalk!.stops[_currentStopIndex]);
    }
    return null;
  }

  RouteLeg? get currentLeg {
    if (_selectedWalk == null ||
        _currentStopIndex >= _selectedWalk!.stops.length - 1) {
      return null;
    }
    final fromId = _selectedWalk!.stops[_currentStopIndex];
    final toId = _selectedWalk!.stops[_currentStopIndex + 1];
    return repo.getLeg(fromId, toId);
  }

  FoodStop? get upcomingFoodStop {
    if (_selectedWalk == null) return null;
    if (_currentStopIndex < _selectedWalk!.stops.length) {
      final currentId = _selectedWalk!.stops[_currentStopIndex];
      final pos = _selectedWalk!.foodPositions.where(
        (fp) => fp.afterStopId == currentId,
      ).firstOrNull;
      if (pos != null) {
        return repo.getFoodStop(pos.foodStopId);
      }
    }
    return null;
  }
}
