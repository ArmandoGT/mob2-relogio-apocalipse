class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.sourceName,
    required this.sourceUrl,
    required this.country,
    required this.severity,
    required this.publishedAt,
    required this.riskWeight,
    required this.keywords,
    required this.tone,
  });

  final String id;
  final String title;
  final String summary;
  final String sourceName;
  final String sourceUrl;
  final String country;
  final String severity;
  final DateTime publishedAt;
  final double riskWeight;
  final List<String> keywords;
  final double tone;

  bool get isCritical => severity == 'Crítico';
  bool get isModerate => severity == 'Moderado';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'sourceName': sourceName,
      'sourceUrl': sourceUrl,
      'country': country,
      'severity': severity,
      'publishedAt': publishedAt.toIso8601String(),
      'riskWeight': riskWeight,
      'keywords': keywords,
      'tone': tone,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Sem título',
      summary: map['summary']?.toString() ?? 'Sem resumo disponível.',
      sourceName: map['sourceName']?.toString() ?? 'Fonte não informada',
      sourceUrl: map['sourceUrl']?.toString() ?? '',
      country: map['country']?.toString() ?? 'Global',
      severity: map['severity']?.toString() ?? 'Baixo',
      publishedAt: DateTime.tryParse(map['publishedAt']?.toString() ?? '') ?? DateTime.now(),
      riskWeight: (map['riskWeight'] as num?)?.toDouble() ?? 1,
      keywords: (map['keywords'] as List?)?.map((item) => item.toString()).toList() ?? const [],
      tone: (map['tone'] as num?)?.toDouble() ?? 0,
    );
  }
}
