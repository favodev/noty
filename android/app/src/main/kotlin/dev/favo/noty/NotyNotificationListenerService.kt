package dev.favo.noty

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class NotyNotificationListenerService : NotificationListenerService() {
    override fun onListenerConnected() {
        super.onListenerConnected()

        try {
            activeNotifications?.forEach { captureNotification(it, dedupeActiveNotification = true) }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        try {
            captureNotification(sbn ?: return, dedupeActiveNotification = false)
        } catch (e: Exception) {
            // Prevenir que el servicio de Android crashee por completo.
            e.printStackTrace()
        }
    }

    private fun captureNotification(
        statusBarNotification: StatusBarNotification,
        dedupeActiveNotification: Boolean,
    ) {
        val notification = statusBarNotification.notification ?: return
        val extras = notification.extras ?: return

        var title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim().orEmpty()

        if (title.isEmpty()) {
            title = extras.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE)?.toString()?.trim().orEmpty()
        }

        var body = extractMessagingBody(extras)

        if (body.isEmpty()) {
            body = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim().orEmpty()
        }

        if (body.isEmpty()) {
            body = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim().orEmpty()
        }

        if (body.isEmpty()) {
            try {
                val textLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
                if (!textLines.isNullOrEmpty()) {
                    body = textLines.joinToString("\n") { it?.toString()?.trim().orEmpty() }
                }
            } catch (e: Exception) {
                // Ignore.
            }
        }

        if (body.isEmpty()) {
            body = notification.tickerText?.toString()?.trim().orEmpty()
        }

        // Fallback si no hay título ni cuerpo pero es una app monitoreada (ej. foto en WhatsApp sin texto).
        if (title.isEmpty() && body.isEmpty()) {
            body = "[Notificación sin texto o multimedia]"
            title = statusBarNotification.packageName
        }

        if (!AppFilterStore.isPackageMonitored(applicationContext, statusBarNotification.packageName)) {
            return
        }

        val captureId = if (dedupeActiveNotification) {
            "${statusBarNotification.key}:${statusBarNotification.postTime}"
        } else {
            "${statusBarNotification.key}:${System.currentTimeMillis()}"
        }

        NotificationCaptureStore.append(
            context = applicationContext,
            payload = mapOf(
                "id" to captureId,
                "appPackage" to statusBarNotification.packageName,
                "title" to title,
                "body" to body,
                "receivedAtEpochMs" to statusBarNotification.postTime,
                "isUnread" to true,
            ),
        )

        val intent = android.content.Intent("dev.favo.noty.NEW_NOTIFICATION")
            .setPackage(packageName)
        sendBroadcast(intent)
    }

    private fun extractMessagingBody(extras: android.os.Bundle): String {
        return try {
            val messages = extras.getParcelableArray(Notification.EXTRA_MESSAGES)
            if (messages.isNullOrEmpty()) {
                return ""
            }

            messages.mapNotNull { rawMessage ->
                val message = rawMessage as? android.os.Bundle ?: return@mapNotNull null
                val text = message.getCharSequence("text")?.toString()?.trim().orEmpty()
                if (text.isEmpty()) {
                    return@mapNotNull null
                }

                val sender = message.getCharSequence("sender")?.toString()?.trim().orEmpty()
                if (sender.isEmpty()) text else "$sender: $text"
            }.distinct().joinToString("\n")
        } catch (_: Exception) {
            ""
        }
    }
}
