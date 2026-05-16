package dev.favo.noty

import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import java.io.ByteArrayOutputStream

object AppFilterStore {
    private const val PREFS_NAME = "noty_app_filters"
    private const val KEY_MONITORED_PACKAGES = "monitored_packages"
    private const val KEY_FILTER_SCHEMA_VERSION = "filter_schema_version"
    private const val CURRENT_FILTER_SCHEMA_VERSION = 3

    fun isPackageMonitored(context: Context, packageName: String): Boolean {
        migrateOldFilterIfNeeded(context)

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        val hasExplicitSelection = prefs.contains(KEY_MONITORED_PACKAGES)
        if (!hasExplicitSelection) {
            return isAllowedDefaultNotificationSource(context, packageName)
        }

        val monitored = prefs.getStringSet(KEY_MONITORED_PACKAGES, emptySet()) ?: emptySet()
        return monitored.contains(packageName)
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

    fun getAppIcons(context: Context, packageNames: List<String>): Map<String, ByteArray> {
        val result = mutableMapOf<String, ByteArray>()
        val pm = context.packageManager

        for (packageName in packageNames.distinct()) {
            val icon = try {
                pm.getApplicationIcon(packageName)
            } catch (_: Exception) {
                null
            } ?: continue

            result[packageName] = drawableToPngBytes(icon)
        }

        return result
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

    private fun drawableToPngBytes(drawable: Drawable): ByteArray {
        val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            drawable.bitmap
        } else {
            val size = 96
            Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888).also { bitmap ->
                val canvas = Canvas(bitmap)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
            }
        }

        return ByteArrayOutputStream().use { output ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
            output.toByteArray()
        }
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
