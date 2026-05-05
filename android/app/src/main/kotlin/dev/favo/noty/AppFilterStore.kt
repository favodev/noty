package dev.favo.noty

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager

object AppFilterStore {
    private const val PREFS_NAME = "noty_app_filters"
    private const val KEY_MONITORED_PACKAGES = "monitored_packages"

    fun isPackageMonitored(context: Context, packageName: String): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val monitored = prefs.getStringSet(KEY_MONITORED_PACKAGES, null)
        
        // Si no hay configuracion, por defecto escuchamos todo (o podria ser al reves, pero para MVP todo es mejor)
        if (monitored == null || monitored.isEmpty()) {
            return true
        }

        return monitored.contains(packageName)
    }

    fun updateMonitoredPackages(context: Context, packages: List<String>) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putStringSet(KEY_MONITORED_PACKAGES, packages.toSet()).apply()
    }

    fun getInstalledApps(context: Context): List<Map<String, String>> {
        val pm = context.packageManager
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        val result = mutableListOf<Map<String, String>>()

        for (appInfo in packages) {
            // Omitimos algunas apps super basicas del sistema que solo meten ruido si queremos,
            // pero la validacion basica es si se puede lanzar
            if (pm.getLaunchIntentForPackage(appInfo.packageName) != null) {
                val appName = pm.getApplicationLabel(appInfo).toString()
                result.add(
                    mapOf(
                        "packageName" to appInfo.packageName,
                        "appName" to appName
                    )
                )
            }
        }
        
        // Sort por nombre
        return result.sortedBy { it["appName"]?.lowercase() }
    }
}
