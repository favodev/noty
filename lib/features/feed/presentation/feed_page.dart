import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:noty/features/feed/domain/notification_item.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
    required this.notifications,
    required this.appIcons,
    required this.isLoading,
    this.errorMessage,
    required this.isNotificationListenerEnabled,
    required this.onOpenNotificationSettings,
    required this.onRefreshRequested,
    required this.onDeleteNotification,
    required this.onMarkAsRead,
  });

  final List<NotificationItem> notifications;
  final Map<String, Uint8List> appIcons;
  final bool isLoading;
  final String? errorMessage;
  final bool isNotificationListenerEnabled;
  final VoidCallback onOpenNotificationSettings;
  final Future<void> Function() onRefreshRequested;
  final Future<void> Function(String id) onDeleteNotification;
  final Future<void> Function(String id) onMarkAsRead;

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
    final apps = <String>{
      for (final item in widget.notifications) item.appName,
    };
    final sortedApps = apps.toList()..sort();
    return <String>['Todas', ...sortedApps];
  }

  List<NotificationItem> get _visibleItems {
    final filtered = widget.notifications.where((item) {
      final matchesApp =
          _selectedApp == 'Todas' || item.appName == _selectedApp;
      final matchesUnread = !_onlyUnread || item.isUnread;
      final matchesQuery = item.matchesQuery(_query);
      return matchesApp && matchesUnread && matchesQuery;
    }).toList();

    filtered.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _visibleItems;
    final colorScheme = theme.colorScheme;
    final hasQuery = _query.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!widget.isNotificationListenerEnabled) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Falta permiso para leer notificaciones.',
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onOpenNotificationSettings,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                    child: const Text('Dar permiso'),
                  ),
                ],
              ),
            ),
          ],
          Text(
            'Historial reciente',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todas las notificaciones capturadas por Noty.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SearchBar(
            hintText: 'Buscar por app, título o contenido...',
            leading: const Icon(Icons.search),
            trailing: hasQuery
                ? [
                    IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        setState(() {
                          _query = '';
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ]
                : null,
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Text(
                '${items.length} resultado${items.length == 1 ? '' : 's'}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (hasQuery || _selectedApp != 'Todas' || _onlyUnread)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _query = '';
                      _selectedApp = 'Todas';
                      _onlyUnread = false;
                    });
                  },
                  child: const Text('Limpiar filtros'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                FilterChip(
                  selected: _onlyUnread,
                  onSelected: (value) {
                    setState(() {
                      _onlyUnread = value;
                    });
                  },
                  avatar: Icon(
                    _onlyUnread
                        ? Icons.mark_email_unread_rounded
                        : Icons.drafts_outlined,
                    size: 16,
                  ),
                  label: const Text('No leídas'),
                ),
                if (_appFilters.length > 1) ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 1,
                    height: 24,
                    color: colorScheme.outlineVariant,
                  ),
                  const SizedBox(width: 12),
                ],
                for (final appName in _appFilters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: _appIconForName(appName) == null
                          ? null
                          : _AppIcon(bytes: _appIconForName(appName), size: 18),
                      label: Text(appName),
                      selected: _selectedApp == appName,
                      onSelected: (_) {
                        setState(() {
                          _selectedApp = appName;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
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
                    ? _EmptyFeed(hasQuery: hasQuery)
                    : RefreshIndicator(
                        onRefresh: widget.onRefreshRequested,
                        child: ListView.separated(
                          key: ValueKey<String>(
                            '${_selectedApp}_${_onlyUnread}_${items.length}_$_query',
                          ),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _NotificationCard(
                              item: item,
                              appIconBytes: widget.appIcons[item.appPackage],
                              onMarkAsRead: widget.onMarkAsRead,
                              onDelete: widget.onDeleteNotification,
                            );
                          },
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Uint8List? _appIconForName(String appName) {
    if (appName == 'Todas') {
      return null;
    }

    for (final item in widget.notifications) {
      if (item.appName == appName) {
        final icon = widget.appIcons[item.appPackage];
        if (icon != null) {
          return icon;
        }
      }
    }

    return null;
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.appIconBytes,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  final NotificationItem item;
  final Uint8List? appIconBytes;
  final Future<void> Function(String id) onMarkAsRead;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelColor = item.isUnread
        ? colorScheme.tertiary
        : colorScheme.onSurfaceVariant;
    final iconBackground = item.isUnread
        ? colorScheme.tertiaryContainer
        : colorScheme.surfaceContainerHighest;
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _AppIcon(
                  bytes: appIconBytes,
                  fallbackColor: item.isUnread
                      ? colorScheme.tertiary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formatRelativeTime(item.receivedAt),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: labelColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.appName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: labelColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (item.hasMedia) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.image_outlined,
                            size: 16,
                            color: labelColor,
                          ),
                        ],
                        Row(
                          children: [
                            if (item.isUnread)
                              IconButton(
                                icon: const Icon(
                                  Icons.mark_email_read_outlined,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => onMarkAsRead(item.id),
                              ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => onDelete(item.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDetails(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _NotificationDetailsSheet(item: item),
    );

    if (item.isUnread) {
      await onMarkAsRead(item.id);
    }
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

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.bytes, this.size = 24, this.fallbackColor});

  final Uint8List? bytes;
  final double size;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    final iconBytes = bytes;
    if (iconBytes == null || iconBytes.isEmpty) {
      return Icon(
        Icons.notifications_active_outlined,
        size: size * 0.84,
        color: fallbackColor,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.memory(
        iconBytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }
}

class _NotificationDetailsSheet extends StatelessWidget {
  const _NotificationDetailsSheet({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.appName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _NotificationCard._formatRelativeTime(item.receivedAt),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SelectableText(
                  item.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  item.body,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
                ),
                if (item.hasMedia) ...[
                  const SizedBox(height: 16),
                  _NotificationMediaPreview(item: item),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationMediaPreview extends StatelessWidget {
  const _NotificationMediaPreview({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final mediaPath = item.mediaPath?.trim();
    if (mediaPath == null || mediaPath.isEmpty) {
      return const SizedBox.shrink();
    }

    final file = File(mediaPath);
    if (!file.existsSync()) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final mediaLabel = item.mediaType == 'sticker' ? 'Sticker' : 'Imagen';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          mediaLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({this.hasQuery = false});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Center(
      key: const ValueKey<String>('empty-feed'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasQuery
                    ? Icons.search_off_rounded
                    : Icons.notifications_off_outlined,
                size: 30,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery
                  ? 'No encontramos coincidencias.'
                  : 'Todavía no hay notificaciones.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Prueba con otro término o limpia los filtros.'
                  : 'Cuando llegue actividad nueva, la vas a ver aquí.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
  const _FeedError({required this.message, required this.onRetry});

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
