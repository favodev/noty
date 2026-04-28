import 'package:flutter/material.dart';
import 'package:noty/core/supabase/supabase_bootstrap.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.supabaseState,
    required this.notificationListenerEnabled,
    required this.authEmail,
    required this.isEmailConfirmed,
    required this.isPasswordRecoveryMode,
    required this.isAuthBusy,
    required this.onSignIn,
    required this.onSignUp,
    required this.onSignOut,
    required this.onRequestPasswordReset,
    required this.onUpdateRecoveredPassword,
    required this.onOpenNotificationSettings,
  });

  final SupabaseBootstrapState supabaseState;
  final bool notificationListenerEnabled;
  final String? authEmail;
  final bool isEmailConfirmed;
  final bool isPasswordRecoveryMode;
  final bool isAuthBusy;
  final Future<String?> Function(String email, String password) onSignIn;
  final Future<String?> Function(String email, String password) onSignUp;
  final Future<String?> Function() onSignOut;
  final Future<String?> Function(String email) onRequestPasswordReset;
  final Future<String?> Function(String newPassword) onUpdateRecoveredPassword;
  final Future<void> Function() onOpenNotificationSettings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _recoveryPasswordController;

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

  Future<void> _handleAuthAction(
    Future<String?> Function() action, {
    required String successMessage,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final error = await action();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? successMessage),
        backgroundColor: error == null ? colorScheme.primary : null,
      ),
    );
  }
}

// Widgets
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
    final colorScheme = theme.colorScheme;
    final statusColor = isAuthenticated ? colorScheme.primary : colorScheme.error;
    final badgeColor = isAuthenticated
        ? (isEmailConfirmed ? colorScheme.primary : colorScheme.tertiary)
        : colorScheme.error;
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
                  color: statusColor,
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
                  color: badgeColor,
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
    final colorScheme = theme.colorScheme;
    final statusColor = isEnabled ? colorScheme.primary : colorScheme.tertiary;
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
                  color: statusColor,
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
                  color: statusColor,
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
