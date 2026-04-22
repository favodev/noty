import 'package:flutter/material.dart';
import 'package:noty/core/supabase/supabase_bootstrap.dart';
import 'package:noty/features/feed/presentation/feed_page.dart';
import 'package:noty/features/search/presentation/search_page.dart';
import 'package:noty/features/settings/presentation/settings_page.dart';

class NotyShell extends StatefulWidget {
  const NotyShell({
    super.key,
    required this.supabaseState,
  });

  final SupabaseBootstrapState supabaseState;

  @override
  State<NotyShell> createState() => _NotyShellState();
}

class _NotyShellState extends State<NotyShell> {
  int _index = 0;

  static const List<String> _titles = <String>[
    'Inicio',
    'Buscar',
    'Ajustes',
  ];

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      const FeedPage(),
      const SearchPage(),
      SettingsPage(supabaseState: widget.supabaseState),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_index),
          child: tabs[_index],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (nextIndex) {
          if (nextIndex == _index) {
            return;
          }
          setState(() {
            _index = nextIndex;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}