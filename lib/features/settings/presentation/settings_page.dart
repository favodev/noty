import 'package:flutter/material.dart';
import 'package:noty/core/supabase/supabase_bootstrap.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.supabaseState,
    required this.currentThemeMode,
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
    required this.onOpenAppSelection,
    this.onThemeModeChanged,
  });

  final SupabaseBootstrapState supabaseState;
  final ThemeMode currentThemeMode;
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
  final void Function() onOpenAppSelection;
  final void Function(ThemeMode mode)? onThemeModeChanged;

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
        const _SettingsHeroCard(
          title: 'Ajustes',
          description: 'Gestion� tu cuenta, apariencia y permisos desde un solo lugar.',
        ),
        const SizedBox(height: 20),
        const _SectionHeader(
          title: 'Cuenta',
          subtitle: 'Estado de tu sesión y respaldo seguro.',
          icon: Icons.account_circle_outlined,
        ),
        const SizedBox(height: 12),
        _AccountCard(
          email: widget.authEmail,
          isEmailConfirmed: widget.isEmailConfirmed,
          isAuthenticated: isAuthenticated,
          onSignOut: widget.isAuthBusy || !isAuthenticated
              ? null
              : () => _handleAuthAction(
                    widget.onSignOut,
                    successMessage: 'Sesi�n cerrada',
                  ),
        ),
        if (!isAuthenticated) ...<Widget>[
          const SizedBox(height: 20),
          const _SectionHeader(
            title: 'Acceder',
            subtitle: 'Inici� sesi�n o cre� una cuenta para guardar tu historial.',
            icon: Icons.login_rounded,
          ),
          const SizedBox(height: 12),
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
              successMessage: 'Sesi�n iniciada',
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
              successMessage: 'Email de recuperaci�n enviado',
            ),
          ),
        ],
        if (widget.isPasswordRecoveryMode) ...<Widget>[
          const SizedBox(height: 20),
          const _SectionHeader(
            title: 'Recuperar password',
            subtitle: 'Defin� una nueva contrase�a para tu cuenta.',
            icon: Icons.lock_reset_outlined,
          ),
          const SizedBox(height: 12),
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
        const SizedBox(height: 20),
        const _SectionHeader(
          title: 'Apariencia',
          subtitle: 'Eleg� c�mo quer�s ver Noty durante el d�a.',
          icon: Icons.palette_outlined,
        ),
        const SizedBox(height: 12),
        _ThemeModeCard(
          currentThemeMode: widget.currentThemeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
        ),
        const SizedBox(height: 20),
        const _SectionHeader(
          title: 'Acceso a notificaciones',
          subtitle: 'Configurá qué apps escuchar y los permisos de Android.',
          icon: Icons.notifications_outlined,
        ),
        const SizedBox(height: 12),
        _NotificationPermissionCard(
          isEnabled: widget.notificationListenerEnabled,
          onOpenSettings: widget.onOpenNotificationSettings,
          onOpenAppSelection: widget.onOpenAppSelection,
        ),
      ],
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

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.tune_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({
    required this.currentThemeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode currentThemeMode;
  final void Function(ThemeMode mode)? onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Eleg� c�mo quer�s ver Noty.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('Sistema'),
                ),
              ],
              selected: <ThemeMode>{currentThemeMode},
              onSelectionChanged: (selection) {
                final mode = selection.first;
                onThemeModeChanged?.call(mode);
              },
            ),
          ],
        ),
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
    final colorScheme = theme.colorScheme;
    final statusColor = isAuthenticated ? colorScheme.primary : colorScheme.error;
    final badgeColor = isAuthenticated
        ? (isEmailConfirmed ? colorScheme.primary : colorScheme.tertiary)
        : colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isAuthenticated ? Icons.check_circle : Icons.cancel,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        isAuthenticated ? 'Cuenta conectada' : 'Sin cuenta conectada',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAuthenticated
                            ? (email ?? 'Sin email')
                            : 'Inici� sesi�n para sincronizar tu historial.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
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
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesi�n'),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!showForm) ...<Widget>[
              Text(
                'Sincronizaci�n en la nube',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Inici� sesi�n o cre� una cuenta para sincronizar tus notificaciones.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (!supabaseInitialized) ...<Widget>[
                const SizedBox(height: 10),
                const _InlineNotice(
                  icon: Icons.info_outline,
                  message: 'Supabase no est� configurado todav�a.',
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: supabaseInitialized ? onToggleForm : null,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Acceder'),
                ),
              ),
            ] else ...<Widget>[
              Text(
                'Ingres� con tu cuenta',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
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
                      child: const Text('Iniciar sesi�n'),
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
                  child: const Text('Olvid� mi password'),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Recuperaci�n de password',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingres� tu nueva password (m�nimo 8 caracteres).',
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
              child: FilledButton.icon(
                onPressed: isAuthBusy ? null : onUpdatePassword,
                icon: const Icon(Icons.lock_reset),
                label: const Text('Actualizar password'),
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
    required this.onOpenAppSelection,
  });

  final bool isEnabled;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAppSelection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = isEnabled ? colorScheme.primary : colorScheme.tertiary;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEnabled ? Icons.check_circle : Icons.warning,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          isEnabled ? 'Captura activa' : 'Permiso pendiente',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEnabled
                              ? 'Android ya está entregando notificaciones a Noty.'
                              : 'Necesitás habilitar el acceso para empezar a guardar notificaciones.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_applications),
                  label: const Text('Abrir ajustes de Android'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onOpenAppSelection,
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Seleccionar apps a monitorear'),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
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
