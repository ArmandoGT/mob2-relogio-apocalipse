class UserPreferencesModel {
  const UserPreferencesModel({
    required this.uid,
    required this.countryFilter,
    required this.severityFilter,
    required this.windowHours,
  });

  final String uid;
  final String countryFilter;
  final String severityFilter;
  final int windowHours;

  factory UserPreferencesModel.initial(String uid) {
    return UserPreferencesModel(
      uid: uid,
      countryFilter: 'Todos',
      severityFilter: 'Todos',
      windowHours: 48,
    );
  }

  UserPreferencesModel copyWith({
    String? countryFilter,
    String? severityFilter,
    int? windowHours,
  }) {
    return UserPreferencesModel(
      uid: uid,
      countryFilter: countryFilter ?? this.countryFilter,
      severityFilter: severityFilter ?? this.severityFilter,
      windowHours: windowHours ?? this.windowHours,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'countryFilter': countryFilter,
      'severityFilter': severityFilter,
      'windowHours': windowHours,
    };
  }

  factory UserPreferencesModel.fromMap(Map<String, dynamic> map) {
    return UserPreferencesModel(
      uid: map['uid']?.toString() ?? '',
      countryFilter: map['countryFilter']?.toString() ?? 'Todos',
      severityFilter: map['severityFilter']?.toString() ?? 'Todos',
      windowHours: (map['windowHours'] as num?)?.toInt() ?? 48,
    );
  }
}
