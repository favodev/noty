package dev.favo.noty

import android.app.Notification
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.NotificationListenerService.RankingMap
import android.service.notification.StatusBarNotification
import java.lang.ref.WeakReference

class NotyNotificationListenerService : NotificationListenerService() {
    companion object {
        private var activeService: WeakReference<NotyNotificationListenerService>? = null

        fun captureActiveNotificationsIfConnected(): Boolean {
            val service = activeService?.get() ?: return false
            service.captureActiveNotifications()
            return true
        }

        fun isConnected(): Boolean {
            return activeService?.get() != null
        }

        fun requestRebindIfNeeded(context: Context): Boolean {
            if (activeService?.get() != null) {
                return false
            }

            if (!NotificationCaptureStore.isListenerEnabled(context)) {
                return false
            }

            return try {
                NotificationListenerService.requestRebind(
                    ComponentName(
                        context,
                        NotyNotificationListenerService::class.java,
                    ),
                )
                true
            } catch (e: Exception) {
                NotificationCaptureStore.markError(context, e)
                false
            }
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        activeService = WeakReference(this)

        try {
            migrateNotificationFilterIfNeeded()
            captureActiveNotifications()
        } catch (e: Exception) {
            NotificationCaptureStore.markError(applicationContext, e)
            e.printStackTrace()
        }
    }

    override fun onListenerDisconnected() {
        activeService = null
        requestRebindIfNeeded(applicationContext)
        super.onListenerDisconnected()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        handlePostedNotification(sbn)
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?, rankingMap: RankingMap?) {
        handlePostedNotification(sbn)
    }

    private fun handlePostedNotification(sbn: StatusBarNotification?) {
        try {
            val statusBarNotification = sbn ?: return
            NotificationCaptureStore.markPosted(applicationContext, statusBarNotification.packageName)
            captureNotification(statusBarNotification, dedupeActiveNotification = false)
        } catch (e: Exception) {
            NotificationCaptureStore.markError(applicationContext, e)
            // Prevenir que el servicio de Android crashee por completo.
            e.printStackTrace()
        }
    }

    private fun captureNotification(
        statusBarNotification: StatusBarNotification,
        dedupeActiveNotification: Boolean,
    ) {
        val sourcePackage = statusBarNotification.packageName
        if (sourcePackage == applicationContext.packageName) {
            return
        }
        val notification = statusBarNotification.notification
        val extras = notification.extras

        var title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim().orEmpty()

        if (title.isEmpty()) {
            title = extras?.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE)?.toString()?.trim().orEmpty()
        }

        var body = if (extras == null) "" else extractMessagingBody(extras)

        if (body.isEmpty()) {
            body = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim().orEmpty()
        }

        if (body.isEmpty()) {
            body = extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim().orEmpty()
        }

        if (body.isEmpty() && extras != null) {
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

        // Fallback si no hay título ni cuerpo (ej. multimedia o apps que ocultan extras).
        if (title.isEmpty() && body.isEmpty()) {
            body = "[Notificación sin texto o multimedia]"
            title = sourcePackage
        }

        val hasOnlyFallbackContent = title == sourcePackage && body == "[Notificación sin texto o multimedia]"
        if (shouldSkipNoise(sourcePackage, hasOnlyFallbackContent)) {
            return
        }

        val captureId = if (dedupeActiveNotification) {
            "${statusBarNotification.key}:${statusBarNotification.postTime}"
        } else {
            "${statusBarNotification.key}:${System.currentTimeMillis()}"
        }

        if (NotificationCaptureStore.isIgnored(applicationContext, captureId)) {
            return
        }

        NotificationCaptureStore.append(
            context = applicationContext,
            payload = mapOf(
                "id" to captureId,
                "appPackage" to sourcePackage,
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

    private fun captureActiveNotifications() {
        NotificationCaptureStore.markListenerConnected(applicationContext)
        activeNotifications?.forEach { captureNotification(it, dedupeActiveNotification = true) }
    }

    private fun migrateNotificationFilterIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return
        }

        try {
            migrateNotificationFilter(
                FLAG_FILTER_TYPE_CONVERSATIONS or
                    FLAG_FILTER_TYPE_ALERTING or
                    FLAG_FILTER_TYPE_SILENT or
                    FLAG_FILTER_TYPE_ONGOING,
                emptyList(),
            )
        } catch (e: Exception) {
            NotificationCaptureStore.markError(applicationContext, e)
        }
    }

    private fun shouldSkipNoise(packageName: String, hasOnlyFallbackContent: Boolean): Boolean {
        if (packageName == "android" || packageName.startsWith("com.android.")) {
            return true
        }

        if (packageName == "com.miui.notification") {
            return true
        }

        return packageName.startsWith("com.miui.") && hasOnlyFallbackContent
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
