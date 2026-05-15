package dev.favo.noty

import android.content.Context
import android.content.pm.PackageManager

object AppFilterStore {
    private const val PREFS_NAME = "noty_app_filters"
    private const val KEY_MONITORED_PACKAGES = "monitored_packages"
    private const val KEY_FILTER_SCHEMA_VERSION = "filter_schema_version"
    private const val CURRENT_FILTER_SCHEMA_VERSION = 3

    fun isPackageMonitored(context: Context, packageName: String): Boolean {
        migrateOldFilterIfNeeded(context)

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        if (!prefs.contains(KEY_MONITORED_PACKAGES)) {
            return isAllowedDefaultNotificationSource(context, packageName)
        }
        
        return isAllowedDefaultNotificationSource(context, packageName)
    }

    fun updateMonitoredPackages(context: Context, packages: List<String>) {
        migrateOldFilterIfNeeded(context)

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (packages.isEmpty()) {
            prefs.edit()
                .remove(KEY_MONITORED_PACKAGES)
                .putInt(KEY_FILTER_SCHEMA_VERSION, CURRENT_FILTER_SCHEMA_VERSION)
                .apply()
            return
        }

        prefs.edit()
            .putStringSet(KEY_MONITORED_PACKAGES, packages.toSet())
            .putInt(KEY_FILTER_SCHEMA_VERSION, CURRENT_FILTER_SCHEMA_VERSION)
            .apply()
    }

    fun getMonitoredPackages(context: Context): List<String> {
        migrateOldFilterIfNeeded(context)

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (!prefs.contains(KEY_MONITORED_PACKAGES)) {
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
            if (!isVisibleInPicker(pm, appInfo)) {
                continue
            }

            val appName = pm.getApplicationLabel(appInfo).toString().ifBlank {
                appInfo.packageName
            }

            result.add(
                mapOf(
                    "packageName" to appInfo.packageName,
                    "appName" to appName
                )
            )
        }
        
        // Sort por nombre
        return result.sortedBy { it["appName"]?.lowercase() }
    }

    private fun isAllowedDefaultNotificationSource(context: Context, packageName: String): Boolean {
        if (packageName == context.packageName) {
            return false
        }

        if (packageName == "android") {
            return false
        }

        if (packageName.startsWith("com.android.")) {
            return false
        }

        if (packageName.startsWith("com.miui.")) {
            return false
        }

        return true
    }

    private fun isVisibleInPicker(pm: PackageManager, appInfo: android.content.pm.ApplicationInfo): Boolean {
        return pm.getLaunchIntentForPackage(appInfo.packageName) != null
    }

    private fun migrateOldFilterIfNeeded(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val schemaVersion = prefs.getInt(KEY_FILTER_SCHEMA_VERSION, 0)

        if (schemaVersion >= CURRENT_FILTER_SCHEMA_VERSION) {
            return
        }

        prefs.edit()
            .remove(KEY_MONITORED_PACKAGES)
            .putInt(KEY_FILTER_SCHEMA_VERSION, CURRENT_FILTER_SCHEMA_VERSION)
            .apply()
    }
}
