package com.fylgja.fylgja

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class CoverageReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "CoverageReceiver"
        const val ACTION_COVERAGE_FOUND = "com.fylgja.fylgja.COVERAGE_FOUND"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "===== COVERAGE RECEIVER CALLED =====")
        Log.d(TAG, "CoverageReceiver: Timestamp: ${System.currentTimeMillis()}")
        Log.d(TAG, "CoverageReceiver: Intent action: ${intent.action}")
        Log.d(TAG, "CoverageReceiver: Context: $context")
        
        if (intent.action == ACTION_COVERAGE_FOUND) {
            Log.d(TAG, "CoverageReceiver: ✅ Intent action matches!")
            Log.d(TAG, "CoverageReceiver: Creating NotificationHelper...")
            
            try {
                val notificationHelper = NotificationHelper(context)
                Log.d(TAG, "CoverageReceiver: NotificationHelper created")
                Log.d(TAG, "CoverageReceiver: Calling showCoverageNotification()...")
                
                notificationHelper.showCoverageNotification()
                
                Log.d(TAG, "CoverageReceiver: ✅ Notification triggered successfully!")
                Log.d(TAG, "CoverageReceiver: ===== RECEIVER COMPLETE =====")
            } catch (e: Exception) {
                Log.e(TAG, "CoverageReceiver: ❌ ERROR showing notification: ${e.message}")
                e.printStackTrace()
                Log.e(TAG, "CoverageReceiver: Stack trace:", e)
            }
        } else {
            Log.w(TAG, "CoverageReceiver: ❌ Intent action doesn't match. Expected: $ACTION_COVERAGE_FOUND, Got: ${intent.action}")
        }
    }
}

