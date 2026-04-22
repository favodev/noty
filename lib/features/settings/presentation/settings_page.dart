import 'package:flutter/material.dart';
import 'package:noty/core/supabase/supabase_bootstrap.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.supabaseState,
  });

  final SupabaseBootstrapState supabaseState;

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: <Widget>[
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
                        status.subtitle,
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