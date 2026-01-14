package no.fylgja.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "FylgjaBootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "BootReceiver: Received intent: ${intent.action}")
        
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> {
                Log.d(TAG, "BootReceiver: Device booted, checking battery optimization status")
                handleBootCompleted(context)
            }
        }
    }

    private fun handleBootCompleted(context: Context) {
        try {
            Log.d(TAG, "BootReceiver: Handling boot completed")
            
            // Check if app is in Doze Mode or App Standby
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val isIgnoringBatteryOptimizations = powerManager.isIgnoringBatteryOptimizations(context.packageName)
            
            Log.d(TAG, "BootReceiver: Battery optimization status - Ignoring: $isIgnoringBatteryOptimizations")
            
            if (!isIgnoringBatteryOptimizations) {
                Log.w(TAG, "BootReceiver: App is NOT ignoring battery optimizations - this may prevent background monitoring")
                Log.w(TAG, "BootReceiver: User should disable battery optimization for Fylgja in Settings")
            } else {
                Log.d(TAG, "BootReceiver: App is ignoring battery optimizations - background monitoring should work")
            }
            
            // Log Doze Mode status
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                val isDeviceIdleMode = powerManager.isDeviceIdleMode
                val isInteractive = powerManager.isInteractive
                
                Log.d(TAG, "BootReceiver: Device idle mode: $isDeviceIdleMode, Interactive: $isInteractive")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "BootReceiver: Error handling boot completed", e)
        }
    }
}

