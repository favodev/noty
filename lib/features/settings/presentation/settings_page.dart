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
    required this.onSyncNow,
    required this.onOpenNotificationSettings,
  });

  final SupabaseBootstrapState supabaseState;
  final bool notificationListenerEnabled;
  final bool isSyncingNotifications;
  final int pendingSyncCount;
  final bool canSyncNow;
  final Future<void> Function() onSyncNow;
  final Future<void> Function() onOpenNotificationSettings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _wifiOnlySync = true;
  bool _backgroundSync = true;
  bool _minimalAnimations = true;

  @override
  Widget build(BuildContext context) {
    final status = _buildStatus(widget.supabaseState);
    final listenerStatus = _buildListenerStatus(widget.notificationListenerEnabled);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: <Widget>[
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