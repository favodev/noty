import 'package:flutter/material.dart';
import 'package:noty/features/feed/domain/notification_item.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.notifications,
    required this.isLoading,
    this.errorMessage,
    this.scrollController,
  });

  final List<NotificationItem> notifications;
  final bool isLoading;
  final String? errorMessage;
  final ScrollController? scrollController;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';
  late final ScrollController _internalScrollController;

  @override
  void initState() {
    super.initState();
    _internalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _internalScrollController.dispose();
    super.dispose();
  }

  List<NotificationItem> get _results {
    final filtered = widget.notifications.where((item) => item.matchesQuery(_query)).toList();
    filtered.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = widget.scrollController ?? _internalScrollController;
    final hasQuery = _query.trim().isNotEmpty;
    final results = _results;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Buscar en historial',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Filtra por app, titulo o contenido en milisegundos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF475569),
                  ),
            ),
            const SizedBox(height: 14),
            TextField(
              autofocus: true,
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Ej: eliminado, banco, standup...',
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: widget.isLoading
                    ? const _SearchLoading()
                    : widget.errorMessage != null
                        ? _SearchError(message: widget.errorMessage!)
                        : !hasQuery
                            ? const _SearchHint()
                            : results.isEmpty
                                ? const _NoSearchResults()
                                : ListView.separated(
                                    controller: scrollController,
                                    key: ValueKey<String>('results-${results.length}-$_query'),
                                    itemCount: results.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final item = results[index];
                                      return Card(
                                        child: ListTile(
                                          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                          subtitle: Text(
                                            '${item.appName} - ${item.body}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          trailing: Text(
                                            _hourMinute(item.receivedAt),
                                            style: Theme.of(context).textTheme.labelSmall,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hourMinute(DateTime dateTime) {
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('search-hint'),
      child: Text(
        'Escribe para empezar a buscar.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF64748B),
            ),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('search-empty'),
      child: Text(
        'No encontramos coincidencias.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF64748B),
            ),
      ),
    );
  }
}

class _SearchLoading extends StatelessWidget {
  const _SearchLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey<String>('search-loading'),
      child: CircularProgressIndicator(),
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('search-error'),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
