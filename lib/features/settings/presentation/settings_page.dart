import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.currentThemeMode,
    required this.notificationListenerEnabled,
    required this.nativeDiagnostics,
    required this.isDataBusy,
    required this.onOpenNotificationSettings,
    required this.onOpenAppSelection,
    required this.onExportHistory,
    required this.onImportHistory,
    required this.onClearHistory,
    this.onThemeModeChanged,
  });

  final ThemeMode currentThemeMode;
  final bool notificationListenerEnabled;
  final Map<String, Object?> nativeDiagnostics;
  final bool isDataBusy;
  final Future<void> Function() onOpenNotificationSettings;
  final VoidCallback onOpenAppSelection;
  final Future<void> Function() onExportHistory;
  final Future<void> Function() onImportHistory;
  final Future<void> Function() onClearHistory;
  final void Function(ThemeMode mode)? onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: <Widget>[
        Text(
          'Ajustes',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Todo queda guardado solo en este teléfono. Para cambiar de móvil, exporta e importa tu historial.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _NotificationPermissionCard(
          isEnabled: notificationListenerEnabled,
          diagnostics: nativeDiagnostics,
          onOpenSettings: onOpenNotificationSettings,
          onOpenAppSelection: onOpenAppSelection,
        ),
        const SizedBox(height: 12),
        _DataPortabilityCard(
          isBusy: isDataBusy,
          onExportHistory: onExportHistory,
          onImportHistory: onImportHistory,
        ),
        const SizedBox(height: 12),
        _ThemeCard(
          currentThemeMode: currentThemeMode,
          onThemeModeChanged: onThemeModeChanged,
        ),
        const SizedBox(height: 12),
        _DataManagementCard(isBusy: isDataBusy, onClearHistory: onClearHistory),
      ],
    );
  }
}

class _NotificationPermissionCard extends StatelessWidget {
  const _NotificationPermissionCard({
    required this.isEnabled,
    required this.diagnostics,
    required this.onOpenSettings,
    required this.onOpenAppSelection,
  });

  final bool isEnabled;
  final Map<String, Object?> diagnostics;
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
                    isEnabled ? Icons.check_circle : Icons.warning_rounded,
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
                            : 'Habilita el acceso para empezar a guardar notificaciones.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (diagnostics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _formatDiagnostics(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
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

  String _formatDiagnostics() {
    final connected = _formatEpoch(diagnostics['listenerConnectedAt']);
    final posted = _formatEpoch(diagnostics['lastPostedAt']);
    final captured = _formatEpoch(diagnostics['lastCapturedAt']);
    final listenerConnected = diagnostics['listenerConnected'] == true;
    final lastPackage = diagnostics['lastPackage']?.toString() ?? '';
    final postedCount = diagnostics['postedCount']?.toString() ?? '0';
    final capturedCount = diagnostics['capturedCount']?.toString() ?? '0';
    final lastError = diagnostics['lastError']?.toString() ?? '';

    return [
      'Diagnóstico: conectado $connected · recibido $posted · guardado $captured',
      'Servicio Android: ${listenerConnected ? 'conectado' : 'reconectando'}',
      'Eventos: $postedCount recibidos / $capturedCount guardados',
      if (lastPackage.isNotEmpty) 'Último paquete: $lastPackage',
      if (lastError.isNotEmpty) 'Último error: $lastError',
    ].join('\n');
  }

  String _formatEpoch(Object? value) {
    final raw = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (raw == null || raw <= 0) {
      return 'nunca';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(raw);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _DataPortabilityCard extends StatelessWidget {
  const _DataPortabilityCard({
    required this.isBusy,
    required this.onExportHistory,
    required this.onImportHistory,
  });

  final bool isBusy;
  final Future<void> Function() onExportHistory;
  final Future<void> Function() onImportHistory;

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
              'Exportar e importar',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Crea un archivo JSON para respaldar tu historial local o impórtalo en otro teléfono.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isBusy ? null : onExportHistory,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Exportar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onImportHistory,
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('Importar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
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
              'Tema',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Claro'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Oscuro'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: <ThemeMode>{currentThemeMode},
              onSelectionChanged: onThemeModeChanged == null
                  ? null
                  : (selection) => onThemeModeChanged!(selection.first),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataManagementCard extends StatelessWidget {
  const _DataManagementCard({
    required this.isBusy,
    required this.onClearHistory,
  });

  final bool isBusy;
  final Future<void> Function() onClearHistory;

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
              'Borrar historial local',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Elimina todas las notificaciones guardadas en este dispositivo. No hay copia en la nube.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isBusy ? null : () => _confirmClear(context),
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('Vaciar base de datos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar historial?'),
        content: const Text(
          'Vas a eliminar todas las notificaciones locales. Si no exportaste antes, no se pueden recuperar. ¿Estás seguro?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Si, borrar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onClearHistory();
    }
  }
}
