import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/event_model.dart';

class ApiService {
  static const _baseUrl = 'https://api.gdeltproject.org/api/v2/doc/doc';
  static const List<String> _criticalKeywords = <String>[
    'nuclear',
    'missile',
    'invasion',
    'chemical',
    'mobilization',
    'war',
    'attack',
    'sanction',
    'retaliation',
  ];
  static const List<String> _moderateKeywords = <String>[
    'conflict',
    'troops',
    'military',
    'border',
    'ceasefire',
    'summit',
    'security',
    'protest',
    'drone',
  ];

  Future<List<EventModel>> fetchRecentEvents() async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: <String, String>{
        'query': '(war OR conflict OR missile OR sanctions OR invasion OR military OR nuclear)',
        'mode': 'artlist',
        'maxrecords': '50',
        'timespan': '48h',
        'format': 'json',
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode == 429) {
        throw const ApiServiceException(
          'O GDELT limitou a consulta agora. Tente atualizar em alguns instantes.',
        );
      }

      if (response.statusCode >= 400) {
        throw ApiServiceException(
          'Falha ao consultar eventos internacionais. Código ${response.statusCode}.',
        );
      }

      final body = jsonDecode(response.body);
      final items = _extractArticles(body);

      return items
          .map((item) => _mapArticle(item as Map<String, dynamic>))
          .where((event) => event.title.trim().isNotEmpty)
          .toList();
    } on SocketException {
      throw const ApiServiceException(
        'Sem conexão com a internet para consultar os eventos.',
      );
    } on HttpException {
      throw const ApiServiceException(
        'Erro HTTP ao consultar o GDELT.',
      );
    } on FormatException {
      throw const ApiServiceException(
        'A resposta da API veio em um formato inesperado.',
      );
    } on ApiServiceException {
      rethrow;
    } catch (_) {
      throw const ApiServiceException(
        'Não foi possível carregar os eventos internacionais agora.',
      );
    }
  }

  List<dynamic> _extractArticles(dynamic body) {
    if (body is Map<String, dynamic>) {
      for (final key in <String>['articles', 'Articles', 'results']) {
        final value = body[key];
        if (value is List) {
          return value;
        }
      }
    }

    return const [];
  }

  EventModel _mapArticle(Map<String, dynamic> item) {
    final title = (item['title'] ?? '').toString().trim();
    final summary = (item['seendate'] ?? item['snippet'] ?? item['excerpt'] ?? '')
        .toString()
        .trim();
    final sourceUrl = (item['url'] ?? '').toString();
    final sourceName = (item['domain'] ?? item['source'] ?? 'Fonte internacional').toString();
    final country = (item['sourcecountry'] ?? 'Global').toString();
    final publishedAt = _parseDate(item['seendate']?.toString());
    final severity = _classifySeverity('$title $summary');
    final riskWeight = switch (severity) {
      'Crítico' => 3.0,
      'Moderado' => 2.0,
      _ => 1.0,
    };

    return EventModel(
      id: sourceUrl.isEmpty ? '$title-${publishedAt.toIso8601String()}' : sourceUrl,
      title: title,
      summary: summary.isEmpty ? 'Cobertura recente detectada pelo monitor internacional.' : summary,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      country: country.isEmpty ? 'Global' : country,
      severity: severity,
      publishedAt: publishedAt,
      riskWeight: riskWeight,
      keywords: _collectKeywords('$title $summary'),
      tone: (item['tone'] as num?)?.toDouble() ?? 0,
    );
  }

  DateTime _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return DateTime.now();
    }

    final normalized = raw.trim();
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return parsed.toLocal();
    }

    if (normalized.length >= 14) {
      final compact = '${normalized.substring(0, 4)}-${normalized.substring(4, 6)}-${normalized.substring(6, 8)}T${normalized.substring(8, 10)}:${normalized.substring(10, 12)}:${normalized.substring(12, 14)}Z';
      return DateTime.tryParse(compact)?.toLocal() ?? DateTime.now();
    }

    return DateTime.now();
  }

  String _classifySeverity(String text) {
    final normalized = text.toLowerCase();

    if (_criticalKeywords.any(normalized.contains)) {
      return 'Crítico';
    }

    if (_moderateKeywords.any(normalized.contains)) {
      return 'Moderado';
    }

    return 'Baixo';
  }

  List<String> _collectKeywords(String text) {
    final normalized = text.toLowerCase();
    return <String>{
      ..._criticalKeywords.where(normalized.contains),
      ..._moderateKeywords.where(normalized.contains),
    }.toList();
  }
}

class ApiServiceException implements Exception {
  const ApiServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
