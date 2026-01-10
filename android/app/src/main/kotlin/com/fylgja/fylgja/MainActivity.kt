package com.fylgja.fylgja

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.view.View
import android.content.Intent
import android.content.IntentFilter
import android.content.BroadcastReceiver
import android.provider.Settings
import android.net.Uri
import android.os.PowerManager
import android.content.Context
import android.content.Context.RECEIVER_NOT_EXPORTED
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "fylgja/notifications"
    private val CONNECTIVITY_CHANNEL = "fylgja/connectivity"
    private val EVENT_CHANNEL = "fylgja/events"
    private lateinit var notificationHelper: NotificationHelper
    private var eventSink: EventChannel.EventSink? = null
    
    // Broadcast receiver for coverage events from native service
    private val coverageReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.fylgja.fylgja.COVERAGE_FOUND") {
                println("MainActivity: ===== COVERAGE BROADCAST RECEIVED =====")
                println("MainActivity: Sending event to Flutter...")
                eventSink?.success("coverage_found")
                println("MainActivity: ✅ Event sent to Flutter")
            }
        }
    }
    
    private fun sendCoverageAlertBroadcast() {
        println("MainActivity: Creating broadcast intent...")
        val intent = Intent(CoverageReceiver.ACTION_COVERAGE_FOUND)
        intent.`package` = packageName
        intent.setFlags(Intent.FLAG_INCLUDE_STOPPED_PACKAGES)
        println("MainActivity: Intent created with package: ${intent.`package`}")
        println("MainActivity: Action: ${intent.action}")
        
        sendBroadcast(intent)
        println("MainActivity: ✅ Broadcast sent successfully")
    }

    override fun onResume() {
        super.onResume()
        println("MainActivity: onResume - app is now in FOREGROUND")
        NotificationHelper.setAppInForeground(true)
        // Cancel any existing notifications when app comes to foreground
        if (::notificationHelper.isInitialized) {
            notificationHelper.cancelNotification()
        }
    }
    
    override fun onPause() {
        super.onPause()
        println("MainActivity: onPause - app is now in BACKGROUND")
        NotificationHelper.setAppInForeground(false)
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize foreground state
        NotificationHelper.setAppInForeground(true) // Assume foreground on create
        
        // Register broadcast receiver for coverage events from native service
        val filter = IntentFilter("com.fylgja.fylgja.COVERAGE_FOUND")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+ requires explicit export flag
            registerReceiver(coverageReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(coverageReceiver, filter)
        }
        println("MainActivity: Broadcast receiver registered")
        
        // Request notification permission for Android 13+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
                println("MainActivity: Requesting notification permission")
            }
        }
        
        // Request to ignore battery optimizations for better standby mode operation
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                }
                try {
                    startActivity(intent)
                    println("MainActivity: Requested battery optimization exemption")
                } catch (e: Exception) {
                    println("MainActivity: Could not request battery optimization exemption: ${e.message}")
                }
            }
        }
        
        // Make status bar transparent
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            )
        }
        
        // Make status bar transparent and content go behind it
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            window.statusBarColor = android.graphics.Color.TRANSPARENT
        }
        
        // Make navigation bar transparent too
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            window.navigationBarColor = android.graphics.Color.TRANSPARENT
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        notificationHelper = NotificationHelper(this)
        
        // Event channel for native service to communicate with Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    println("MainActivity: EventChannel listener attached")
                    eventSink = events
                }
                
                override fun onCancel(arguments: Any?) {
                    println("MainActivity: EventChannel listener cancelled")
                    eventSink = null
                }
            }
        )
        
        // Connectivity monitoring service channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONNECTIVITY_CHANNEL).setMethodCallHandler { call, result ->
            println("MainActivity: Connectivity method called: ${call.method}")
            when (call.method) {
                "startMonitoring" -> {
                    println("MainActivity: Starting native connectivity service...")
                    ConnectivityMonitoringService.startService(this)
                    println("MainActivity: ✅ Service start requested")
                    result.success(null)
                }
                "stopMonitoring" -> {
                    println("MainActivity: Stopping native connectivity service...")
                    ConnectivityMonitoringService.stopService(this)
                    println("MainActivity: ✅ Service stop requested")
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Notification channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                   println("MainActivity: Method called: ${call.method}")
                   when (call.method) {
                       "showCoverageNotification" -> {
                           println("MainActivity: showCoverageNotification called")
                           val showNotification = call.arguments<Map<*, *>>()?.get("showNotification") as? Boolean ?: true
                           notificationHelper.showCoverageNotification(showNotification)
                           result.success(null)
                       }
                       "cancelNotification" -> {
                           println("MainActivity: cancelNotification called")
                           notificationHelper.cancelNotification()
                           result.success(null)
                       }
                       "stopSound" -> {
                           println("MainActivity: ===== STOP SOUND METHOD CHANNEL CALLED =====")
                           println("MainActivity: Timestamp: ${System.currentTimeMillis()}")
                           println("MainActivity: Calling notificationHelper.stopSound()")
                           notificationHelper.stopSound()
                           println("MainActivity: notificationHelper.stopSound() completed")
                           result.success(null)
                           println("MainActivity: Method channel result sent")
                           println("MainActivity: ===== STOP SOUND METHOD CHANNEL COMPLETE =====")
                       }
                       "triggerAlert" -> {
                           println("MainActivity: triggerAlert called")
                           notificationHelper.showCoverageNotification()
                           result.success(null)
                       }
                       "sendCoverageAlert" -> {
                           println("MainActivity: ===== SEND COVERAGE ALERT CALLED =====")
                           println("MainActivity: Timestamp: ${System.currentTimeMillis()}")
                           println("MainActivity: Sending broadcast to CoverageReceiver...")
                           try {
                               sendCoverageAlertBroadcast()
                               println("MainActivity: ✅ Broadcast sent successfully")
                               result.success("broadcast_sent")
                           } catch (e: Exception) {
                               println("MainActivity: ❌ Error sending broadcast: ${e.message}")
                               e.printStackTrace()
                               result.error("ERROR", e.message, null)
                           }
                       }
                       else -> {
                           println("MainActivity: Unknown method: ${call.method}")
                           result.notImplemented()
                       }
                   }
               }
    }
    
    override fun onDestroy() {
        println("MainActivity: onDestroy called - emergency stopping all notifications and sound")
        // Emergency stop all sound and vibration when app is destroyed
        NotificationHelper.emergencyStop(this)
        notificationHelper.cancelNotification()
        super.onDestroy()
    }
    
    // Removed onStop() and onPause() cancel calls to allow notifications in standby mode
}
