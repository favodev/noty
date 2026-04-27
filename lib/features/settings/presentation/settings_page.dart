import 'package:flutter/material.dart';
import 'package:noty/core/supabase/supabase_bootstrap.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.supabaseState,
    required this.notificationListenerEnabled,
    required this.isSyncingNotifications,
    required this.pendingSyncCount,
    required this.canSyncNow,
    required this.authEmail,
    required this.isEmailConfirmed,
    required this.isPasswordRecoveryMode,
    required this.isAuthBusy,
    required this.onSignIn,
    required this.onSignUp,
    required this.onSignOut,
    required this.onRequestPasswordReset,
    required this.onUpdateRecoveredPassword,
    required this.onSyncNow,
    required this.onOpenNotificationSettings,
  });

  final SupabaseBootstrapState supabaseState;
  final bool notificationListenerEnabled;
  final bool isSyncingNotifications;
  final int pendingSyncCount;
  final bool canSyncNow;
  final String? authEmail;
  final bool isEmailConfirmed;
  final bool isPasswordRecoveryMode;
  final bool isAuthBusy;
  final Future<String?> Function(String email, String password) onSignIn;
  final Future<String?> Function(String email, String password) onSignUp;
  final Future<String?> Function() onSignOut;
  final Future<String?> Function(String email) onRequestPasswordReset;
  final Future<String?> Function(String newPassword) onUpdateRecoveredPassword;
  final Future<void> Function() onSyncNow;
  final Future<void> Function() onOpenNotificationSettings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _recoveryPasswordController;

  bool _wifiOnlySync = true;
  bool _backgroundSync = true;
  bool _showAuthForm = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _recoveryPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _recoveryPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = widget.authEmail != null;
    final status = _buildStatus(widget.supabaseState);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: <Widget>[
        // Sección 1: Cuenta
        _buildSectionTitle('Cuenta'),
        const SizedBox(height: 10),
        _AccountCard(
          email: widget.authEmail,
          isEmailConfirmed: widget.isEmailConfirmed,
          isAuthenticated: isAuthenticated,
          onSignOut: widget.isAuthBusy || !isAuthenticated
              ? null
              : () => _handleAuthAction(
                    widget.onSignOut,
                    successMessage: 'Sesion cerrada',
                  ),
        ),

        // Sección 2: Autenticación (solo si no hay sesión)
        if (!isAuthenticated) ...<Widget>[
          const SizedBox(height: 20),
          _buildSectionTitle('Acceder'),
          const SizedBox(height: 10),
          _AuthFormCard(
            supabaseInitialized: widget.supabaseState.initialized,
            isAuthBusy: widget.isAuthBusy,
            showForm: _showAuthForm,
            onToggleForm: () {
              setState(() {
                _showAuthForm = !_showAuthForm;
              });
            },
            emailController: _emailController,
            passwordController: _passwordController,
            onSignIn: () => _handleAuthAction(
              () => widget.onSignIn(
                _emailController.text,
                _passwordController.text,
              ),
              successMessage: 'Sesion iniciada',
            ),
            onSignUp: () => _handleAuthAction(
              () => widget.onSignUp(
                _emailController.text,
                _passwordController.text,
              ),
              successMessage: 'Cuenta creada',
            ),
            onRequestPasswordReset: () => _handleAuthAction(
              () => widget.onRequestPasswordReset(_emailController.text),
              successMessage: 'Email de recuperacion enviado',
            ),
          ),
        ],

        // Sección 3: Recuperación de password
        if (widget.isPasswordRecoveryMode) ...<Widget>[
          const SizedBox(height: 20),
          _buildSectionTitle('Recuperar password'),
          const SizedBox(height: 10),
          _PasswordRecoveryCard(
            isAuthBusy: widget.isAuthBusy,
            controller: _recoveryPasswordController,
            onUpdatePassword: () => _handleAuthAction(
              () => widget.onUpdateRecoveredPassword(
                _recoveryPasswordController.text,
              ),
              successMessage: 'Password actualizada',
            ),
          ),
        ],

        // Sección 4: Permisos Android
        const SizedBox(height: 20),
        _buildSectionTitle('Acceso a notificaciones'),
        const SizedBox(height: 10),
        _NotificationPermissionCard(
          isEnabled: widget.notificationListenerEnabled,
          onOpenSettings: widget.onOpenNotificationSettings,
        ),

        // Sección 5: Sincronización
        const SizedBox(height: 20),
        _buildSectionTitle('Sincronizacion'),
        const SizedBox(height: 10),
        _SyncCard(
          status: status,
          pendingCount: widget.pendingSyncCount,
          canSyncNow: widget.canSyncNow,
          isSyncing: widget.isSyncingNotifications,
          onSyncNow: widget.onSyncNow,
        ),

        // Sección 6: Opciones de sync
        const SizedBox(height: 10),
        _SyncOptionsCard(
          wifiOnly: _wifiOnlySync,
          backgroundSync: _backgroundSync,
          onWifiOnlyChanged: (value) => setState(() => _wifiOnlySync = value),
          onBackgroundSyncChanged: (value) => setState(() => _backgroundSync = value),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  _SupabaseStatusViewModel _buildStatus(SupabaseBootstrapState state) {
    if (!state.configured) {
      return const _SupabaseStatusViewModel(
        label: 'Pendiente',
        subtitle: 'Sin configurar',
        color: Colors.orange,
      );
    }
    if (state.initialized) {
      return const _SupabaseStatusViewModel(
        label: 'Conectado',
        subtitle: 'Inicializado',
        color: Colors.green,
      );
    }
    return const _SupabaseStatusViewModel(
      label: 'Error',
      subtitle: 'Fallo',
      color: Colors.red,
    );
  }

  Future<void> _handleAuthAction(
    Future<String?> Function() action, {
    required String successMessage,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await action();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? successMessage),
        backgroundColor: error == null ? Colors.green : null,
      ),
    );
  }
}

