import 'package:flutter/foundation.dart';

import '../models/event_model.dart';
import '../models/user_preferences_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'score_controller.dart';

class EventController extends ChangeNotifier {
  EventController({
    required ApiService apiService,
    required FirestoreService firestoreService,
    required AuthService authService,
    required ScoreController scoreController,
  })  : _apiService = apiService,
        _firestoreService = firestoreService,
        _authService = authService,
        _scoreController = scoreController;

  ApiService _apiService;
  FirestoreService _firestoreService;
  AuthService _authService;
  ScoreController _scoreController;

  List<EventModel> _allEvents = const [];
  List<EventModel> _filteredEvents = const [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;
  String _selectedCountry = 'Todos';
  String _selectedSeverity = 'Todos';

  List<EventModel> get events => _filteredEvents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;
  String get selectedCountry => _selectedCountry;
  String get selectedSeverity => _selectedSeverity;
  bool get isFirebaseReady => _firestoreService.isConfigured;
  bool get hasUserSession => _authService.currentUser != null;

  List<String> get availableCountries {
    final countries = _allEvents.map((event) => event.country).toSet().toList()..sort();
    return <String>['Todos', ...countries];
  }

  List<String> get availableSeverities => const <String>['Todos', 'Crítico', 'Moderado', 'Baixo'];

  EventController updateDependencies({
    required ApiService apiService,
    required FirestoreService firestoreService,
    required AuthService authService,
    required ScoreController scoreController,
  }) {
    _apiService = apiService;
    _firestoreService = firestoreService;
    _authService = authService;
    _scoreController = scoreController;
    return this;
  }

  Future<void> fetchEvents() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final events = await _apiService.fetchRecentEvents();
      _allEvents = events;
      await _restorePreferencesIfPossible();
      _applyFilters(persist: false);
      _lastUpdated = DateTime.now();
      await _persistQueryHistory();
    } catch (error) {
      _errorMessage = error.toString();
      _allEvents = const [];
      _filteredEvents = const [];
      _scoreController.updateWithEvents(const []);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setCountryFilter(String? value) async {
    _selectedCountry = value ?? 'Todos';
    await _applyFilters();
  }

  Future<void> setSeverityFilter(String? value) async {
    _selectedSeverity = value ?? 'Todos';
    await _applyFilters();
  }

  Future<void> clearFilters() async {
    _selectedCountry = 'Todos';
    _selectedSeverity = 'Todos';
    await _applyFilters();
  }

  Future<void> toggleFavorite(EventModel event) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      throw StateError('Faça login para salvar favoritos.');
    }

    await _firestoreService.toggleFavorite(uid: uid, event: event);
    notifyListeners();
  }

  Future<bool> isFavorite(String eventId) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return false;
    }

    return _firestoreService.isFavorite(uid: uid, eventId: eventId);
  }

  Stream<List<EventModel>> get favoritesStream {
    final uid = _authService.currentUser?.uid ?? '';
    return _firestoreService.watchFavorites(uid);
  }

  Future<void> _applyFilters({bool persist = true}) async {
    _filteredEvents = _allEvents.where((event) {
      final countryMatch = _selectedCountry == 'Todos' || event.country == _selectedCountry;
      final severityMatch = _selectedSeverity == 'Todos' || event.severity == _selectedSeverity;
      return countryMatch && severityMatch;
    }).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    _scoreController.updateWithEvents(_filteredEvents);

    if (persist) {
      await _persistPreferences();
      await _persistQueryHistory();
    }

    notifyListeners();
  }

  Future<void> _restorePreferencesIfPossible() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final preferences = await _firestoreService.loadPreferences(uid);
    _selectedCountry = preferences.countryFilter;
    _selectedSeverity = preferences.severityFilter;
  }

  Future<void> _persistPreferences() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return;
    }

    await _firestoreService.savePreferences(
      UserPreferencesModel(
        uid: uid,
        countryFilter: _selectedCountry,
        severityFilter: _selectedSeverity,
        windowHours: 48,
      ),
    );
  }

  Future<void> _persistQueryHistory() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return;
    }

    await _firestoreService.saveQueryHistory(
      uid: uid,
      countryFilter: _selectedCountry,
      severityFilter: _selectedSeverity,
      resultCount: _filteredEvents.length,
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
