import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/event_controller.dart';
import '../models/event_model.dart';

class DetailsView extends StatefulWidget {
  const DetailsView({super.key, required this.event});

  final EventModel event;

  @override
  State<DetailsView> createState() => _DetailsViewState();
}

class _DetailsViewState extends State<DetailsView> {
  late Future<bool> _favoriteFuture;

  @override
  void initState() {
    super.initState();
    _favoriteFuture = context.read<EventController>().isFavorite(widget.event.id);
  }

  Future<void> _toggleFavorite() async {
    final controller = context.read<EventController>();

    try {
      await controller.toggleFavorite(widget.event);
      setState(() {
        _favoriteFuture = controller.isFavorite(widget.event.id);
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favoritos atualizados.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do evento'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF102A43),
                                ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _SeverityBadge(severity: event.severity),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetaChip(icon: Icons.public_rounded, label: event.country),
                        _MetaChip(icon: Icons.schedule_rounded, label: dateFormat.format(event.publishedAt)),
                        _MetaChip(icon: Icons.source_rounded, label: event.sourceName),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      event.summary,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF334E68),
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 20),
                    SelectableText(
                      event.sourceUrl.isEmpty ? 'Fonte externa não informada.' : event.sourceUrl,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF2563EB),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Impacto no score',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF102A43),
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Este evento entra no cálculo com peso ${event.riskWeight.toStringAsFixed(0)} por causa da severidade ${event.severity.toLowerCase()}. Quanto mais eventos críticos e recentes existirem na janela de 48 horas, maior será o score global.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF486581),
                            height: 1.5,
                          ),
                    ),
                    if (event.keywords.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: event.keywords
                            .map((keyword) => Chip(label: Text(keyword)))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<bool>(
              future: _favoriteFuture,
              builder: (context, snapshot) {
                final isFavorite = snapshot.data ?? false;
                return ElevatedButton.icon(
                  onPressed: _toggleFavorite,
                  icon: Icon(isFavorite ? Icons.star_rounded : Icons.star_border_rounded),
                  label: Text(isFavorite ? 'Remover dos favoritos' : 'Salvar nos favoritos'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FD),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF486581)),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final String severity;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      'Crítico' => const Color(0xFFC62828),
      'Moderado' => const Color(0xFFF57C00),
      _ => const Color(0xFF2E7D32),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        severity,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
