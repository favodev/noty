import 'package:flutter/material.dart';
import 'package:noty/features/feed/data/mock_notifications.dart';
import 'package:noty/features/feed/domain/notification_item.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late final List<NotificationItem> _notifications;
  String _selectedApp = 'Todas';
  bool _onlyUnread = false;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _notifications = buildMockNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _showContent = true;
        });
      }
    });
  }

  List<String> get _appFilters {
    final apps = <String>{for (final item in _notifications) item.appName};
    final sortedApps = apps.toList()..sort();
    return <String>['Todas', ...sortedApps];
  }

  List<NotificationItem> get _visibleItems {
    final filtered = _notifications.where((item) {
      final matchesApp = _selectedApp == 'Todas' || item.appName == _selectedApp;
      final matchesUnread = !_onlyUnread || item.isUnread;
      return matchesApp && matchesUnread;
    }).toList();

    filtered.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;

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
            'Persistencia local lista. Siguiente paso: listener Android y sync con Supabase.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF475569),
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
                child: items.isEmpty
                    ? const _EmptyFeed()
                    : ListView.separated(
                        key: ValueKey<String>(
                          '${_selectedApp}_${_onlyUnread}_${items.length}',
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
    final labelColor = item.isUnread ? const Color(0xFF0B6BFD) : const Color(0xFF64748B);

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
                color: const Color(0xFFEEF2FF),
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
                              color: const Color(0xFF64748B),
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
                        const Icon(Icons.circle, size: 8, color: Color(0xFF0B6BFD)),
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
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('empty-feed'),
      child: Text(
        'No hay notificaciones para ese filtro.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF64748B),
            ),
      ),
    );
  }
}