import 'package:noty/core/config/app_env.dart';
import 'package:noty/features/auth/data/supabase_auth_service.dart';
import 'package:noty/features/feed/data/local_notifications_repository.dart';
import 'package:noty/features/feed/data/mock_notifications.dart';
import 'package:noty/features/feed/data/native_notifications_bridge.dart';
import 'package:noty/features/feed/data/supabase_notifications_sync.dart';
import 'package:noty/features/feed/domain/notification_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotyShellLoadResult {
  const NotyShellLoadResult({
    required this.notifications,
    required this.listenerEnabled,
    this.errorMessage,
  });

  final List<NotificationItem> notifications;
  final bool listenerEnabled;
  final String? errorMessage;
}

class NotyShellSyncResult {
  const NotyShellSyncResult({
    required this.notifications,
    required this.completed,
  });

  final List<NotificationItem> notifications;
  final bool completed;
}

class NotyShellService {
  NotyShellService({
    SupabaseAuthService? authService,
    LocalNotificationsRepository? repository,
    NativeNotificationsBridge? nativeBridge,
    SupabaseNotificationsSync? supabaseSync,
  })  : _authService = authService ?? SupabaseAuthService(),
        _repository = repository ?? LocalNotificationsRepository(),
        _nativeBridge = nativeBridge ?? NativeNotificationsBridge(),
        _supabaseSync = supabaseSync ?? SupabaseNotificationsSync();

  final SupabaseAuthService _authService;
  final LocalNotificationsRepository _repository;
  final NativeNotificationsBridge _nativeBridge;
  final SupabaseNotificationsSync _supabaseSync;

  User? get currentUser => _authService.currentUser;

  bool get isEmailConfirmed => _authService.isEmailConfirmed;

  Stream<AuthState> authStateChanges() => _authService.authStateChanges();

  Future<void> dispose() => _repository.dispose();

  Future<NotyShellLoadResult> loadNotifications({
    required bool enableLocalPersistence,
  }) async {
    if (!enableLocalPersistence) {
      return NotyShellLoadResult(
        notifications: buildMockNotifications(),
        listenerEnabled: false,
      );
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

      return NotyShellLoadResult(
        notifications: notifications,
        listenerEnabled: listenerEnabled,
      );
    } catch (_) {
      return const NotyShellLoadResult(
        notifications: <NotificationItem>[],
        listenerEnabled: false,
        errorMessage: 'No pudimos cargar notificaciones locales.',
      );
    }
  }

  Future<NotyShellSyncResult> syncPendingNotifications({
    required bool enableLocalPersistence,
    required bool supabaseInitialized,
    required User? currentUser,
  }) async {
    if (!supabaseInitialized || !enableLocalPersistence || currentUser == null) {
      return const NotyShellSyncResult(
        notifications: <NotificationItem>[],
        completed: false,
      );
    }

    try {
      final pending = await _repository.getPendingSync(limit: 100);
      if (pending.isEmpty) {
        final notifications = await _repository.getAll();
        return NotyShellSyncResult(
          notifications: notifications,
          completed: true,
        );
      }

      final result = await _supabaseSync.sync(pending);

      if (result.syncedIds.isNotEmpty) {
        await _repository.markAsSynced(result.syncedIds);
      }

      for (final failure in result.failed) {
        await _repository.markAsSyncFailed(failure.notificationId, failure.message);
      }

      final refreshed = await _repository.getAll();
      return NotyShellSyncResult(
        notifications: refreshed,
        completed: true,
      );
    } catch (_) {
      return const NotyShellSyncResult(
        notifications: <NotificationItem>[],
        completed: false,
      );
    }
  }

  Future<void> signIn({
    required bool supabaseInitialized,
    required String email,
    required String password,
  }) async {
    _ensureSupabaseInitialized(supabaseInitialized);
    await _authService.signInWithPassword(
      email: _normalizeRequiredEmail(email),
      password: _normalizeRequiredPassword(password),
    );
  }

  Future<void> signUp({
    required bool supabaseInitialized,
    required String email,
    required String password,
  }) async {
    _ensureSupabaseInitialized(supabaseInitialized);
    await _authService.signUpWithPassword(
      email: _normalizeRequiredEmail(email),
      password: _normalizeRequiredPassword(password),
    );
  }

  Future<void> signOut({required bool supabaseInitialized}) async {
    _ensureSupabaseInitialized(supabaseInitialized);
    await _authService.signOut();
  }

  Future<void> requestPasswordReset({
    required bool supabaseInitialized,
    required String email,
  }) async {
    _ensureSupabaseInitialized(supabaseInitialized);
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw const _ShellValidationException('Ingresa un email valido.');
    }

    await _authService.sendPasswordResetEmail(
      email: normalizedEmail,
      redirectTo: AppEnv.supabaseAuthRedirect,
    );
  }

  Future<void> updateRecoveredPassword({
    required bool supabaseInitialized,
    required bool isPasswordRecoveryMode,
    required String password,
  }) async {
    _ensureSupabaseInitialized(supabaseInitialized);
    if (!isPasswordRecoveryMode) {
      throw const _ShellValidationException('No hay recuperacion activa.');
    }
    if (password.length < 8) {
      throw const _ShellValidationException(
        'La nueva password debe tener al menos 8 caracteres.',
      );
    }

    await _authService.updatePassword(password);
  }

  Future<void> openNotificationListenerSettings() async {
    await _nativeBridge.openNotificationListenerSettings();
  }

  Future<List<Map<String, String>>> getInstalledApps() async {
    return _nativeBridge.getInstalledApps();
  }

  Future<List<String>> getMonitoredPackages() async {
    return _nativeBridge.getMonitoredPackages();
  }

  Future<void> updateMonitoredPackages(List<String> packages) async {
    await _nativeBridge.updateMonitoredPackages(packages);
  }

  Future<void> clearLocalHistory() async {
    await _repository.deleteAll();
  }

  void _ensureSupabaseInitialized(bool initialized) {
    if (!initialized) {
      throw const _ShellValidationException('Supabase no está inicializado.');
    }
  }

  String _normalizeRequiredEmail(String email) {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw const _ShellValidationException('Email y password son obligatorios.');
    }
    return normalizedEmail;
  }

  String _normalizeRequiredPassword(String password) {
    if (password.isEmpty) {
      throw const _ShellValidationException('Email y password son obligatorios.');
    }
    return password;
  }
}

class _ShellValidationException implements Exception {
  const _ShellValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
