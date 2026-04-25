import 'dart:async';

import 'package:flutter/material.dart';
import 'package:noty/core/config/app_env.dart';
import 'package:noty/core/supabase/supabase_bootstrap.dart';
import 'package:noty/features/auth/data/supabase_auth_service.dart';
import 'package:noty/features/auth/presentation/password_recovery_page.dart';
import 'package:noty/features/feed/data/local_notifications_repository.dart';
import 'package:noty/features/feed/data/mock_notifications.dart';
import 'package:noty/features/feed/data/native_notifications_bridge.dart';
import 'package:noty/features/feed/data/supabase_notifications_sync.dart';
import 'package:noty/features/feed/domain/notification_item.dart';
import 'package:noty/features/feed/presentation/feed_page.dart';
import 'package:noty/features/search/presentation/search_page.dart';
import 'package:noty/features/settings/presentation/settings_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotyShell extends StatefulWidget {
  const NotyShell({
    super.key,
    required this.supabaseState,
    this.enableLocalPersistence = true,
  });

  final SupabaseBootstrapState supabaseState;
  final bool enableLocalPersistence;

  @override
  State<NotyShell> createState() => _NotyShellState();
}

class _NotyShellState extends State<NotyShell> with WidgetsBindingObserver {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final LocalNotificationsRepository _repository = LocalNotificationsRepository();
  final NativeNotificationsBridge _nativeBridge = NativeNotificationsBridge();
  final SupabaseNotificationsSync _supabaseSync = SupabaseNotificationsSync();

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

