import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/event_controller.dart';
import '../models/event_model.dart';
import 'details_view.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EventController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
      ),
      body: SafeArea(
        child: !controller.hasUserSession
            ? const _EmptyState(
                title: 'Faça login para ver seus favoritos',
                description: 'Os favoritos ficam vinculados ao seu UID no Firestore.',
              )
            : StreamBuilder<List<EventModel>>(
                stream: controller.favoritesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final favorites = snapshot.data ?? const <EventModel>[];
                  if (favorites.isEmpty) {
                    return const _EmptyState(
                      title: 'Nenhum favorito salvo',
                      description: 'Abra um evento e marque como favorito para montar sua lista.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemBuilder: (context, index) => _FavoriteTile(event: favorites[index]),
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemCount: favorites.length,
                  );
                },
              ),
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            '${event.country} • ${event.severity} • ${formatter.format(event.publishedAt)}',
            style: const TextStyle(height: 1.4),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DetailsView(event: event),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_border_rounded, size: 54, color: Color(0xFF829AB1)),
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
            ],
          ),
        ),
      ),
    );
  }
}
