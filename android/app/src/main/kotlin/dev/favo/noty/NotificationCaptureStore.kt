package dev.favo.noty

import android.content.ComponentName
import android.content.Context
import android.provider.Settings
import org.json.JSONArray
import org.json.JSONObject

object NotificationCaptureStore {
    private const val PREFS_NAME = "noty_native_capture"
    private const val KEY_PENDING_NOTIFICATIONS = "pending_notifications"

    fun append(context: Context, payload: Map<String, Any?>) {
        migrateIfNeeded(context)
        val dbHelper = NativeCaptureDatabaseHelper(context)
        dbHelper.append(payload)
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