  static const List<String> _titles = <String>[
    'Inicio',
    'Buscar',
    'Ajustes',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.supabaseState.initialized) {
      _currentUser = _authService.currentUser;
      _isEmailConfirmed = _authService.isEmailConfirmed;
      _authSubscription = _authService.authStateChanges().listen((state) {
        if (!mounted) {
          return;
        }

        final isRecoveryEvent = state.event == AuthChangeEvent.passwordRecovery;
        final isSignedOutEvent = state.event == AuthChangeEvent.signedOut;

        setState(() {
          _currentUser = state.session?.user;
          _isEmailConfirmed = _authService.isEmailConfirmed;
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
      });
    }

    _loadNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotifications();
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

    if (!widget.enableLocalPersistence) {
      setState(() {
        _notifications = buildMockNotifications();
        _isLoadingNotifications = false;
      });

      if (widget.supabaseState.initialized) {
        unawaited(_syncPendingNotifications());
      }
      return;
    }

    try {
      await _repository.initialize();
      await _repository.seedIfEmpty(buildMockNotifications());

      final listenerEnabled = await _nativeBridge.isNotificationListenerEnabled();
      final nativeNotifications = await _nativeBridge.drainPendingNotifications();
      for (final item in nativeNotifications) {
        await _repository.upsert(item);
      }

      final notifications = await _repository.getAll();

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = notifications;
        _isLoadingNotifications = false;
        _isNotificationListenerEnabled = listenerEnabled;
      });

      if (widget.supabaseState.initialized) {
        unawaited(_syncPendingNotifications());
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingNotifications = false;
        _notificationsError = 'No pudimos cargar notificaciones locales.';
      });
    }
  }

  Future<void> _syncPendingNotifications() async {
    if (!mounted || _isSyncingNotifications) {
      return;
    }

    if (!widget.supabaseState.initialized) {
      return;
    }

    if (_currentUser == null) {
      return;
    }

    if (!widget.enableLocalPersistence) {
      return;
    }

    setState(() {
      _isSyncingNotifications = true;
    });

    try {
      final pending = await _repository.getPendingSync(limit: 100);
      if (pending.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isSyncingNotifications = false;
        });
        return;
      }

      final result = await _supabaseSync.sync(pending);

      if (result.syncedIds.isNotEmpty) {
        await _repository.markAsSynced(result.syncedIds);
      }

      for (final failure in result.failed) {
        await _repository.markAsSyncFailed(failure.notificationId, failure.message);
      }

      final refreshed = await _repository.getAll();

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = refreshed;
        _isSyncingNotifications = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSyncingNotifications = false;
      });
    }
  }

  Future<String?> _signIn(String email, String password) async {
    if (!widget.supabaseState.initialized) {
      return 'Supabase no esta inicializado.';
    }

    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return 'Email y password son obligatorios.';
    }

    setState(() {
      _isAuthBusy = true;
    });

    try {
      await _authService.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (_) {
      return 'No pudimos iniciar sesion.';
    } finally {
      if (mounted) {
        setState(() {
          _isAuthBusy = false;
        });
      }
    }
  }

  Future<String?> _signUp(String email, String password) async {
    if (!widget.supabaseState.initialized) {
      return 'Supabase no esta inicializado.';
    }

    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return 'Email y password son obligatorios.';
    }

    setState(() {
      _isAuthBusy = true;
    });

    try {
      await _authService.signUpWithPassword(
        email: normalizedEmail,
        password: password,
      );
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (_) {
      return 'No pudimos crear la cuenta.';
    } finally {
      if (mounted) {
        setState(() {
          _isAuthBusy = false;
        });
      }
    }
  }

  Future<String?> _signOut() async {
    if (!widget.supabaseState.initialized) {
      return 'Supabase no esta inicializado.';
    }

    setState(() {
      _isAuthBusy = true;
    });

    try {
      await _authService.signOut();
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (_) {
      return 'No pudimos cerrar sesion.';
    } finally {
      if (mounted) {
        setState(() {
          _isAuthBusy = false;
        });
      }
    }
  }

  Future<String?> _requestPasswordReset(String email) async {
    if (!widget.supabaseState.initialized) {
      return 'Supabase no esta inicializado.';
    }

    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      return 'Ingresa un email valido.';
    }

    setState(() {
      _isAuthBusy = true;
    });

    try {
      await _authService.sendPasswordResetEmail(
        email: normalizedEmail,
        redirectTo: AppEnv.supabaseAuthRedirect,
      );
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (_) {
      return 'No pudimos enviar el email de recuperacion.';
    } finally {
      if (mounted) {
        setState(() {
          _isAuthBusy = false;
        });
      }
    }
  }

  Future<String?> _updateRecoveredPassword(String password) async {
    if (!widget.supabaseState.initialized) {
      return 'Supabase no esta inicializado.';
    }

    if (!_isPasswordRecoveryMode) {
      return 'No hay recuperacion activa.';
    }

    if (password.length < 8) {
      return 'La nueva password debe tener al menos 8 caracteres.';
    }

    setState(() {
      _isAuthBusy = true;
    });

    try {
      await _authService.updatePassword(password);
      if (mounted) {
        setState(() {
          _isPasswordRecoveryMode = false;
        });
      }
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (_) {
      return 'No pudimos actualizar la password.';
    } finally {
      if (mounted) {
        setState(() {
          _isAuthBusy = false;
        });
      }
    }
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result ?? 'Password actualizada'),
        backgroundColor: result == null ? const Color(0xFF047857) : null,
      ),
    );

    _isRecoveryFlowOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final pendingSyncCount =
        _notifications.where((item) => item.needsSync).length;

    final tabs = <Widget>[
      FeedPage(
        notifications: _notifications,
        isLoading: _isLoadingNotifications,
        errorMessage: _notificationsError,
        onRefreshRequested: _loadNotifications,
      ),
      SearchPage(
        notifications: _notifications,
        isLoading: _isLoadingNotifications,
        errorMessage: _notificationsError,
      ),
      SettingsPage(
        supabaseState: widget.supabaseState,
        notificationListenerEnabled: _isNotificationListenerEnabled,
        isSyncingNotifications: _isSyncingNotifications,
        pendingSyncCount: pendingSyncCount,
        canSyncNow: widget.supabaseState.initialized && _currentUser != null,
        authEmail: _currentUser?.email,
        isEmailConfirmed: _isEmailConfirmed,
        isPasswordRecoveryMode: _isPasswordRecoveryMode,
        isAuthBusy: _isAuthBusy,
        onSignIn: _signIn,
        onSignUp: _signUp,
        onSignOut: _signOut,
        onRequestPasswordReset: _requestPasswordReset,
        onUpdateRecoveredPassword: _updateRecoveredPassword,
        onSyncNow: _syncPendingNotifications,
        onOpenNotificationSettings: () async {
          await _nativeBridge.openNotificationListenerSettings();
        },
      ),
    ];

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
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Buscar',
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