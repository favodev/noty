package dev.favo.noty

import android.content.ComponentName
import android.content.Context
import android.provider.Settings
import org.json.JSONArray
import org.json.JSONObject

object NotificationCaptureStore {
    private const val PREFS_NAME = "noty_native_capture"
    private const val KEY_PENDING_NOTIFICATIONS = "pending_notifications"
    private const val KEY_LISTENER_CONNECTED_AT = "listener_connected_at"
    private const val KEY_LAST_POSTED_AT = "last_posted_at"
    private const val KEY_LAST_CAPTURED_AT = "last_captured_at"
    private const val KEY_LAST_PACKAGE = "last_package"
    private const val KEY_POSTED_COUNT = "posted_count"
    private const val KEY_CAPTURED_COUNT = "captured_count"
    private const val KEY_LAST_ERROR = "last_error"
    private const val KEY_IGNORED_NOTIFICATION_KEYS = "ignored_notification_keys"

    fun append(context: Context, payload: Map<String, Any?>) {
        migrateIfNeeded(context)
        val dbHelper = NativeCaptureDatabaseHelper(context)
        dbHelper.append(payload)
        markCaptured(context, payload["appPackage"]?.toString().orEmpty())
    }

    fun drain(context: Context): List<Map<String, Any?>> {
        migrateIfNeeded(context)
        val dbHelper = NativeCaptureDatabaseHelper(context)
        return dbHelper.drain()
    }

    fun isListenerEnabled(context: Context): Boolean {
        @Suppress("InlinedApi")
        val enabledListeners = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners",
        ) ?: return false

        val component = ComponentName(context, NotyNotificationListenerService::class.java)
        val flat = component.flattenToString()
        val short = component.flattenToShortString()

        return enabledListeners.contains(flat) || enabledListeners.contains(short)
    }

    fun markListenerConnected(context: Context) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putLong(KEY_LISTENER_CONNECTED_AT, System.currentTimeMillis())
            .remove(KEY_LAST_ERROR)
            .apply()
    }

    fun markPosted(context: Context, packageName: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putLong(KEY_LAST_POSTED_AT, System.currentTimeMillis())
            .putString(KEY_LAST_PACKAGE, packageName)
            .putInt(KEY_POSTED_COUNT, prefs.getInt(KEY_POSTED_COUNT, 0) + 1)
            .remove(KEY_LAST_ERROR)
            .apply()
    }

    fun markError(context: Context, error: Throwable) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_LAST_ERROR, "${error::class.java.simpleName}: ${error.message.orEmpty()}")
            .apply()
    }

    fun diagnostics(context: Context): Map<String, Any?> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return mapOf(
            "listenerEnabled" to isListenerEnabled(context),
            "listenerConnectedAt" to prefs.getLong(KEY_LISTENER_CONNECTED_AT, 0L),
            "lastPostedAt" to prefs.getLong(KEY_LAST_POSTED_AT, 0L),
            "lastCapturedAt" to prefs.getLong(KEY_LAST_CAPTURED_AT, 0L),
            "lastPackage" to prefs.getString(KEY_LAST_PACKAGE, ""),
            "postedCount" to prefs.getInt(KEY_POSTED_COUNT, 0),
            "capturedCount" to prefs.getInt(KEY_CAPTURED_COUNT, 0),
            "lastError" to prefs.getString(KEY_LAST_ERROR, ""),
        )
    }

    fun ignoreNotification(context: Context, notificationId: String) {
        val key = notificationId.substringBeforeLast(":", notificationId).trim()
        if (key.isEmpty()) {
            return
        }

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val ignoredKeys = prefs.getStringSet(KEY_IGNORED_NOTIFICATION_KEYS, emptySet()).orEmpty()
            .toMutableSet()
        ignoredKeys.add(key)

        prefs.edit()
            .putStringSet(KEY_IGNORED_NOTIFICATION_KEYS, ignoredKeys)
            .apply()
    }

    fun isIgnored(context: Context, notificationKey: String): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val ignoredKeys = prefs.getStringSet(KEY_IGNORED_NOTIFICATION_KEYS, emptySet()).orEmpty()
        return ignoredKeys.contains(notificationKey)
    }

    private fun markCaptured(context: Context, packageName: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putLong(KEY_LAST_CAPTURED_AT, System.currentTimeMillis())
            .putString(KEY_LAST_PACKAGE, packageName)
            .putInt(KEY_CAPTURED_COUNT, prefs.getInt(KEY_CAPTURED_COUNT, 0) + 1)
            .remove(KEY_LAST_ERROR)
            .apply()
    }

    private fun migrateIfNeeded(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val rawJson = prefs.getString(KEY_PENDING_NOTIFICATIONS, null)
        
        if (!rawJson.isNullOrBlank()) {
            try {
                val queue = JSONArray(rawJson)
                val dbHelper = NativeCaptureDatabaseHelper(context)
                for (index in 0 until queue.length()) {
                    val jsonObject = queue.optJSONObject(index) ?: continue
                    dbHelper.append(jsonToMap(jsonObject))
                }
            } catch (_: Throwable) {
                // Si falla la migracion, igual borramos para no volver a intentar
            }
            prefs.edit().remove(KEY_PENDING_NOTIFICATIONS).apply()
        }
    }

    private fun jsonToMap(json: JSONObject): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        val keys = json.keys()

        while (keys.hasNext()) {
            val key = keys.next()
            val value = json.get(key)
            map[key] = if (value == JSONObject.NULL) null else value
        }

        return map
    }
}
