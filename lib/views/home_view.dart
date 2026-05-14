import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/event_controller.dart';
import '../controllers/score_controller.dart';
import '../models/event_model.dart';
import 'details_view.dart';
import 'favorites_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventController>().fetchEvents();
    });
  }

  Future<void> _openScoreDetails(ScoreResult result) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Como o score foi calculado',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF102A43),
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  result.formula,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: const Color(0xFF334E68),
                      ),
                ),
                const SizedBox(height: 20),
                ...result.breakdown.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.label)),
                        Text('${item.value} x impacto ${item.impact}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<EventController, ScoreController, AuthController>(
      builder: (context, eventController, scoreController, authController, _) {
        final score = scoreController.result;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Painel global'),
            actions: [
              IconButton(
                tooltip: 'Explicação do cálculo',
                onPressed: () => _openScoreDetails(score),
                icon: const Icon(Icons.functions_rounded),
              ),
              IconButton(
                tooltip: 'Favoritos',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const FavoritesView(),
                    ),
                  );
                },
                icon: const Icon(Icons.star_border_rounded),
              ),
              IconButton(
                tooltip: 'Sair',
                onPressed: authController.isLoading ? null : authController.signOut,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: eventController.fetchEvents,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  if (!eventController.isFirebaseReady) ...[
                    const _PendingFirebaseBanner(),
                    const SizedBox(height: 16),
                  ],
                  _ScoreHeroCard(
                    result: score,
                    lastUpdated: eventController.lastUpdated,
                    onExplainPressed: () => _openScoreDetails(score),
                  ),
                  const SizedBox(height: 16),
                  _FilterCard(eventController: eventController),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: 'Eventos internacionais recentes',
                    subtitle: 'Leitura das últimas 48 horas com foco em crise, conflito e escalada militar.',
                    trailing: TextButton.icon(
                      onPressed: eventController.fetchEvents,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Atualizar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildEventState(context, eventController),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventState(BuildContext context, EventController eventController) {
    if (eventController.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (eventController.errorMessage != null) {
      return _MessageCard(
        icon: Icons.cloud_off_rounded,
        title: 'Não foi possível atualizar os eventos',
        description: eventController.errorMessage!,
        actionLabel: 'Tentar novamente',
        onAction: eventController.fetchEvents,
      );
    }

    if (eventController.events.isEmpty) {
      return _MessageCard(
        icon: Icons.public_off_rounded,
        title: 'Nenhum evento encontrado',
        description: 'A consulta atual não retornou resultados. Ajuste os filtros ou tente novamente.',
        actionLabel: 'Limpar filtros',
        onAction: eventController.clearFilters,
      );
    }

    return Column(
      children: eventController.events
          .map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EventCard(event: event),
              ))
          .toList(),
    );
  }
}

class _PendingFirebaseBanner extends StatelessWidget {
  const _PendingFirebaseBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF7D07A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.build_circle_outlined, color: Color(0xFF9C6B00)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'O painel consome eventos internacionais em tempo real. Favoritos e histórico usam Firebase quando o projeto conectado está disponível.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF7C5A00),
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreHeroCard extends StatelessWidget {
  const _ScoreHeroCard({
    required this.result,
    required this.lastUpdated,
    required this.onExplainPressed,
  });

  final ScoreResult result;
  final DateTime? lastUpdated;
  final VoidCallback onExplainPressed;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Relógio do Apocalipse',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF102A43),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Score global de risco calculado com volume, severidade e recência dos eventos monitorados.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF486581),
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: result.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${result.score}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: result.color,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        '/100',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: result.color,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Chip(
                  label: Text('Nível ${result.status}'),
                  avatar: CircleAvatar(backgroundColor: result.color, radius: 6),
                ),
                Chip(
                  label: Text(
                    lastUpdated == null
                        ? 'Sem atualização recente'
                        : 'Atualizado em ${formatter.format(lastUpdated!)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onExplainPressed,
              icon: const Icon(Icons.visibility_rounded),
              label: const Text('Ver cálculo do score'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.eventController});

  final EventController eventController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros da consulta',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF102A43),
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField<String>(
                    initialValue: eventController.selectedCountry,
                    decoration: const InputDecoration(
                      labelText: 'País',
                      prefixIcon: Icon(Icons.public_rounded),
                    ),
                    items: eventController.availableCountries
                        .map(
                          (country) => DropdownMenuItem<String>(
                            value: country,
                            child: Text(country),
                          ),
                        )
                        .toList(),
                    onChanged: eventController.setCountryFilter,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: eventController.selectedSeverity,
                    decoration: const InputDecoration(
                      labelText: 'Severidade',
                      prefixIcon: Icon(Icons.warning_amber_rounded),
                    ),
                    items: eventController.availableSeverities
                        .map(
                          (severity) => DropdownMenuItem<String>(
                            value: severity,
                            child: Text(severity),
                          ),
                        )
                        .toList(),
                    onChanged: eventController.setSeverityFilter,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: eventController.clearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Limpar filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF102A43),
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF486581),
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        trailing,
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF829AB1)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF102A43),
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF486581),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EventController>();
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF102A43),
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                _SeverityPill(severity: event.severity),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              event.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF486581),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(event.country)),
                Chip(label: Text(formatter.format(event.publishedAt))),
                if (event.keywords.isNotEmpty)
                  Chip(label: Text(event.keywords.take(2).join(' • '))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DetailsView(event: event),
                        ),
                      );
                    },
                    child: const Text('Ver detalhes'),
                  ),
                ),
                const SizedBox(width: 12),
                FutureBuilder<bool>(
                  future: controller.isFavorite(event.id),
                  builder: (context, snapshot) {
                    final isFavorite = snapshot.data ?? false;
                    return IconButton.filledTonal(
                      tooltip: isFavorite ? 'Remover dos favoritos' : 'Salvar nos favoritos',
                      onPressed: () async {
                        try {
                          await controller.toggleFavorite(event);
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFavorite
                                    ? 'Evento removido dos favoritos.'
                                    : 'Evento salvo nos favoritos.',
                              ),
                            ),
                          );
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
                      icon: Icon(
                        isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({required this.severity});

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
              fontWeight: FontWeight.w700,
              color: color,
            ),
      ),
    );
  }
}
