package dev.favo.noty

import android.content.ComponentName
import android.content.Context
import android.app.KeyguardManager
import android.os.PowerManager
import android.provider.Settings
import org.json.JSONArray
import org.json.JSONObject

object NotificationCaptureStore {
    private const val PREFS_NAME = "noty_native_capture"
    private const val RECENT_CAPTURE_WINDOW_MS = 6 * 60 * 60 * 1000L
    private const val MAX_RECENT_CAPTURE_IDS = 300
    private const val KEY_PENDING_NOTIFICATIONS = "pending_notifications"
    private const val KEY_RECENT_CAPTURE_IDS = "recent_capture_ids"
    private const val KEY_LISTENER_CONNECTED_AT = "listener_connected_at"
    private const val KEY_LAST_POSTED_AT = "last_posted_at"
    private const val KEY_LAST_CAPTURED_AT = "last_captured_at"
    private const val KEY_LISTENER_DISCONNECTED_AT = "listener_disconnected_at"
    private const val KEY_LAST_ACTIVE_SYNC_AT = "last_active_sync_at"
    private const val KEY_LAST_ACTIVE_PACKAGES = "last_active_packages"
    private const val KEY_LAST_PACKAGE = "last_package"
    private const val KEY_POSTED_COUNT = "posted_count"
    private const val KEY_CAPTURED_COUNT = "captured_count"
    private const val KEY_LISTENER_DISCONNECTED_COUNT = "listener_disconnected_count"
    private const val KEY_LAST_ACTIVE_NOTIFICATION_COUNT = "last_active_notification_count"
    private const val KEY_LAST_SKIPPED_AT = "last_skipped_at"
    private const val KEY_LAST_SKIPPED_PACKAGE = "last_skipped_package"
    private const val KEY_LAST_SKIPPED_REASON = "last_skipped_reason"
    private const val KEY_SKIPPED_COUNT = "skipped_count"
    private const val KEY_LAST_ERROR = "last_error"
    private const val KEY_IGNORED_NOTIFICATION_IDS = "ignored_notification_ids"
    private const val KEY_LISTENER_REPAIR_REQUESTED_AT = "listener_repair_requested_at"
    private const val KEY_LISTENER_REPAIR_COUNT = "listener_repair_count"

    fun append(context: Context, payload: Map<String, Any?>): Boolean {
        migrateIfNeeded(context)
        val captureId = payload["id"]?.toString().orEmpty()
        val packageName = payload["appPackage"]?.toString().orEmpty()

        if (captureId.isNotEmpty() && wasRecentlyCaptured(context, captureId)) {
            markSkipped(context, packageName, "duplicado-reciente")
            return false
        }

        val dbHelper = NativeCaptureDatabaseHelper(context)
        dbHelper.append(payload)
        if (captureId.isNotEmpty()) {
            markRecentlyCaptured(context, captureId)
        }
        markCaptured(context, packageName)
        return true
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

    fun markListenerDisconnected(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putLong(KEY_LISTENER_DISCONNECTED_AT, System.currentTimeMillis())
            .putInt(
                KEY_LISTENER_DISCONNECTED_COUNT,
                prefs.getInt(KEY_LISTENER_DISCONNECTED_COUNT, 0) + 1,
            )
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

    fun markActiveNotificationSnapshot(
        context: Context,
        count: Int,
        packageNames: List<String> = emptyList(),
    ) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putLong(KEY_LAST_ACTIVE_SYNC_AT, System.currentTimeMillis())
            .putInt(KEY_LAST_ACTIVE_NOTIFICATION_COUNT, count)
            .putString(KEY_LAST_ACTIVE_PACKAGES, packageNames.distinct().joinToString(", "))
            .remove(KEY_LAST_ERROR)
            .apply()
    }

    fun markSkipped(context: Context, packageName: String, reason: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putLong(KEY_LAST_SKIPPED_AT, System.currentTimeMillis())
            .putString(KEY_LAST_SKIPPED_PACKAGE, packageName)
            .putString(KEY_LAST_SKIPPED_REASON, reason)
            .putInt(KEY_SKIPPED_COUNT, prefs.getInt(KEY_SKIPPED_COUNT, 0) + 1)
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
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager

        return mapOf(
            "listenerEnabled" to isListenerEnabled(context),
            "listenerConnected" to NotyNotificationListenerService.isConnected(),
            "listenerConnectedAt" to prefs.getLong(KEY_LISTENER_CONNECTED_AT, 0L),
            "listenerDisconnectedAt" to prefs.getLong(KEY_LISTENER_DISCONNECTED_AT, 0L),
            "listenerDisconnectedCount" to prefs.getInt(KEY_LISTENER_DISCONNECTED_COUNT, 0),
            "lastPostedAt" to prefs.getLong(KEY_LAST_POSTED_AT, 0L),
            "lastCapturedAt" to prefs.getLong(KEY_LAST_CAPTURED_AT, 0L),
            "lastActiveSyncAt" to prefs.getLong(KEY_LAST_ACTIVE_SYNC_AT, 0L),
            "lastActiveNotificationCount" to prefs.getInt(KEY_LAST_ACTIVE_NOTIFICATION_COUNT, 0),
            "lastActivePackages" to prefs.getString(KEY_LAST_ACTIVE_PACKAGES, ""),
            "lastPackage" to prefs.getString(KEY_LAST_PACKAGE, ""),
            "postedCount" to prefs.getInt(KEY_POSTED_COUNT, 0),
            "capturedCount" to prefs.getInt(KEY_CAPTURED_COUNT, 0),
            "skippedCount" to prefs.getInt(KEY_SKIPPED_COUNT, 0),
            "lastSkippedAt" to prefs.getLong(KEY_LAST_SKIPPED_AT, 0L),
            "lastSkippedPackage" to prefs.getString(KEY_LAST_SKIPPED_PACKAGE, ""),
            "lastSkippedReason" to prefs.getString(KEY_LAST_SKIPPED_REASON, ""),
            "listenerRepairRequestedAt" to prefs.getLong(KEY_LISTENER_REPAIR_REQUESTED_AT, 0L),
            "listenerRepairCount" to prefs.getInt(KEY_LISTENER_REPAIR_COUNT, 0),
            "isInteractive" to (powerManager?.isInteractive ?: false),
            "isDeviceLocked" to (keyguardManager?.isDeviceLocked ?: false),
            "isKeyguardLocked" to (keyguardManager?.isKeyguardLocked ?: false),
            "lastError" to prefs.getString(KEY_LAST_ERROR, ""),
        )
    }

    fun canRequestListenerRepair(context: Context, cooldownMs: Long): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val lastRequestedAt = prefs.getLong(KEY_LISTENER_REPAIR_REQUESTED_AT, 0L)
        return System.currentTimeMillis() - lastRequestedAt >= cooldownMs
    }

