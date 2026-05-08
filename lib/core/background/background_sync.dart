import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:noty/core/supabase/supabase_bootstrap.dart';
import 'package:noty/features/shell/data/noty_shell_service.dart';
import 'package:workmanager/workmanager.dart';

const String backgroundSyncTask = "dev.favo.noty.syncNotifications";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == backgroundSyncTask) {
        // Inicializamos Supabase en este nuevo isolate
        final supabaseState = await bootstrapSupabase();
        
        if (!supabaseState.initialized) {
          return true; // Supabase no configurado, no hacemos nada y evitamos que falle el job
        }

        final shellService = NotyShellService();
        
        final user = shellService.currentUser;
        if (user == null) {
          return true; // No hay sesion, nada que sincar
        }

        // Primero leemos si hay algo en la base nativa que no haya bajado a Flutter aun
        await shellService.loadNotifications(enableLocalPersistence: true);

        // Ahora forzamos el sync
        await shellService.syncPendingNotifications(
          enableLocalPersistence: true,
          supabaseInitialized: true,
          currentUser: user,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Background sync failed: $e');
      return false; // Retornamos false para que el sistema sepa que fallo
    }
  });
}

class BackgroundSyncManager {
  static Future<void> initialize() async {
    if (kIsWeb) return;

    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static Future<void> registerPeriodicSync() async {
    if (kIsWeb) return;

    await Workmanager().registerPeriodicTask(
      "noty_periodic_sync",
      backgroundSyncTask,
      frequency: const Duration(minutes: 15), // Mínimo permitido por Android
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}
