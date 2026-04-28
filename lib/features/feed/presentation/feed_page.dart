import 'package:flutter/material.dart';
import 'package:noty/features/feed/domain/notification_item.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
    required this.notifications,
    required this.isLoading,
    required this.onRefreshRequested,
    this.errorMessage,
  });

  final List<NotificationItem> notifications;
  final bool isLoading;
  final Future<void> Function() onRefreshRequested;
  final String? errorMessage;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  String _query = '';
  String _selectedApp = 'Todas';
  bool _onlyUnread = false;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _showContent = true;
        });
      }
    });
  }

  List<String> get _appFilters {
    final apps = <String>{for (final item in widget.notifications) item.appName};
    final sortedApps = apps.toList()..sort();
    return <String>['Todas', ...sortedApps];
  }

  List<NotificationItem> get _visibleItems {
    final filtered = widget.notifications.where((item) {
      final matchesApp = _selectedApp == 'Todas' || item.appName == _selectedApp;
      final matchesUnread = !_onlyUnread || item.isUnread;
      final matchesQuery = item.matchesQuery(_query);
      return matchesApp && matchesUnread && matchesQuery;
    }).toList();

    filtered.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Historial reciente',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todas las notificaciones capturadas por Noty.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por app, titulo o contenido...',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _appFilters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final appName = _appFilters[index];
                      return ChoiceChip(
                        label: Text(appName),
                        selected: _selectedApp == appName,
                        onSelected: (_) {
                          setState(() {
                            _selectedApp = appName;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: _onlyUnread,
                onSelected: (value) {
                  setState(() {
                    _onlyUnread = value;
                  });
                },
                label: const Text('No leidas'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              opacity: _showContent ? 1 : 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: widget.isLoading
                    ? const _LoadingFeed()
                        : widget.errorMessage != null
                            ? _FeedError(
                                message: widget.errorMessage!,
                                onRetry: widget.onRefreshRequested,
                              )
                        : items.isEmpty
                            ? _EmptyFeed(hasQuery: _query.trim().isNotEmpty)
                            : ListView.separated(
                                key: ValueKey<String>(
                                  '${_selectedApp}_${_onlyUnread}_${items.length}_$_query',
                                ),
                                itemCount: items.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return _NotificationCard(item: item);
                                },
                              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelColor = item.isUnread ? colorScheme.tertiary : colorScheme.onSurfaceVariant;
    final iconBackground = item.isUnread
        ? colorScheme.tertiaryContainer
        : colorScheme.surfaceContainerHighest;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_active_outlined, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatRelativeTime(item.receivedAt),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: labelColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.appName,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: labelColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      if (item.isUnread) ...<Widget>[
                        const SizedBox(width: 8),
                        Icon(Icons.circle, size: 8, color: colorScheme.tertiary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatRelativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'ahora';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    return '${difference.inDays}d';
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({
    this.hasQuery = false,
  });

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('empty-feed'),
      child: Text(
        hasQuery
            ? 'No encontramos coincidencias para tu busqueda.'
            : 'No hay notificaciones para ese filtro.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _LoadingFeed extends StatelessWidget {
  const _LoadingFeed();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey<String>('loading-feed'),
      child: CircularProgressIndicator(),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('error-feed'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
