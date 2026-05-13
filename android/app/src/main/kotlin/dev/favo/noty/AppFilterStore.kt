package dev.favo.noty

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager

object AppFilterStore {
    private const val PREFS_NAME = "noty_app_filters"
    private const val KEY_MONITORED_PACKAGES = "monitored_packages"

    fun isPackageMonitored(context: Context, packageName: String): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        if (!prefs.contains(KEY_MONITORED_PACKAGES)) {
            return true
        }
        
        val monitored = prefs.getStringSet(KEY_MONITORED_PACKAGES, emptySet()) ?: emptySet()
        return monitored.contains(packageName)
    }

    fun updateMonitoredPackages(context: Context, packages: List<String>) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putStringSet(KEY_MONITORED_PACKAGES, packages.toSet()).apply()
    }

    fun getMonitoredPackages(context: Context): List<String> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (!prefs.contains(KEY_MONITORED_PACKAGES)) {
            // Return an empty list or null? Since it returns List<String>, let's return emptyList, 
            // but the UI won't know it's "not configured". The UI might need to handle this.
            // Actually, returning emptyList() when not configured is fine, or we can just leave it as is.
            return emptyList()
        }
        val monitored = prefs.getStringSet(KEY_MONITORED_PACKAGES, emptySet()) ?: emptySet()
        return monitored.toList()
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
