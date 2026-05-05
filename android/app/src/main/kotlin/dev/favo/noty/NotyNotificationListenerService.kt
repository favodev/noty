package dev.favo.noty

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class NotyNotificationListenerService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        val statusBarNotification = sbn ?: return
        val notification = statusBarNotification.notification ?: return
        val extras = notification.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim().orEmpty()
        val body = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim().orEmpty()

        if (title.isEmpty() && body.isEmpty()) {
            return
        }

        if (!AppFilterStore.isPackageMonitored(applicationContext, statusBarNotification.packageName)) {
            return
        }

        NotificationCaptureStore.append(
            context = applicationContext,
            payload = mapOf(
                "id" to statusBarNotification.key,
                "appPackage" to statusBarNotification.packageName,
                "title" to title,
                "body" to body,
                "receivedAtEpochMs" to statusBarNotification.postTime,
                "isUnread" to true,
            ),
        )
    }
}