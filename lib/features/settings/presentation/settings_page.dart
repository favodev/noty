import 'package:flutter/material.dart';
import 'package:noty/features/shell/data/noty_shell_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.currentThemeMode,
    required this.notificationListenerEnabled,
    required this.nativeDiagnostics,
    required this.mediaCaptureSettings,
    required this.isDataBusy,
    required this.onOpenNotificationSettings,
    required this.onOpenAppSelection,
    required this.onExportHistory,
    required this.onImportHistory,
    required this.onClearHistory,
    required this.onMediaCaptureSettingsChanged,
    this.onThemeModeChanged,
  });

  final ThemeMode currentThemeMode;
  final bool notificationListenerEnabled;
  final Map<String, Object?> nativeDiagnostics;
  final MediaCaptureSettings mediaCaptureSettings;
  final bool isDataBusy;
  final Future<void> Function() onOpenNotificationSettings;
  final VoidCallback onOpenAppSelection;
  final Future<void> Function() onExportHistory;
  final Future<void> Function() onImportHistory;
  final Future<void> Function() onClearHistory;
  final Future<void> Function(MediaCaptureSettings settings)
  onMediaCaptureSettingsChanged;
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
        _MediaCaptureCard(
          settings: mediaCaptureSettings,
          onChanged: onMediaCaptureSettingsChanged,
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
    final listenerConnected = diagnostics['listenerConnected'] == true;
    final isCapturing = isEnabled && listenerConnected;
    final statusColor = isCapturing
        ? colorScheme.primary
        : isEnabled
        ? colorScheme.error
        : colorScheme.tertiary;
    final statusIcon = isCapturing ? Icons.check_circle : Icons.warning_rounded;
    final statusTitle = isCapturing
        ? 'Captura activa'
        : isEnabled
        ? 'Servicio desconectado'
        : 'Permiso pendiente';
    final statusBody = isCapturing
        ? 'Android ya está entregando notificaciones a Noty.'
        : isEnabled
        ? 'El permiso está activo, pero Android no tiene conectado el servicio de Noty.'
        : 'Habilita el acceso para empezar a guardar notificaciones.';

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
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        statusTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusBody,
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
            const SizedBox(height: 12),
            _DiagnosticsPanel(diagnostics: diagnostics),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticsPanel extends StatelessWidget {
  const _DiagnosticsPanel({required this.diagnostics});

  final Map<String, Object?> diagnostics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <String, String>{
      'Pantalla activa': _boolText(diagnostics['isInteractive']),
      'Dispositivo bloqueado': _boolText(diagnostics['isDeviceLocked']),
      'Keyguard activo': _boolText(diagnostics['isKeyguardLocked']),
      'Eventos recibidos': '${diagnostics['postedCount'] ?? 0}',
      'Eventos guardados': '${diagnostics['capturedCount'] ?? 0}',
      'Desconexiones': '${diagnostics['listenerDisconnectedCount'] ?? 0}',
      'Activas vistas': '${diagnostics['lastActiveNotificationCount'] ?? 0}',
      'Apps activas': _emptyText(diagnostics['lastActivePackages']),
      'Omitidas': '${diagnostics['skippedCount'] ?? 0}',
      'Última omitida': _emptyText(diagnostics['lastSkippedPackage']),
      'Motivo omitida': _emptyText(diagnostics['lastSkippedReason']),
      'Hora omitida': _timeText(diagnostics['lastSkippedAt']),
      'Última app': _emptyText(diagnostics['lastPackage']),
      'Último evento': _timeText(diagnostics['lastPostedAt']),
      'Última captura': _timeText(diagnostics['lastCapturedAt']),
      'Última sync activa': _timeText(diagnostics['lastActiveSyncAt']),
      'Última desconexión': _timeText(diagnostics['listenerDisconnectedAt']),
    };

    final lastError = '${diagnostics['lastError'] ?? ''}'.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Diagnóstico',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final row in rows.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        row.key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        row.value,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (lastError.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Error: $lastError',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _boolText(Object? value) => value == true ? 'Sí' : 'No';

  String _emptyText(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '—' : text;
  }

  String _timeText(Object? value) {
    final epochMs = value is int
        ? value
        : value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');

    if (epochMs == null || epochMs <= 0) {
      return '—';
    }

    final time = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
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

class _MediaCaptureCard extends StatelessWidget {
  const _MediaCaptureCard({required this.settings, required this.onChanged});

  final MediaCaptureSettings settings;
  final Future<void> Function(MediaCaptureSettings settings) onChanged;

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
              'Imágenes y stickers',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Solo se guardan si Android entrega la imagen dentro de la notificación. Los archivos quedan en almacenamiento privado de Noty.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Guardar stickers'),
              subtitle: const Text('Ideal para stickers y previews pequeñas.'),
              value: settings.saveStickers,
              onChanged: (value) => onChanged(
                MediaCaptureSettings(
                  saveStickers: value,
                  savePhotos: settings.savePhotos,
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Guardar fotos'),
              subtitle: const Text('Puede ocupar bastante más espacio.'),
              value: settings.savePhotos,
              onChanged: (value) => onChanged(
                MediaCaptureSettings(
                  saveStickers: settings.saveStickers,
                  savePhotos: value,
                ),
              ),
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
