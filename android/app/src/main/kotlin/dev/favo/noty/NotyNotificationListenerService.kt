package dev.favo.noty

import android.app.Notification
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.NotificationListenerService.RankingMap
import android.service.notification.StatusBarNotification
import java.io.ByteArrayOutputStream
import java.io.File
import java.lang.ref.WeakReference
import java.security.MessageDigest

class NotyNotificationListenerService : NotificationListenerService() {
    companion object {
        private const val REPAIR_COOLDOWN_MS = 60_000L
        private const val ACTIVE_SYNC_COOLDOWN_MS = 30_000L

        private var activeService: WeakReference<NotyNotificationListenerService>? = null

        fun captureActiveNotificationsIfConnected(): Boolean {
            val service = activeService?.get() ?: return false
            val now = System.currentTimeMillis()
            if (now - service.lastActiveSyncRequestedAt < ACTIVE_SYNC_COOLDOWN_MS) {
                return true
            }
            service.lastActiveSyncRequestedAt = now
            service.captureActiveNotifications()
            return true
        }

        fun isConnected(): Boolean {
            return activeService?.get() != null
        }

        fun repairConnectionIfNeeded(context: Context): Boolean {
            if (activeService?.get() != null) {
                return false
            }

            if (!NotificationCaptureStore.isListenerEnabled(context)) {
                return false
            }

            if (!NotificationCaptureStore.canRequestListenerRepair(context, REPAIR_COOLDOWN_MS)) {
                return false
            }

            return try {
                val appContext = context.applicationContext
                val component = ComponentName(
                    appContext,
                    NotyNotificationListenerService::class.java,
                )

                NotificationCaptureStore.markListenerRepairRequested(appContext)

                appContext.packageManager.setComponentEnabledSetting(
                    component,
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP,
                )
                appContext.packageManager.setComponentEnabledSetting(
                    component,
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                    PackageManager.DONT_KILL_APP,
                )
                NotificationListenerService.requestRebind(component)

                true
            } catch (e: Exception) {
                NotificationCaptureStore.markError(context, e)
                false
            }
        }

        fun requestRebindAfterDisconnect(context: Context): Boolean {
            return try {
                NotificationListenerService.requestRebind(
                    ComponentName(
                        context.applicationContext,
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

    private var lastActiveSyncRequestedAt = 0L

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
        NotificationCaptureStore.markListenerDisconnected(applicationContext)
        requestRebindAfterDisconnect(applicationContext)
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
            captureNotification(statusBarNotification)
        } catch (e: Exception) {
            NotificationCaptureStore.markError(applicationContext, e)
            // Prevenir que el servicio de Android crashee por completo.
            e.printStackTrace()
        }
    }

    private fun captureNotification(statusBarNotification: StatusBarNotification) {
        val sourcePackage = resolveSourcePackage(statusBarNotification)
        if (sourcePackage == applicationContext.packageName) {
            NotificationCaptureStore.markSkipped(applicationContext, sourcePackage, "app-propia")
            return
        }

        if (!AppFilterStore.isPackageMonitored(applicationContext, sourcePackage)) {
            NotificationCaptureStore.markSkipped(applicationContext, sourcePackage, "app-no-monitoreada")
            return
        }

        val notification = statusBarNotification.notification
        if (isGroupSummary(notification)) {
            NotificationCaptureStore.markSkipped(applicationContext, sourcePackage, "resumen-grupo")
            return
        }

        val extras = notification.extras
        val appName = resolveAppName(sourcePackage)
        val title = resolveTitle(extras)
        val media = captureMediaIfAllowed(
            sourcePackage = sourcePackage,
            statusBarNotification = statusBarNotification,
            notification = notification,
        )

        val messagingCaptures = extractMessagingCaptures(
            extras = extras,
            fallbackTitle = title,
            statusBarNotification = statusBarNotification,
        )

        if (messagingCaptures.isNotEmpty()) {
            var capturedAny = false
            for (message in messagingCaptures) {
                val captured = appendCapturedNotification(
                    sourcePackage = sourcePackage,
                    appName = appName,
                    title = message.title,
                    body = message.body,
                    receivedAtEpochMs = message.receivedAtEpochMs,
                    captureId = message.captureId,
                    media = media.takeIf { !capturedAny },
                )
                capturedAny = capturedAny || captured
            }
            if (capturedAny) {
                notifyFlutter()
            }
            return
        }

        var body = resolveBody(extras, notification)

        if (title.isEmpty() && body.isEmpty()) {
            body = when (media?.type) {
                "sticker" -> "[Sticker]"
                "photo" -> "[Imagen]"
                else -> "[Notificacion sin texto o multimedia]"
            }
        }

        val resolvedTitle = title.ifEmpty { sourcePackage }

        if (isCountOnlyMessagingSummary(sourcePackage, body)) {
            NotificationCaptureStore.markSkipped(applicationContext, sourcePackage, "resumen-mensajes")
            return
        }

        val hasOnlyFallbackContent = resolvedTitle == sourcePackage && body == "[Notificacion sin texto o multimedia]"
        if (shouldSkipNoise(sourcePackage, hasOnlyFallbackContent)) {
            NotificationCaptureStore.markSkipped(applicationContext, sourcePackage, "ruido-sistema")
            return
        }

        val captured = appendCapturedNotification(
            sourcePackage = sourcePackage,
            appName = appName,
            title = resolvedTitle,
            body = body,
            receivedAtEpochMs = statusBarNotification.postTime,
            captureId = buildContentCaptureId(statusBarNotification, resolvedTitle, body),
            media = media,
        )

        if (captured) {
            notifyFlutter()
        }
    }

    private fun captureActiveNotifications() {
        NotificationCaptureStore.markListenerConnected(applicationContext)
        val currentNotifications = activeNotifications.orEmpty()
        NotificationCaptureStore.markActiveNotificationSnapshot(
            applicationContext,
            currentNotifications.size,
            currentNotifications.map { resolveSourcePackage(it) },
        )
        currentNotifications.forEach { captureNotification(it) }
    }

    private fun resolveSourcePackage(statusBarNotification: StatusBarNotification): String {
        val packageName = statusBarNotification.packageName
        if (packageName != "android" && !packageName.startsWith("com.android.")) {
            return packageName
        }

        val keyPackage = statusBarNotification.key
            .split('|')
            .getOrNull(1)
            ?.trim()
            .orEmpty()

        if (keyPackage.isNotEmpty() && keyPackage != "android" && !keyPackage.startsWith("com.android.")) {
            return keyPackage
        }

        return packageName
    }

    private fun resolveAppName(packageName: String): String {
        return try {
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (_: Exception) {
            packageName
        }
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


    private fun appendCapturedNotification(
        sourcePackage: String,
        appName: String,
        title: String,
        body: String,
        receivedAtEpochMs: Long,
        captureId: String,
        media: CapturedMedia? = null,
    ): Boolean {
        if (NotificationCaptureStore.isIgnored(applicationContext, captureId)) {
            media?.path?.let { File(it).delete() }
            NotificationCaptureStore.markSkipped(applicationContext, sourcePackage, "ignorada")
            return false
        }

        val captured = NotificationCaptureStore.append(
            context = applicationContext,
            payload = mapOf(
                "id" to captureId,
                "appPackage" to sourcePackage,
                "appName" to appName,
                "title" to title,
                "body" to body,
                "receivedAtEpochMs" to receivedAtEpochMs,
                "isUnread" to true,
                "mediaPath" to media?.path,
                "mediaType" to media?.type,
                "mediaMimeType" to media?.mimeType,
                "mediaSizeBytes" to media?.sizeBytes,
            ),
        )

        if (!captured) {
            media?.path?.let { File(it).delete() }
        }
        return captured
    }

    private fun notifyFlutter() {
        val intent = android.content.Intent("dev.favo.noty.NEW_NOTIFICATION")
            .setPackage(packageName)
        sendBroadcast(intent)
    }

    private fun resolveTitle(extras: Bundle?): String {
        val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim().orEmpty()
        if (title.isNotEmpty()) {
            return title
        }

        return extras?.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE)?.toString()?.trim().orEmpty()
    }

    private fun resolveBody(extras: Bundle?, notification: Notification): String {
        var body = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim().orEmpty()

        if (body.isEmpty()) {
            body = extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim().orEmpty()
        }

        if (body.isEmpty() && extras != null) {
            try {
                val textLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
                if (!textLines.isNullOrEmpty()) {
                    body = textLines.joinToString("\n") { it?.toString()?.trim().orEmpty() }
                }
            } catch (_: Exception) {
                // Ignore.
            }
        }

        if (body.isEmpty()) {
            body = notification.tickerText?.toString()?.trim().orEmpty()
        }

        return body
    }

    private fun isGroupSummary(notification: Notification): Boolean {
        return notification.flags and Notification.FLAG_GROUP_SUMMARY != 0
    }

    private fun isCountOnlyMessagingSummary(packageName: String, body: String): Boolean {
        val normalizedBody = body.trim().lowercase()
        if (normalizedBody.isEmpty()) {
            return false
        }

        val isKnownMessagingApp = packageName == "com.whatsapp" ||
            packageName == "com.whatsapp.w4b" ||
            packageName == "com.facebook.orca" ||
            packageName == "org.telegram.messenger" ||
            packageName == "com.instagram.android"

        if (!isKnownMessagingApp) {
            return false
        }

        return Regex("""^\d+\s+(new\s+messages?|nuevos?\s+mensajes?|mensajes?\s+nuevos?)\b""")
            .containsMatchIn(normalizedBody)
    }

    private fun buildContentCaptureId(
        statusBarNotification: StatusBarNotification,
        title: String,
        body: String,
    ): String {
        return "${statusBarNotification.key}:content:${stableHash("$title\n$body")}"
    }

    private fun extractMessagingCaptures(
        extras: Bundle?,
        fallbackTitle: String,
        statusBarNotification: StatusBarNotification,
    ): List<MessagingCapture> {
        if (extras == null) {
            return emptyList()
        }

        return try {
            val messages = extras.getParcelableArray(Notification.EXTRA_MESSAGES)
            if (messages.isNullOrEmpty()) {
                return emptyList()
            }

            messages.mapNotNull { rawMessage ->
                val message = rawMessage as? Bundle ?: return@mapNotNull null
                val text = message.getCharSequence("text")?.toString()?.trim().orEmpty()
                if (text.isEmpty()) {
                    return@mapNotNull null
                }

                val sender = message.getCharSequence("sender")?.toString()?.trim().orEmpty()
                val messageTime = message.getLong("time", 0L).takeIf { it > 0L }
                    ?: statusBarNotification.postTime
                val title = fallbackTitle.ifEmpty { sender }
                    .ifEmpty { resolveSourcePackage(statusBarNotification) }
                val body = if (sender.isEmpty() || sender == title) text else "$sender: $text"
                val captureId = "${statusBarNotification.key}:message:" +
                    stableHash("$messageTime\n$sender\n$text")

                MessagingCapture(
                    captureId = captureId,
                    title = title,
                    body = body,
                    receivedAtEpochMs = messageTime,
                )
            }.distinctBy { it.captureId }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun captureMediaIfAllowed(
        sourcePackage: String,
        statusBarNotification: StatusBarNotification,
        notification: Notification,
    ): CapturedMedia? {
        return try {
            val settings = MediaCaptureSettingsStore.get(applicationContext)
            if (!settings.enabled) {
                return null
            }

            val bitmap = extractNotificationPicture(notification) ?: return null
            val mediaType = classifyMedia(bitmap)
            if (mediaType == "sticker" && !settings.saveStickers) {
                return null
            }
            if (mediaType == "photo" && !settings.savePhotos) {
                return null
            }

            saveMediaBitmap(
                bitmap = bitmap,
                mediaType = mediaType,
                captureId = "${statusBarNotification.key}:media:${stableHash("${bitmap.width}x${bitmap.height}:${statusBarNotification.postTime}")}",
            )
        } catch (e: Exception) {
            NotificationCaptureStore.markError(applicationContext, e)
            null
        }
    }

    private fun extractNotificationPicture(notification: Notification): Bitmap? {
        val extras = notification.extras ?: return null

        @Suppress("DEPRECATION")
        val picture = extras.getParcelable<Bitmap>(Notification.EXTRA_PICTURE)
        if (picture != null) {
            return picture
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val pictureIcon = extras.getParcelable<Icon>(Notification.EXTRA_PICTURE_ICON)
            if (pictureIcon != null) {
                return drawableToBitmap(pictureIcon.loadDrawable(applicationContext))
            }
        }

        return null
    }

    private fun classifyMedia(bitmap: Bitmap): String {
        val longestSide = maxOf(bitmap.width, bitmap.height)
        return if (longestSide <= 512) "sticker" else "photo"
    }

    private fun saveMediaBitmap(
        bitmap: Bitmap,
        mediaType: String,
        captureId: String,
    ): CapturedMedia? {
        return try {
            val directory = File(applicationContext.filesDir, "noty_media")
            if (!directory.exists()) {
                directory.mkdirs()
            }

            val format = if (mediaType == "sticker") {
                Bitmap.CompressFormat.PNG
            } else {
                Bitmap.CompressFormat.JPEG
            }
            val extension = if (mediaType == "sticker") "png" else "jpg"
            val mimeType = if (mediaType == "sticker") "image/png" else "image/jpeg"
            val file = File(directory, "${stableHash(captureId)}-${System.currentTimeMillis()}.$extension")

            val bytes = ByteArrayOutputStream().use { output ->
                bitmap.compress(format, if (mediaType == "sticker") 100 else 88, output)
                output.toByteArray()
            }
            file.writeBytes(bytes)

            CapturedMedia(
                path = file.absolutePath,
                type = mediaType,
                mimeType = mimeType,
                sizeBytes = bytes.size,
            )
        } catch (e: Exception) {
            NotificationCaptureStore.markError(applicationContext, e)
            null
        }
    }

    private fun drawableToBitmap(drawable: Drawable?): Bitmap? {
        if (drawable == null) {
            return null
        }

        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }

        val width = drawable.intrinsicWidth.takeIf { it > 0 } ?: 512
        val height = drawable.intrinsicHeight.takeIf { it > 0 } ?: 512
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    private fun stableHash(value: String): String {
        val bytes = MessageDigest.getInstance("SHA-256")
            .digest(value.toByteArray(Charsets.UTF_8))
        return bytes.take(12).joinToString("") { "%02x".format(it.toInt() and 0xff) }
    }

    private data class MessagingCapture(
        val captureId: String,
        val title: String,
        val body: String,
        val receivedAtEpochMs: Long,
    )

    private data class CapturedMedia(
        val path: String,
        val type: String,
        val mimeType: String,
        val sizeBytes: Int,
    )

}
