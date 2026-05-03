package dev.favo.noty

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	companion object {
		private const val CHANNEL_NAME = "noty/native_notifications"
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"drainPendingNotifications" -> {
						result.success(NotificationCaptureStore.drain(applicationContext))
					}

					"isNotificationListenerEnabled" -> {
						result.success(NotificationCaptureStore.isListenerEnabled(applicationContext))
					}

					"openNotificationListenerSettings" -> {
						val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
							.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						startActivity(intent)
						result.success(null)
					}

					else -> result.notImplemented()
				}
			}
	}
}
