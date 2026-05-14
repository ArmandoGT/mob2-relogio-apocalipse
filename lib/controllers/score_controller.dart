import 'package:flutter/material.dart';

import '../models/event_model.dart';

class ScoreController extends ChangeNotifier {
  ScoreResult _result = ScoreResult.empty();

  ScoreResult get result => _result;

  void updateWithEvents(List<EventModel> events) {
    final critical = events.where((event) => event.severity == 'Crítico').toList();
    final moderate = events.where((event) => event.severity == 'Moderado').toList();
    final low = events.where((event) => event.severity == 'Baixo').toList();
    final now = DateTime.now();
    final recentCritical = critical
        .where((event) => now.difference(event.publishedAt).inHours <= 12)
        .length;

    final rawScore = (critical.length * 3) +
        (moderate.length * 2) +
        low.length +
        (recentCritical * 2);
    final score = (rawScore * 4).clamp(0, 100);

    _result = ScoreResult(
      score: score,
      status: _statusForScore(score),
      color: _colorForScore(score),
      formula:
          'Score bruto = (críticos × 3) + (moderados × 2) + (baixos × 1) + (críticos nas últimas 12h × 2). Score final = mínimo(100, score bruto × 4).',
      breakdown: <ScoreBreakdownItem>[
        ScoreBreakdownItem(label: 'Eventos críticos', value: critical.length, impact: critical.length * 3),
        ScoreBreakdownItem(label: 'Eventos moderados', value: moderate.length, impact: moderate.length * 2),
        ScoreBreakdownItem(label: 'Eventos baixos', value: low.length, impact: low.length),
        ScoreBreakdownItem(label: 'Críticos nas últimas 12h', value: recentCritical, impact: recentCritical * 2),
      ],
    );

    notifyListeners();
  }

  String _statusForScore(int score) {
    if (score <= 20) return 'Baixo';
    if (score <= 40) return 'Moderado';
    if (score <= 60) return 'Alto';
    if (score <= 80) return 'Muito alto';
    return 'Crítico';
  }

  Color _colorForScore(int score) {
    if (score <= 20) return const Color(0xFF2E7D32);
    if (score <= 40) return const Color(0xFFF9A825);
    if (score <= 60) return const Color(0xFFF57C00);
    if (score <= 80) return const Color(0xFFD84315);
    return const Color(0xFFC62828);
  }
}

class ScoreResult {
  const ScoreResult({
    required this.score,
    required this.status,
    required this.color,
    required this.formula,
    required this.breakdown,
  });

  final int score;
  final String status;
  final Color color;
  final String formula;
  final List<ScoreBreakdownItem> breakdown;

  factory ScoreResult.empty() {
    return const ScoreResult(
      score: 0,
      status: 'Baixo',
      color: Color(0xFF2E7D32),
      formula: 'Ainda não há eventos suficientes para calcular o score.',
      breakdown: <ScoreBreakdownItem>[],
    );
  }
}

class ScoreBreakdownItem {
  const ScoreBreakdownItem({
    required this.label,
    required this.value,
    required this.impact,
  });

  final String label;
  final int value;
  final int impact;
}
