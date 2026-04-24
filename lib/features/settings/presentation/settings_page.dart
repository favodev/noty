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
  bool _minimalAnimations = true;

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
    final status = _buildStatus(widget.supabaseState);
    final listenerStatus = _buildListenerStatus(widget.notificationListenerEnabled);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: <Widget>[
        Text(
          'Cuenta',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.authEmail == null
                            ? 'Sesion no iniciada'
                            : widget.isEmailConfirmed
                                ? 'Sesion activa: ${widget.authEmail}'
                                : 'Sesion activa sin confirmar email: ${widget.authEmail}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (widget.authEmail == null
                                ? const Color(0xFFB91C1C)
                                : widget.isEmailConfirmed
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFB45309))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.authEmail == null
                            ? 'Sin sesion'
                            : widget.isEmailConfirmed
                                ? 'Verificado'
                                : 'No verificado',
                        style: TextStyle(
                          color: widget.authEmail == null
                              ? const Color(0xFFB91C1C)
                              : widget.isEmailConfirmed
                                  ? const Color(0xFF047857)
                                  : const Color(0xFFB45309),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const <String>[AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'tuemail@dominio.com',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const <String>[AutofillHints.password],
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: '********',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: widget.supabaseState.initialized && !widget.isAuthBusy
                          ? () => _handleAuthAction(
                                () => widget.onSignIn(
                                  _emailController.text,
                                  _passwordController.text,
                                ),
                                successMessage: 'Sesion iniciada',
                              )
                          : null,
                      icon: _buildAuthButtonIcon(),
                      label: const Text('Iniciar sesion'),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.supabaseState.initialized && !widget.isAuthBusy
                          ? () => _handleAuthAction(
                                () => widget.onSignUp(
                                  _emailController.text,
                                  _passwordController.text,
                                ),
                                successMessage: 'Cuenta creada',
                              )
                          : null,
                      icon: _buildAuthButtonIcon(),
                      label: const Text('Crear cuenta'),
                    ),
                    TextButton.icon(
                      onPressed: widget.supabaseState.initialized &&
                              !widget.isAuthBusy &&
                              widget.authEmail != null
                          ? () => _handleAuthAction(
                                widget.onSignOut,
                                successMessage: 'Sesion cerrada',
                              )
                          : null,
                      icon: _buildAuthButtonIcon(),
                      label: const Text('Cerrar sesion'),
                    ),
                    TextButton.icon(
                      onPressed: widget.supabaseState.initialized && !widget.isAuthBusy
                          ? () => _handleAuthAction(
                                () => widget.onRequestPasswordReset(
                                  _emailController.text,
                                ),
                                successMessage: 'Email de recuperacion enviado',
                              )
                          : null,
                      icon: const Icon(Icons.mark_email_read_outlined, size: 16),
                      label: const Text('Recuperar password'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (widget.isPasswordRecoveryMode) ...<Widget>[
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Recuperacion detectada',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Define una nueva password para completar el recovery.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _recoveryPasswordController,
                    obscureText: true,
                    autofillHints: const <String>[AutofillHints.newPassword],
                    decoration: const InputDecoration(
                      labelText: 'Nueva password',
                      hintText: 'Minimo 8 caracteres',
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: !widget.isAuthBusy
                        ? () => _handleAuthAction(
                              () => widget.onUpdateRecoveredPassword(
                                _recoveryPasswordController.text,
                              ),
                              successMessage: 'Password actualizada',
                            )
                        : null,
                    icon: _buildAuthButtonIcon(),
                    label: const Text('Actualizar password'),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Permisos Android',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Acceso a notificaciones',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            listenerStatus.subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF64748B),
                                ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: listenerStatus.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        listenerStatus.label,
                        style: TextStyle(
                          color: listenerStatus.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: widget.onOpenNotificationSettings,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir ajustes de acceso'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Sincronizacion',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Supabase',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${status.subtitle} · Pendientes: ${widget.pendingSyncCount}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(
                      color: status.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: widget.canSyncNow && !widget.isSyncingNotifications
                ? widget.onSyncNow
                : null,
            icon: widget.isSyncingNotifications
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(
              widget.isSyncingNotifications ? 'Sincronizando...' : 'Sincronizar ahora',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: <Widget>[
              SwitchListTile(
                value: _wifiOnlySync,
                onChanged: (value) {
                  setState(() {
                    _wifiOnlySync = value;
                  });
                },
                title: const Text('Solo sincronizar en Wi-Fi'),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: _backgroundSync,
                onChanged: (value) {
                  setState(() {
                    _backgroundSync = value;
                  });
                },
                title: const Text('Sync en background'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Animaciones',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Card(
          child: SwitchListTile(
            value: _minimalAnimations,
            onChanged: (value) {
              setState(() {
                _minimalAnimations = value;
              });
            },
            title: const Text('Animaciones minimalistas'),
            subtitle: const Text('Transiciones cortas para fluidez y bajo costo.'),
          ),
        ),
      ],
    );
  }

  _SupabaseStatusViewModel _buildStatus(SupabaseBootstrapState state) {
    if (!state.configured) {
      return const _SupabaseStatusViewModel(
        label: 'Pendiente',
        subtitle: 'Estado actual: sin configurar',
        color: Color(0xFFB91C1C),
      );
    }

    if (state.initialized) {
      return const _SupabaseStatusViewModel(
        label: 'Conectado',
        subtitle: 'Estado actual: inicializado correctamente',
        color: Color(0xFF047857),
      );
    }

    return const _SupabaseStatusViewModel(
      label: 'Error',
      subtitle: 'Estado actual: fallo en inicializacion',
      color: Color(0xFFB91C1C),
    );
  }

  _SupabaseStatusViewModel _buildListenerStatus(bool isEnabled) {
    if (isEnabled) {
      return const _SupabaseStatusViewModel(
        label: 'Habilitado',
        subtitle: 'Estado actual: listener activo',
        color: Color(0xFF047857),
      );
    }

    return const _SupabaseStatusViewModel(
      label: 'Pendiente',
      subtitle: 'Estado actual: listener deshabilitado',
      color: Color(0xFFB91C1C),
    );
  }

  Widget _buildAuthButtonIcon() {
    if (widget.isAuthBusy) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return const Icon(Icons.lock_open, size: 16);
  }

  Future<void> _handleAuthAction(
    Future<String?> Function() action, {
    required String successMessage,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await action();

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? successMessage),
        backgroundColor: error == null ? const Color(0xFF047857) : null,
      ),
    );
  }
}

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