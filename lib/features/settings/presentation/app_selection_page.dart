import 'package:flutter/material.dart';

class AppSelectionPage extends StatefulWidget {
  const AppSelectionPage({
    super.key,
    required this.onGetInstalledApps,
    required this.onGetMonitoredPackages,
    required this.onSavePackages,
  });

  final Future<List<Map<String, String>>> Function() onGetInstalledApps;
  final Future<List<String>> Function() onGetMonitoredPackages;
  final Future<void> Function(List<String> packages) onSavePackages;

  @override
  State<AppSelectionPage> createState() => _AppSelectionPageState();
}

class _AppSelectionPageState extends State<AppSelectionPage> {
  bool _isLoading = true;
  List<Map<String, String>> _apps = <Map<String, String>>[];
  final Set<String> _selectedPackages = <String>{};

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    try {
      final apps = await widget.onGetInstalledApps();
      final monitored = await widget.onGetMonitoredPackages();
      
      setState(() {
        _apps = apps;
        if (monitored.isEmpty) {
          // If no settings exist yet, select all by default (matches native logic)
          _selectedPackages.addAll(apps.map((e) => e['packageName']!));
        } else {
          _selectedPackages.addAll(monitored);
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    await widget.onSavePackages(_selectedPackages.toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferencias de apps guardadas')),
      );
      Navigator.of(context).pop();
    }
  }

  void _toggleAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedPackages.addAll(_apps.map((e) => e['packageName']!));
      } else {
        _selectedPackages.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selectedPackages.length == _apps.length && _apps.isNotEmpty;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtro de Apps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _save,
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _apps.isEmpty
              ? const Center(child: Text('No se encontraron apps.'))
              : Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('Seleccionar todas', style: TextStyle(fontWeight: FontWeight.bold)),
                      value: allSelected,
                      onChanged: _toggleAll,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _apps.length,
                        itemBuilder: (context, index) {
                          final app = _apps[index];
                          final packageName = app['packageName']!;
                          final appName = app['appName'] ?? packageName;
                          final isSelected = _selectedPackages.contains(packageName);

                          return CheckboxListTile(
                            title: Text(appName),
                            subtitle: Text(packageName, style: const TextStyle(fontSize: 11)),
                            value: isSelected,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedPackages.add(packageName);
                                } else {
                                  _selectedPackages.remove(packageName);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

