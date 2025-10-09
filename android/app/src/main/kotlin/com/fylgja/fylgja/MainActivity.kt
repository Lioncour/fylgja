package com.fylgja.fylgja

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.view.View
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "fylgja/notifications"
    private lateinit var notificationHelper: NotificationHelper

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
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
        
               MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                   println("MainActivity: Method called: ${call.method}")
                   when (call.method) {
                       "showCoverageNotification" -> {
                           println("MainActivity: showCoverageNotification called")
                           notificationHelper.showCoverageNotification()
                           result.success(null)
                       }
                       "cancelNotification" -> {
                           println("MainActivity: cancelNotification called")
                           notificationHelper.cancelNotification()
                           result.success(null)
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
        NotificationHelper.emergencyStop()
        notificationHelper.cancelNotification()
        super.onDestroy()
    }
    
    override fun onStop() {
        println("MainActivity: onStop called - stopping all notifications and sound")
        // Also stop when app goes to background
        notificationHelper.cancelNotification()
        super.onStop()
    }
    
    override fun onPause() {
        println("MainActivity: onPause called - stopping all notifications and sound")
        // Stop when app is paused
        notificationHelper.cancelNotification()
        super.onPause()
    }
}