// View Models
class _SupabaseStatusViewModel {
  const _SupabaseStatusViewModel({
    required this.label,
    required this.subtitle,
    required this.color,
  });
  final String label;
  final String subtitle;
  final Color color;
}

// Widgets
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.email,
    required this.isEmailConfirmed,
    required this.isAuthenticated,
    required this.onSignOut,
  });

  final String? email;
  final bool isEmailConfirmed;
  final bool isAuthenticated;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  isAuthenticated ? Icons.check_circle : Icons.cancel,
                  color: isAuthenticated ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAuthenticated
                        ? (email ?? 'Sin email')
                        : 'Sin sesion',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                _StatusBadge(
                  label: isAuthenticated
                      ? (isEmailConfirmed ? 'Verificado' : 'Sin verificar')
                      : 'Desconectado',
                  color: isAuthenticated
                      ? (isEmailConfirmed ? Colors.green : Colors.orange)
                      : Colors.red,
                ),
              ],
            ),
            if (isAuthenticated) ...<Widget>[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSignOut,
                  child: const Text('Cerrar sesion'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AuthFormCard extends StatelessWidget {
  const _AuthFormCard({
    required this.supabaseInitialized,
    required this.isAuthBusy,
    required this.showForm,
    required this.onToggleForm,
    required this.emailController,
    required this.passwordController,
    required this.onSignIn,
    required this.onSignUp,
    required this.onRequestPasswordReset,
  });

  final bool supabaseInitialized;
  final bool isAuthBusy;
  final bool showForm;
  final VoidCallback onToggleForm;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;
  final VoidCallback onRequestPasswordReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!showForm) ...<Widget>[
              Text(
                'Inicia sesion o crea una cuenta para sincronizar tus notificaciones.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: supabaseInitialized ? onToggleForm : null,
                  child: const Text('Acceder'),
                ),
              ),
            ] else ...<Widget>[
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'tu@email.com',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton(
                      onPressed: isAuthBusy ? null : onSignIn,
                      child: const Text('Iniciar sesion'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isAuthBusy ? null : onSignUp,
                      child: const Text('Crear cuenta'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: isAuthBusy ? null : onRequestPasswordReset,
                  child: const Text('Olvide mi password'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: onToggleForm,
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PasswordRecoveryCard extends StatelessWidget {
  const _PasswordRecoveryCard({
    required this.isAuthBusy,
    required this.controller,
    required this.onUpdatePassword,
  });

  final bool isAuthBusy;
  final TextEditingController controller;
  final VoidCallback onUpdatePassword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Recuperacion de password',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa tu nueva password (minimo 8 caracteres).',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva password',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isAuthBusy ? null : onUpdatePassword,
                child: const Text('Actualizar password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationPermissionCard extends StatelessWidget {
  const _NotificationPermissionCard({
    required this.isEnabled,
    required this.onOpenSettings,
  });

  final bool isEnabled;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  isEnabled ? Icons.check_circle : Icons.warning,
                  color: isEnabled ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEnabled
                        ? 'Notificaciones capturadas'
                        : 'Sin acceso a notificaciones',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _StatusBadge(
                  label: isEnabled ? 'Activo' : 'Inactivo',
                  color: isEnabled ? Colors.green : Colors.orange,
                ),
              ],
            ),
            if (!isEnabled) ...<Widget>[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onOpenSettings,
                  child: const Text('Habilitar acceso'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({
    required this.status,
    required this.pendingCount,
    required this.canSyncNow,
    required this.isSyncing,
    required this.onSyncNow,
  });

  final _SupabaseStatusViewModel status;
  final int pendingCount;
  final bool canSyncNow;
  final bool isSyncing;
  final VoidCallback onSyncNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Icon(
              status.label == 'Conectado' ? Icons.cloud_done : Icons.cloud_off,
              color: status.color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Supabase',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${status.subtitle} · $pendingCount pendiente${pendingCount == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _StatusBadge(
              label: status.label,
              color: status.color,
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncOptionsCard extends StatelessWidget {
  const _SyncOptionsCard({
    required this.wifiOnly,
    required this.backgroundSync,
    required this.onWifiOnlyChanged,
    required this.onBackgroundSyncChanged,
  });

  final bool wifiOnly;
  final bool backgroundSync;
  final ValueChanged<bool> onWifiOnlyChanged;
  final ValueChanged<bool> onBackgroundSyncChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          SwitchListTile(
            value: wifiOnly,
            onChanged: onWifiOnlyChanged,
            title: const Text('Solo con Wi-Fi'),
            subtitle: const Text('Ahorro de datos moviles'),
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: backgroundSync,
            onChanged: onBackgroundSyncChanged,
            title: const Text('Sincronizacion en background'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}