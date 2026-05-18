import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/event_model.dart';

class ApiService {
  // ── Currents API ──────────────────────────────────────────────────────
  // Documentação: https://currentsapi.services/en/docs/
  // Plano gratuito: 1 000 requisições/dia, sem restrição de ambiente.
  // Registre-se em https://currentsapi.services/en/register para obter
  // a sua chave e cole abaixo.
  static const _apiKey = 'OYbqXRl4bMGiZv2EJVkZn2k9VWw3L7BcmP4pLf1nXO47UkYn';
  static const _baseUrl = 'https://api.currentsapi.services/v1/search';

  // ── Palavras-chave para classificação de severidade ───────────────────
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

  /// Busca eventos internacionais recentes relacionados a crises e conflitos.
  Future<List<EventModel>> fetchRecentEvents() async {
    // Janela de 48 horas para trás
    final now = DateTime.now().toUtc();
    final from = now.subtract(const Duration(hours: 48));

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: <String, String>{
        'keywords':
            'war OR conflict OR missile OR sanctions OR invasion OR military OR nuclear',
        'language': 'en',
        'start_date': from.toIso8601String(),
        'end_date': now.toIso8601String(),
        'page_size': '50',
        'apiKey': _apiKey,
      },
    );

    try {
      final response = await http.get(uri).timeout(
            const Duration(seconds: 20),
          );

      if (response.statusCode == 401) {
        throw const ApiServiceException(
          'Chave da API inválida. Verifique a configuração da Currents API.',
        );
      }

      if (response.statusCode == 429) {
        throw const ApiServiceException(
          'Limite de requisições atingido. Tente atualizar em alguns instantes.',
        );
      }

      if (response.statusCode >= 400) {
        throw ApiServiceException(
          'Falha ao consultar eventos internacionais. Código ${response.statusCode}.',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      // A Currents API retorna { "status": "ok", "news": [...] }
      if (body['status'] != 'ok') {
        throw const ApiServiceException(
          'A API retornou um status inesperado. Tente novamente.',
        );
      }

      final items = (body['news'] as List?) ?? const [];

      return items
          .cast<Map<String, dynamic>>()
          .map(_mapArticle)
          .where((event) => event.title.trim().isNotEmpty)
          .toList();
    } on SocketException {
      throw const ApiServiceException(
        'Sem conexão com a internet para consultar os eventos.',
      );
    } on HttpException {
      throw const ApiServiceException(
        'Erro HTTP ao consultar a Currents API.',
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

  // ── Mapeamento de artigo da Currents API → EventModel ─────────────────
  EventModel _mapArticle(Map<String, dynamic> item) {
    final title = (item['title'] ?? '').toString().trim();
    final description = (item['description'] ?? '').toString().trim();
    final sourceUrl = (item['url'] ?? '').toString();
    final sourceName = (item['author'] ?? 'Fonte internacional').toString();
    final publishedAt = _parseDate(item['published']?.toString());
    final severity = _classifySeverity('$title $description');
    final riskWeight = switch (severity) {
      'Crítico' => 3.0,
      'Moderado' => 2.0,
      _ => 1.0,
    };

    // A Currents API retorna um array de categorias; usamos como proxy de
    // país/região quando não houver dado melhor.
    final categories = (item['category'] as List?)
            ?.map((c) => c.toString())
            .toList() ??
        const <String>[];

    return EventModel(
      id: (item['id'] ?? sourceUrl).toString(),
      title: title,
      summary: description.isEmpty
          ? 'Cobertura recente detectada pelo monitor internacional.'
          : description,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      country: _inferCountry(categories, item['language']?.toString()),
      severity: severity,
      publishedAt: publishedAt,
      riskWeight: riskWeight,
      keywords: _collectKeywords('$title $description'),
      tone: 0, // a Currents API não fornece score de tom
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Infere uma região/país a partir das categorias e idioma do artigo.
  String _inferCountry(List<String> categories, String? language) {
    // Sem campo de país direto; usamos o idioma como heurística.
    return switch (language?.toLowerCase()) {
      'en' => 'Global',
      'pt' => 'Brasil / Portugal',
      'es' => 'América Latina / Espanha',
      'fr' => 'França / África Francófona',
      'de' => 'Alemanha',
      'ru' => 'Rússia',
      'zh' => 'China',
      'ar' => 'Oriente Médio',
      'ja' => 'Japão',
      'ko' => 'Coreia',
      _ => 'Global',
    };
  }

  DateTime _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return DateTime.now();
    }

    // Formato da Currents API: "2026-03-24 12:05:00 +0000"
    final normalized = raw.trim();
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return parsed.toLocal();
    }

    // Tentativa alternativa: substituir espaço entre data e hora por "T"
    final withT = normalized.replaceFirst(' ', 'T');
    final alt = DateTime.tryParse(withT);
    if (alt != null) {
      return alt.toLocal();
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
