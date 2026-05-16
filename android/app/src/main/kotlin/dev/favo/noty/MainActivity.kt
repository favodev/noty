package dev.favo.noty

import android.content.ComponentName
import android.content.Intent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.IntentFilter
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
	companion object {
		private const val CHANNEL_NAME = "noty/native_notifications"
		private const val EVENT_CHANNEL_NAME = "noty/native_events"
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL_NAME)
			.setStreamHandler(object : EventChannel.StreamHandler {
				private var receiver: BroadcastReceiver? = null

				override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
					receiver = object : BroadcastReceiver() {
						override fun onReceive(context: Context?, intent: Intent?) {
							events?.success(null)
						}
					}
					// Consider registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED) for Android 14+ if needed, 
					// but for internal broadcasts, context.registerReceiver works fine on older or we can just use regular registerReceiver
					val filter = IntentFilter("dev.favo.noty.NEW_NOTIFICATION")
					if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
						registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
					} else {
						registerReceiver(receiver, filter)
					}
				}

				override fun onCancel(arguments: Any?) {
					receiver?.let { unregisterReceiver(it) }
					receiver = null
				}
			})

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"drainPendingNotifications" -> {
						val capturedActive = NotyNotificationListenerService.captureActiveNotificationsIfConnected()
						if (!capturedActive) {
							NotyNotificationListenerService.repairConnectionIfNeeded(applicationContext)
						}
						result.success(NotificationCaptureStore.drain(applicationContext))
					}

					"isNotificationListenerEnabled" -> {
						NotyNotificationListenerService.repairConnectionIfNeeded(applicationContext)
						result.success(NotificationCaptureStore.isListenerEnabled(applicationContext))
					}

					"getNativeDiagnostics" -> {
						NotyNotificationListenerService.repairConnectionIfNeeded(applicationContext)
						result.success(NotificationCaptureStore.diagnostics(applicationContext))
					}

					"ignoreCapturedNotification" -> {
						val notificationId = call.argument<String>("id").orEmpty()
						NotificationCaptureStore.ignoreNotification(applicationContext, notificationId)
						result.success(null)
					}

					"openNotificationListenerSettings" -> {
						openNotificationListenerSettings()
						result.success(null)
					}

					"getInstalledApps" -> {
						result.success(AppFilterStore.getInstalledApps(applicationContext))
					}

					"getAppIcons" -> {
						val packages = call.argument<List<String>>("packages") ?: emptyList()
						result.success(AppFilterStore.getAppIcons(applicationContext, packages))
					}

					"updateMonitoredPackages" -> {
						val packages = call.argument<List<String>>("packages") ?: emptyList()
						AppFilterStore.updateMonitoredPackages(applicationContext, packages)
						result.success(null)
					}

					"getMonitoredPackages" -> {
						result.success(AppFilterStore.getMonitoredPackages(applicationContext))
					}

					else -> result.notImplemented()
				}
			}
	}

	private fun openNotificationListenerSettings() {
		val component = ComponentName(
			applicationContext,
			NotyNotificationListenerService::class.java,
		)

		val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
			Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS)
				.putExtra(
					Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
					component.flattenToString(),
				)
		} else {
			Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
		}.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

		try {
			startActivity(intent)
		} catch (_: Exception) {
			startActivity(
				Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
					.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			)
		}
	}
}
