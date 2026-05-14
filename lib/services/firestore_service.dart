import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_model.dart';
import '../models/user_preferences_model.dart';
import 'auth_service.dart';

class FirestoreService {
  FirestoreService({required bool firebaseEnabled}) : _firebaseEnabled = firebaseEnabled;

  final bool _firebaseEnabled;

  bool get isConfigured => _firebaseEnabled;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Stream<List<EventModel>> watchFavorites(String uid) {
    if (!_firebaseEnabled || uid.isEmpty) {
      return Stream<List<EventModel>>.value(const []);
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<bool> isFavorite({
    required String uid,
    required String eventId,
  }) async {
    if (!_firebaseEnabled || uid.isEmpty || eventId.isEmpty) {
      return false;
    }

    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(eventId)
        .get();

    return doc.exists;
  }

  Future<void> toggleFavorite({
    required String uid,
    required EventModel event,
  }) async {
    _ensureConfigured();

    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(event.id);

    final snapshot = await ref.get();

    if (snapshot.exists) {
      await ref.delete();
      return;
    }

    await ref.set(event.toMap());
  }

  Future<void> saveQueryHistory({
    required String uid,
    required String countryFilter,
    required String severityFilter,
    required int resultCount,
  }) async {
    if (!_firebaseEnabled || uid.isEmpty) {
      return;
    }

    await _firestore.collection('users').doc(uid).collection('history').add({
      'countryFilter': countryFilter,
      'severityFilter': severityFilter,
      'resultCount': resultCount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserPreferencesModel> loadPreferences(String uid) async {
    if (!_firebaseEnabled || uid.isEmpty) {
      return UserPreferencesModel.initial(uid);
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('profile')
        .get();

    if (!snapshot.exists) {
      return UserPreferencesModel.initial(uid);
    }

    return UserPreferencesModel.fromMap(snapshot.data() ?? <String, dynamic>{});
  }

  Future<void> savePreferences(UserPreferencesModel preferences) async {
    if (!_firebaseEnabled || preferences.uid.isEmpty) {
      return;
    }

    await _firestore
        .collection('users')
        .doc(preferences.uid)
        .collection('preferences')
        .doc('profile')
        .set(preferences.toMap());
  }

  void _ensureConfigured() {
    if (_firebaseEnabled) {
      return;
    }

    throw const FirebaseSetupException(
      'O serviço de persistência não está disponível no ambiente atual.'
    );
  }
}
