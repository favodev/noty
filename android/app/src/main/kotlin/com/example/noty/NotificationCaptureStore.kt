package com.example.noty

import android.content.ComponentName
import android.content.Context
import android.provider.Settings
import org.json.JSONArray
import org.json.JSONObject

object NotificationCaptureStore {
    private const val PREFS_NAME = "noty_native_capture"
    private const val KEY_PENDING_NOTIFICATIONS = "pending_notifications"
    private const val MAX_QUEUE_SIZE = 250

    fun append(context: Context, payload: Map<String, Any?>) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val queue = readQueue(prefs.getString(KEY_PENDING_NOTIFICATIONS, null))

        val item = JSONObject()
        payload.forEach { (key, value) ->
            item.put(key, value ?: JSONObject.NULL)
        }

        queue.put(item)
        val trimmed = trimToMaxSize(queue)

        prefs.edit().putString(KEY_PENDING_NOTIFICATIONS, trimmed.toString()).apply()
    }

    fun drain(context: Context): List<Map<String, Any?>> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val queue = readQueue(prefs.getString(KEY_PENDING_NOTIFICATIONS, null))
        prefs.edit().remove(KEY_PENDING_NOTIFICATIONS).apply()

        val result = mutableListOf<Map<String, Any?>>()
        for (index in 0 until queue.length()) {
            val jsonObject = queue.optJSONObject(index) ?: continue
            result.add(jsonToMap(jsonObject))
        }

        return result
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

    private fun readQueue(rawJson: String?): JSONArray {
        if (rawJson.isNullOrBlank()) {
            return JSONArray()
        }

        return try {
            JSONArray(rawJson)
        } catch (_: Throwable) {
            JSONArray()
        }
    }

    private fun trimToMaxSize(queue: JSONArray): JSONArray {
        if (queue.length() <= MAX_QUEUE_SIZE) {
            return queue
        }

        val trimmed = JSONArray()
        val start = queue.length() - MAX_QUEUE_SIZE
        for (index in start until queue.length()) {
            trimmed.put(queue.get(index))
        }

        return trimmed
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