    fun markListenerRepairRequested(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putLong(KEY_LISTENER_REPAIR_REQUESTED_AT, System.currentTimeMillis())
            .putInt(KEY_LISTENER_REPAIR_COUNT, prefs.getInt(KEY_LISTENER_REPAIR_COUNT, 0) + 1)
            .remove(KEY_LAST_ERROR)
            .apply()
    }

    fun ignoreNotification(context: Context, notificationId: String) {
        val id = notificationId.trim()
        if (id.isEmpty()) {
            return
        }

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val ignoredIds = prefs.getStringSet(KEY_IGNORED_NOTIFICATION_IDS, emptySet()).orEmpty()
            .toMutableSet()
        ignoredIds.add(id)

        prefs.edit()
            .putStringSet(KEY_IGNORED_NOTIFICATION_IDS, ignoredIds)
            .apply()
    }

    fun isIgnored(context: Context, notificationId: String): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val ignoredIds = prefs.getStringSet(KEY_IGNORED_NOTIFICATION_IDS, emptySet()).orEmpty()
        return ignoredIds.contains(notificationId)
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

    private fun wasRecentlyCaptured(context: Context, captureId: String): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val lastCapturedAt = loadRecentCaptureIds(prefs.getString(KEY_RECENT_CAPTURE_IDS, null))[captureId]
            ?: return false

        return System.currentTimeMillis() - lastCapturedAt < RECENT_CAPTURE_WINDOW_MS
    }

    private fun markRecentlyCaptured(context: Context, captureId: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        val recent = loadRecentCaptureIds(prefs.getString(KEY_RECENT_CAPTURE_IDS, null))
        val cutoff = now - RECENT_CAPTURE_WINDOW_MS

        recent.entries.removeAll { it.value < cutoff }
        recent[captureId] = now

        while (recent.size > MAX_RECENT_CAPTURE_IDS) {
            val oldest = recent.minByOrNull { it.value } ?: break
            recent.remove(oldest.key)
        }

        val json = JSONObject()
        for ((id, timestamp) in recent) {
            json.put(id, timestamp)
        }

        prefs.edit()
            .putString(KEY_RECENT_CAPTURE_IDS, json.toString())
            .apply()
    }

    private fun loadRecentCaptureIds(rawJson: String?): MutableMap<String, Long> {
        val result = mutableMapOf<String, Long>()
        if (rawJson.isNullOrBlank()) {
            return result
        }

        return try {
            val json = JSONObject(rawJson)
            val keys = json.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                result[key] = json.optLong(key, 0L)
            }
            result
        } catch (_: Exception) {
            mutableMapOf()
        }
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
