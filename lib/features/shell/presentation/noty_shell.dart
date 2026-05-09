import 'dart:async';

import 'package:flutter/material.dart';
import 'package:noty/core/supabase/supabase_bootstrap.dart';
import 'package:noty/features/auth/presentation/password_recovery_page.dart';
import 'package:noty/features/feed/domain/notification_item.dart';
import 'package:noty/features/feed/presentation/feed_page.dart';
import 'package:noty/features/shell/data/noty_shell_service.dart';
import 'package:noty/features/settings/presentation/settings_page.dart';
import 'package:noty/features/settings/presentation/app_selection_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotyShell extends StatefulWidget {
  const NotyShell({
    super.key,
    required this.supabaseState,
    required this.currentThemeMode,
    this.enableLocalPersistence = true,
    this.onThemeChanged,
  });

  final SupabaseBootstrapState supabaseState;
  final ThemeMode currentThemeMode;
  final bool enableLocalPersistence;
  final void Function(ThemeMode mode)? onThemeChanged;

  @override
  State<NotyShell> createState() => _NotyShellState();
}

class _NotyShellState extends State<NotyShell> with WidgetsBindingObserver {
  final NotyShellService _shellService = NotyShellService();

  StreamSubscription<AuthState>? _authSubscription;
  bool _isRecoveryFlowOpen = false;

  int _index = 0;
  bool _isLoadingNotifications = true;
  bool _isNotificationListenerEnabled = false;
  bool _isSyncingNotifications = false;
  bool _isAuthBusy = false;
  bool _isEmailConfirmed = false;
  bool _isPasswordRecoveryMode = false;
  String? _notificationsError;
  User? _currentUser;
  List<NotificationItem> _notifications = const <NotificationItem>[];

  static const List<String> _titles = <String>['Inicio', 'Ajustes'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.supabaseState.initialized) {
      _currentUser = _shellService.currentUser;
      _isEmailConfirmed = _shellService.isEmailConfirmed;
      _authSubscription = _shellService.authStateChanges().listen(_handleAuthStateChanged);
    }

    _loadNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    unawaited(_shellService.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotifications();
    }
  }

  void _handleAuthStateChanged(AuthState state) {
    if (!mounted) {
      return;
    }

    final isRecoveryEvent = state.event == AuthChangeEvent.passwordRecovery;
    final isSignedOutEvent = state.event == AuthChangeEvent.signedOut;

    setState(() {
      _currentUser = state.session?.user;
      _isEmailConfirmed = _shellService.isEmailConfirmed;
      if (isRecoveryEvent) {
        _isPasswordRecoveryMode = true;
      } else if (isSignedOutEvent) {
        _isPasswordRecoveryMode = false;
      }
    });

    if (state.session?.user != null) {
      unawaited(_syncPendingNotifications());
    }

    if (isRecoveryEvent) {
      unawaited(_openPasswordRecoveryFlow());
    }
  }

  Future<void> _loadNotifications() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingNotifications = true;
      _notificationsError = null;
    });

    final result = await _shellService.loadNotifications(
      enableLocalPersistence: widget.enableLocalPersistence,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _notifications = result.notifications;
      _isLoadingNotifications = false;
      _isNotificationListenerEnabled = result.listenerEnabled;
      _notificationsError = result.errorMessage;
    });

    if (widget.supabaseState.initialized) {
      unawaited(_syncPendingNotifications());
    }
  }

  Future<void> _syncPendingNotifications() async {
    if (!mounted || _isSyncingNotifications) {
      return;
    }

    setState(() {
      _isSyncingNotifications = true;
    });

    final result = await _shellService.syncPendingNotifications(
      enableLocalPersistence: widget.enableLocalPersistence,
      supabaseInitialized: widget.supabaseState.initialized,
      currentUser: _currentUser,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      if (result.completed) {
        _notifications = result.notifications;
      }
      _isSyncingNotifications = false;
    });
  }

  Future<String?> _signIn(String email, String password) async {
    return _runAuthAction(() async {
      await _shellService.signIn(
        supabaseInitialized: widget.supabaseState.initialized,
        email: email,
        password: password,
      );
    });
  }

  Future<String?> _signUp(String email, String password) async {
    return _runAuthAction(() async {
      await _shellService.signUp(
        supabaseInitialized: widget.supabaseState.initialized,
        email: email,
        password: password,
      );
    });
  }

  Future<String?> _signOut() async {
    return _runAuthAction(() async {
      await _shellService.signOut(
        supabaseInitialized: widget.supabaseState.initialized,
      );
    });
  }

  Future<String?> _requestPasswordReset(String email) async {
    return _runAuthAction(() async {
      await _shellService.requestPasswordReset(
        supabaseInitialized: widget.supabaseState.initialized,
        email: email,
      );
    });
  }

  Future<String?> _updateRecoveredPassword(String password) async {
    return _runAuthAction(() async {
      await _shellService.updateRecoveredPassword(
        supabaseInitialized: widget.supabaseState.initialized,
        isPasswordRecoveryMode: _isPasswordRecoveryMode,
        password: password,
      );
      if (mounted) {
        setState(() {
          _isPasswordRecoveryMode = false;
        });
      }
    });
  }

  Future<String?> _runAuthAction(Future<void> Function() action) async {
    setState(() {
      _isAuthBusy = true;
    });

    try {
      await action();
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isAuthBusy = false;
        });
      }
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
    await _shellService.clearLocalHistory();
    await _loadNotifications();
  }

  Future<void> _openPasswordRecoveryFlow() async {
    if (!mounted || _isRecoveryFlowOpen) {
      return;
    }

    _isRecoveryFlowOpen = true;

    final newPassword = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const PasswordRecoveryPage(),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) {
      _isRecoveryFlowOpen = false;
      return;
    }

    if (newPassword == null || newPassword.trim().isEmpty) {
      _isRecoveryFlowOpen = false;
      return;
    }

    final result = await _updateRecoveredPassword(newPassword);

    if (!mounted) {
      _isRecoveryFlowOpen = false;
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result ?? 'Password actualizada'),
        backgroundColor: result == null ? colorScheme.primary : null,
      ),
    );

    _isRecoveryFlowOpen = false;
  }

  List<Widget> _buildTabs() {
    return <Widget>[
        FeedPage(
          notifications: _notifications,
          isLoading: _isLoadingNotifications,
          errorMessage: _notificationsError,
          isNotificationListenerEnabled: _isNotificationListenerEnabled,
          onOpenNotificationSettings: _shellService.openNotificationListenerSettings,
          onRefreshRequested: _loadNotifications,
        ),
      SettingsPage(
        supabaseState: widget.supabaseState,
        currentThemeMode: widget.currentThemeMode,
        notificationListenerEnabled: _isNotificationListenerEnabled,
        authEmail: _currentUser?.email,
        isEmailConfirmed: _isEmailConfirmed,
        isPasswordRecoveryMode: _isPasswordRecoveryMode,
        isAuthBusy: _isAuthBusy,
        onSignIn: _signIn,
        onSignUp: _signUp,
        onSignOut: _signOut,
        onRequestPasswordReset: _requestPasswordReset,
        onUpdateRecoveredPassword: _updateRecoveredPassword,
        onOpenNotificationSettings: _shellService.openNotificationListenerSettings,
        onOpenAppSelection: _openAppSelection,
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
          final slide = Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_index),
          child: tabs[_index],
        ),
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
