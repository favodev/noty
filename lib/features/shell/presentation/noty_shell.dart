import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:noty/features/feed/domain/notification_item.dart';
import 'package:noty/features/feed/presentation/feed_page.dart';
import 'package:noty/features/settings/presentation/app_selection_page.dart';
import 'package:noty/features/settings/presentation/settings_page.dart';
import 'package:noty/features/shell/data/noty_shell_service.dart';

class NotyShell extends StatefulWidget {
  const NotyShell({
    super.key,
    required this.currentThemeMode,
    this.enableLocalPersistence = true,
    this.onThemeChanged,
  });

  final ThemeMode currentThemeMode;
  final bool enableLocalPersistence;
  final void Function(ThemeMode mode)? onThemeChanged;

  @override
  State<NotyShell> createState() => _NotyShellState();
}

class _NotyShellState extends State<NotyShell> with WidgetsBindingObserver {
  final NotyShellService _shellService = NotyShellService();
  StreamSubscription<void>? _newNotificationSubscription;
  Timer? _notificationDrainTimer;

  int _index = 0;
  bool _isLoadingNotifications = true;
  bool _isNotificationListenerEnabled = false;
  bool _isDataBusy = false;
  bool _isRefreshingNotifications = false;
  String? _notificationsError;
  Map<String, Object?> _nativeDiagnostics = const <String, Object?>{};
  Map<String, Uint8List> _appIcons = const <String, Uint8List>{};
  List<NotificationItem> _notifications = const <NotificationItem>[];

  static const List<String> _titles = <String>['Inicio', 'Ajustes'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadNotifications());

    _newNotificationSubscription = _shellService.onNewNotification.listen((_) {
      if (mounted) {
        unawaited(_loadNotifications(silent: true));
      }
    });

    if (widget.enableLocalPersistence) {
      _notificationDrainTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted) {
          unawaited(_loadNotifications(silent: true));
        }
      });
    }
  }

  @override
  void dispose() {
    _notificationDrainTimer?.cancel();
    unawaited(_newNotificationSubscription?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_shellService.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadNotifications(silent: true));
    }
  }

  Future<void> _deleteNotification(String id) async {
    await _shellService.deleteNotification(id);
    await _loadNotifications(silent: true);
  }

  Future<void> _markAsRead(String id) async {
    await _shellService.markNotificationAsRead(id);
    await _loadNotifications(silent: true);
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!mounted) {
      return;
    }

    if (_isRefreshingNotifications) {
      return;
    }

    _isRefreshingNotifications = true;

    if (!silent) {
      setState(() {
        _isLoadingNotifications = true;
        _notificationsError = null;
      });
    }

    try {
      final result = await _shellService.loadNotifications(
        enableLocalPersistence: widget.enableLocalPersistence,
      );
      final nativeDiagnostics = widget.enableLocalPersistence
          ? await _shellService.getNativeDiagnostics()
          : const <String, Object?>{};
      final appIcons = widget.enableLocalPersistence
          ? await _shellService.getAppIcons(
              result.notifications
                  .map((item) => item.appPackage)
                  .where((packageName) => packageName.isNotEmpty)
                  .toSet()
                  .toList(),
            )
          : const <String, Uint8List>{};

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = result.notifications;
        _isLoadingNotifications = false;
        _isNotificationListenerEnabled = result.listenerEnabled;
        _notificationsError = result.errorMessage;
        _nativeDiagnostics = nativeDiagnostics;
        _appIcons = appIcons;
      });
    } finally {
      _isRefreshingNotifications = false;
    }
  }

  void _openAppSelection() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AppSelectionPage(
          onGetInstalledApps: _shellService.getInstalledApps,
          onGetMonitoredPackages: _shellService.getMonitoredPackages,
          onSavePackages: _shellService.updateMonitoredPackages,
        ),
      ),
    );
  }

  Future<void> _clearHistory() async {
    await _runDataAction(
      successMessage: 'Historial local borrado.',
      action: () async {
        await _shellService.clearLocalHistory();
        await _loadNotifications();
        return null;
      },
    );
  }

  Future<void> _exportHistory() async {
    await _runDataAction(
      successMessage: 'Exportación lista para compartir o guardar.',
      action: _shellService.exportHistory,
    );
  }

  Future<void> _importHistory() async {
    await _runDataAction(
      successMessage: 'Historial importado correctamente.',
      action: () async {
        final importedCount = await _shellService.importHistory();
        if (importedCount == null) {
          return 'Importación cancelada.';
        }
        await _loadNotifications();
        return 'Se importaron $importedCount notificaciones.';
      },
    );
  }

  Future<void> _runDataAction({
    required String successMessage,
    required Future<Object?> Function() action,
  }) async {
    if (_isDataBusy) {
      return;
    }

    setState(() {
      _isDataBusy = true;
    });

    String message = successMessage;
    try {
      final result = await action();
      if (result is String && result.isNotEmpty) {
        message = result;
      }
    } catch (error) {
      message = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isDataBusy = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  List<Widget> _buildTabs() {
    return <Widget>[
      FeedPage(
        notifications: _notifications,
        appIcons: _appIcons,
        isLoading: _isLoadingNotifications,
        errorMessage: _notificationsError,
        isNotificationListenerEnabled: _isNotificationListenerEnabled,
        onOpenNotificationSettings:
            _shellService.openNotificationListenerSettings,
        onRefreshRequested: _loadNotifications,
        onDeleteNotification: _deleteNotification,
        onMarkAsRead: _markAsRead,
      ),
      SettingsPage(
        currentThemeMode: widget.currentThemeMode,
        notificationListenerEnabled: _isNotificationListenerEnabled,
        nativeDiagnostics: _nativeDiagnostics,
        isDataBusy: _isDataBusy,
        onOpenNotificationSettings:
            _shellService.openNotificationListenerSettings,
        onOpenAppSelection: _openAppSelection,
        onExportHistory: _exportHistory,
        onImportHistory: _importHistory,
        onClearHistory: _clearHistory,
        onThemeModeChanged: widget.onThemeChanged,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _buildTabs();

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide =
              Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(key: ValueKey<int>(_index), child: tabs[_index]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (nextIndex) {
          if (nextIndex == _index) {
            return;
          }
          setState(() {
            _index = nextIndex;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
