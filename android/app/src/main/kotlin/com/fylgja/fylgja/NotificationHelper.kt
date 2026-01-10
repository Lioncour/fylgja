package com.fylgja.fylgja

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import java.util.Timer
import java.util.TimerTask

class NotificationHelper(private val context: Context) {
    companion object {
        private const val CHANNEL_ID = "fylgja_coverage_channel"
        private const val CHANNEL_NAME = "Coverage Alerts"
        private const val CHANNEL_DESCRIPTION = "Notifications for when Fylgja finds network coverage."
        private const val NOTIFICATION_ID = 999
        
        // Static reference to current MediaPlayer for stopping continuous sound
        private var currentMediaPlayer: MediaPlayer? = null
        
        // Wake lock for standby mode sound playback
        private var wakeLock: PowerManager.WakeLock? = null
        
        // Simple flag to prevent multiple sounds
        @Volatile
        private var isPlaying = false
        
        // Timer to stop sound after a few seconds
        private var soundTimer: Timer? = null
        
        // Track if app is in foreground
        @Volatile
        private var isAppInForeground = false
        
        // Handler and Runnable for continuous vibration in standby - STATIC so they persist across instances
        @Volatile
        private var vibrationHandler: Handler? = null
        @Volatile
        private var vibrationRunnable: Runnable? = null
        @Volatile
        private var shouldVibrate = false
        
        // Flag to prevent starting vibration if we're in the process of stopping
        @Volatile
        private var isStopping = false
        
        fun setIsPlaying(value: Boolean) {
            isPlaying = value
        }
        
        fun getIsPlaying(): Boolean {
            return isPlaying
        }
        
        fun setAppInForeground(value: Boolean) {
            isAppInForeground = value
            println("NotificationHelper: App foreground state changed to: $value")
            // If app comes to foreground, cancel any existing notifications
            if (value) {
                println("NotificationHelper: App is now in foreground - cancelling any existing notifications")
                // Cancel notification but keep sound/vibration for a moment
                // The notification will be cancelled by the context's NotificationHelper instance
            }
        }
        
        fun isAppInForeground(): Boolean {
            return isAppInForeground
        }
        
        // Static method to force stop all sound and vibration
        fun forceStopAll() {
            println("NotificationHelper: forceStopAll called")
            currentMediaPlayer?.let { mediaPlayer ->
                try {
                    if (mediaPlayer.isPlaying) {
                        mediaPlayer.stop()
                    }
                    mediaPlayer.release()
                    println("NotificationHelper: Force stopped continuous sound")
                } catch (e: Exception) {
                    println("NotificationHelper: Error force stopping sound: ${e.message}")
                }
            }
            currentMediaPlayer = null
        }
        
        // More aggressive cleanup for app termination
        fun emergencyStop(context: Context) {
            println("NotificationHelper: emergencyStop called")
            
            // Stop all sound
            setIsPlaying(false)
            currentMediaPlayer?.let { mediaPlayer ->
                try {
                    mediaPlayer.setOnCompletionListener(null)
                    if (mediaPlayer.isPlaying) {
                        mediaPlayer.stop()
                    }
                    mediaPlayer.reset()
                    mediaPlayer.release()
                } catch (e: Exception) {
                    try {
                        mediaPlayer.release()
                    } catch (releaseError: Exception) {
                        println("NotificationHelper: Error force releasing MediaPlayer: ${releaseError.message}")
                    }
                }
            }
            currentMediaPlayer = null
            
            // Additional emergency cleanup
            try {
                // Stop any system sounds
                val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                audioManager.abandonAudioFocus(null)
                println("NotificationHelper: Audio focus abandoned")
            } catch (e: Exception) {
                println("NotificationHelper: Error abandoning audio focus: ${e.message}")
            }
        }
        
        // Acquire wake lock for standby mode sound playback
        fun acquireWakeLock(context: Context) {
            try {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = powerManager.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "Fylgja::CoverageSound"
                )
                wakeLock?.acquire(10*60*1000L) // 10 minutes timeout to ensure sound plays fully
                println("NotificationHelper: Wake lock acquired for standby mode")
            } catch (e: Exception) {
                println("NotificationHelper: Error acquiring wake lock: ${e.message}")
            }
        }
        
        // Release wake lock
        fun releaseWakeLock() {
            try {
                wakeLock?.let { lock ->
                    if (lock.isHeld) {
                        lock.release()
                        println("NotificationHelper: Wake lock released")
                    }
                }
            } catch (e: Exception) {
                println("NotificationHelper: Error releasing wake lock: ${e.message}")
            } finally {
                wakeLock = null
            }
        }
    }

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        println("NotificationHelper: Creating notification channel...")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_MAX // Changed to MAX for standby
                ).apply {
                    description = CHANNEL_DESCRIPTION
                    enableVibration(true)
                    enableLights(true)
                    setShowBadge(true)
                    lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC

                    // FORCE sound and vibration settings - use custom sound
                    val soundUri = Uri.parse("android.resource://${context.packageName}/raw/notification_sound")
                    println("NotificationHelper: Custom Sound URI: $soundUri")

                    val audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM) // Use ALARM for standby mode
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED or AudioAttributes.FLAG_HW_AV_SYNC)
                        .build()
                    setSound(soundUri, audioAttributes)

                    // Set aggressive vibration pattern for standby
                    val vibrationPattern = longArrayOf(0, 1000, 500, 2000, 500, 1000)
                    setVibrationPattern(vibrationPattern)

                    // Set light color for attention
                    lightColor = 0xFF0000FF.toInt()
                    enableLights(true)

                    println("NotificationHelper: Channel configured with MAX importance and aggressive settings")
                }

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            println("NotificationHelper: Channel created successfully")
        } else {
            println("NotificationHelper: Android version too old for channels")
        }
    }

    fun showCoverageNotification(showNotification: Boolean = true) {
        println("NotificationHelper: ===== SHOW COVERAGE NOTIFICATION CALLED =====")
        println("NotificationHelper: Timestamp: ${System.currentTimeMillis()}")
        println("NotificationHelper: Context package: ${context.packageName}")
        println("NotificationHelper: showNotification parameter: $showNotification")
        println("NotificationHelper: App in foreground: ${isAppInForeground()}")
        
        // If app is in foreground, NEVER show notification regardless of parameter
        val shouldShowNotification = showNotification && !isAppInForeground()
        println("NotificationHelper: Final decision - shouldShowNotification: $shouldShowNotification")
        
        if (getIsPlaying()) {
            println("NotificationHelper: ❌ Sound already playing, ignoring new request")
            return
        }
        println("NotificationHelper: ✅ Not playing, proceeding...")
        
        // Set playing flag FIRST before stopping anything
        setIsPlaying(true)
        
        // Stop existing sound/vibration BUT preserve vibration if it's already running
        // We only want to stop if we're not already vibrating
        if (!shouldVibrate) {
            println("NotificationHelper: No existing vibration, stopping all sound")
            stopAllSound()
        } else {
            println("NotificationHelper: Vibration already running, only stopping sound (not vibration)")
            // Only stop sound, not vibration
            currentMediaPlayer?.let { mediaPlayer ->
                try {
                    mediaPlayer.setOnCompletionListener(null)
                    if (mediaPlayer.isPlaying) {
                        mediaPlayer.stop()
                    }
                    mediaPlayer.reset()
                    mediaPlayer.release()
                } catch (e: Exception) {
                    println("NotificationHelper: Error stopping MediaPlayer: ${e.message}")
                }
            }
            currentMediaPlayer = null
            releaseWakeLock()
        }
        
        // Acquire wake lock for standby mode sound playback
        acquireWakeLock(context)
        
        // Don't cancel vibration here - we want it to continue if already running
        // Only cancel if we're starting a completely new notification
        if (!shouldVibrate) {
            println("NotificationHelper: No existing vibration, proceeding to start new one")
        } else {
            println("NotificationHelper: Vibration already running, will continue with existing vibration")
        }
        
        // Create new MediaPlayer
        val soundUri = Uri.parse("android.resource://${context.packageName}/raw/notification_sound")
        
        try {
            currentMediaPlayer = MediaPlayer().apply {
                setDataSource(context, soundUri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED or AudioAttributes.FLAG_HW_AV_SYNC)
                        .build()
                )
                setVolume(1.0f, 1.0f)
                prepare()
                start()
                setOnCompletionListener { 
                    // Restart the sound to keep it playing
                    if (getIsPlaying()) {
                        try {
                            start()
                        } catch (e: Exception) {
                            println("NotificationHelper: Sound restart error: ${e.message}")
                            setIsPlaying(false)
                            release()
                            currentMediaPlayer = null
                        }
                    }
                }
            }
            
            println("NotificationHelper: ✅ MediaPlayer started successfully!")
            println("NotificationHelper: Sound URI: $soundUri")
            println("NotificationHelper: Volume set to: 1.0")
            println("NotificationHelper: AudioAttributes: USAGE_ALARM")
            println("NotificationHelper: Sound will play continuously until stopSound() is called")
            // No timer - sound will play continuously until stopSound() is called
            
        } catch (e: Exception) {
            println("NotificationHelper: Error creating MediaPlayer: ${e.message}")
            setIsPlaying(false)
        }
        
        // NO FALLBACK - only use MediaPlayer to prevent multiple sounds
        
        // CONTINUOUS VIBRATION - Repeating pattern until stopSound() is called
        // Use Handler to ensure vibration continues even in standby mode
        // Only start new vibration if not already vibrating AND not in the process of stopping
        if (isStopping) {
            println("NotificationHelper: ⚠️ WARNING - isStopping is true, NOT starting vibration (prevented restart after stop)")
            return // Don't start vibration if we're stopping
        }
        
        if (!shouldVibrate) {
            println("NotificationHelper: Starting new continuous vibration")
            shouldVibrate = true
            vibrationHandler = Handler(Looper.getMainLooper())
        } else {
            println("NotificationHelper: Vibration already running, not starting new one")
            return // Don't start new vibration if already running
        }
        
        vibrationRunnable = object : Runnable {
            override fun run() {
                println("NotificationHelper: ===== VIBRATION RUNNABLE EXECUTED =====")
                println("NotificationHelper: Timestamp: ${System.currentTimeMillis()}")
                println("NotificationHelper: shouldVibrate flag: $shouldVibrate")
                
                // Check flag FIRST before doing anything
                if (!shouldVibrate) {
                    println("NotificationHelper: Vibration stopped - shouldVibrate is false, exiting runnable")
                    return
                }
                
                // Double-check handler still exists
                val currentHandler = vibrationHandler
                println("NotificationHelper: currentHandler exists: ${currentHandler != null}")
                if (currentHandler == null) {
                    println("NotificationHelper: Handler is null, exiting runnable")
                    return
                }
                
                try {
                    val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                        vibratorManager.defaultVibrator
                    } else {
                        @Suppress("DEPRECATION")
                        context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                    }
                    
                    // Check if vibrator is available and flag is still true
                    println("NotificationHelper: Checking vibrator - hasVibrator: ${vibrator.hasVibrator()}, shouldVibrate: $shouldVibrate")
                    if (vibrator.hasVibrator() && shouldVibrate) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            // Strong, continuous vibration pattern - vibrate 800ms, pause 300ms, repeat
                            // This creates a noticeable, continuous vibration
                            val vibrationPattern = longArrayOf(0, 800, 300, 800, 300, 800, 300, 800)
                            val vibrationEffect = VibrationEffect.createWaveform(vibrationPattern, 0) // 0 = repeat from start indefinitely
                            println("NotificationHelper: Creating vibration effect with pattern: ${vibrationPattern.contentToString()}, repeat index: 0")
                            vibrator.vibrate(vibrationEffect)
                            println("NotificationHelper: Continuous vibration triggered (repeating pattern) - pattern will repeat indefinitely")
                        } else {
                            @Suppress("DEPRECATION")
                            // For older Android, use repeating pattern
                            println("NotificationHelper: Using legacy vibration API")
                            vibrator.vibrate(longArrayOf(0, 800, 300, 800, 300, 800, 300, 800), 0) // 0 = repeat indefinitely
                            println("NotificationHelper: Continuous vibration triggered (legacy, repeating) - pattern will repeat indefinitely")
                        }
                        
                        // Schedule next vibration restart (every 2 seconds) to ensure it continues even if pattern stops
                        // This acts as a backup to ensure continuous vibration
                        println("NotificationHelper: Checking if should schedule next vibration - shouldVibrate: $shouldVibrate, currentHandler: ${currentHandler != null}")
                        if (shouldVibrate && currentHandler != null) {
                            currentHandler.postDelayed(this, 2000)
                            println("NotificationHelper: Scheduled next vibration restart in 2 seconds")
                        } else {
                            println("NotificationHelper: NOT scheduling next vibration - shouldVibrate: $shouldVibrate, currentHandler: ${currentHandler != null}")
                        }
                    } else {
                        println("NotificationHelper: Vibrator not available or shouldVibrate is false - hasVibrator: ${vibrator.hasVibrator()}, shouldVibrate: $shouldVibrate")
                    }
                } catch (e: Exception) {
                    println("NotificationHelper: Vibration error: ${e.message}")
                    e.printStackTrace()
                    // Retry after delay only if flag is still true and handler exists
                    if (shouldVibrate && currentHandler != null) {
                        currentHandler.postDelayed(this, 1000)
                        println("NotificationHelper: Retrying vibration after error in 1 second")
                    } else {
                        println("NotificationHelper: Not retrying - shouldVibrate is false or handler is null")
                    }
                }
            }
        }
        
        // Start vibration immediately
        vibrationHandler?.post(vibrationRunnable!!)
        println("NotificationHelper: Continuous vibration handler started - vibration will continue until stopSound() is called")

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // FORCE SOUND AND VIBRATION IN NOTIFICATION - Use custom sound for standby
        val customSoundUri = Uri.parse("android.resource://${context.packageName}/raw/notification_sound")
        println("NotificationHelper: Using custom sound URI: $customSoundUri")

        // Only show notification if requested AND app is NOT in foreground
        if (shouldShowNotification) {
            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle("Du har jammen meg dekning!")
                .setContentText("Trykk her for å pause søkingen")
                .setPriority(NotificationCompat.PRIORITY_MAX) // MAX for standby
                .setCategory(NotificationCompat.CATEGORY_ALARM) // ALARM category for standby
                .setAutoCancel(false)
                .setOngoing(true)
                .setContentIntent(pendingIntent)
                .setSound(customSoundUri) // Use custom sound
                // Don't set vibration here - we handle it directly with Handler for continuous vibration in standby
                .setDefaults(NotificationCompat.DEFAULT_LIGHTS) // Only lights, not vibration (we handle it directly)
                .setFullScreenIntent(pendingIntent, true) // Critical for standby
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC) // Critical for standby
                .setLights(0xFF0000FF.toInt(), 1000, 1000) // Red light for attention
                .setTimeoutAfter(0) // Don't timeout
                .setShowWhen(true)
                .setWhen(System.currentTimeMillis())
                .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE) // For standby
                .setColor(0xFF0000FF.toInt()) // Red color for urgency
                .build()

            with(NotificationManagerCompat.from(context)) {
                notify(NOTIFICATION_ID, notification)
                println("NotificationHelper: Coverage notification sent")
            }
        } else {
            println("NotificationHelper: Skipping notification (app in foreground)")
            println("NotificationHelper: Sound and vibration should already be playing")
            // Don't call cancelNotification() here as it would stop the sound/vibration we just started
            // Only cancel the notification display, not the sound/vibration
        }
    }

    private fun cancelVibration() {
        println("NotificationHelper: ===== CANCEL VIBRATION CALLED =====")
        println("NotificationHelper: Timestamp: ${System.currentTimeMillis()}")
        println("NotificationHelper: shouldVibrate BEFORE: $shouldVibrate")
        println("NotificationHelper: vibrationHandler BEFORE: ${vibrationHandler != null}")
        println("NotificationHelper: vibrationRunnable BEFORE: ${vibrationRunnable != null}")
        
        // CRITICAL: Set flag FIRST to stop runnable from rescheduling
        shouldVibrate = false
        println("NotificationHelper: Set shouldVibrate = false")
        
        // CRITICAL: Get references BEFORE nulling, and remove callbacks BEFORE nulling
        val handlerToStop = vibrationHandler
        val runnableToRemove = vibrationRunnable
        println("NotificationHelper: Stored handler reference: ${handlerToStop != null}")
        println("NotificationHelper: Stored runnable reference: ${runnableToRemove != null}")
        
        // Remove ALL callbacks and messages from handler BEFORE nulling
        if (handlerToStop != null) {
            runnableToRemove?.let { 
                val removedRunnable = handlerToStop.removeCallbacks(it)
                println("NotificationHelper: removeCallbacks(runnable) called - removed: $removedRunnable")
            }
            val removedCallbacks = handlerToStop.removeCallbacksAndMessages(null)
            println("NotificationHelper: removeCallbacksAndMessages(null) called - removed: $removedCallbacks")
        } else {
            println("NotificationHelper: WARNING - handlerToStop is null, cannot remove callbacks")
        }
        
        // NOW null the references after removing callbacks
        vibrationHandler = null
        vibrationRunnable = null
        println("NotificationHelper: Nulled handler and runnable references AFTER removing callbacks")
        println("NotificationHelper: Handler stopped and all callbacks removed")
        
        // Use Handler to cancel vibration on main thread to avoid blocking
        Handler(Looper.getMainLooper()).post {
            println("NotificationHelper: Inside Handler.post - on main thread")
            try {
                val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                    vibratorManager.defaultVibrator
                } else {
                    @Suppress("DEPRECATION")
                    context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                }
                
                println("NotificationHelper: Got vibrator instance")
                println("NotificationHelper: hasVibrator: ${vibrator.hasVibrator()}")
                
                // CRITICAL: Cancel the repeating vibration pattern immediately
                println("NotificationHelper: Calling vibrator.cancel() - FIRST TIME")
                vibrator.cancel()
                println("NotificationHelper: vibrator.cancel() completed")
                
                // Force stop with minimum amplitude vibration (Android 8.0+) - this overrides repeating patterns
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    try {
                        println("NotificationHelper: Android O+ detected, creating minimum amplitude vibration to override pattern")
                        // Create a one-shot minimum amplitude vibration (1) to override any repeating pattern
                        // Amplitude must be between 1-255, so we use 1 (minimum) instead of 0
                        val stopVibration = VibrationEffect.createOneShot(1, 1) // 1ms with minimum amplitude (1)
                        vibrator.vibrate(stopVibration)
                        println("NotificationHelper: Minimum amplitude vibration sent to force stop repeating pattern")
                    } catch (e: Exception) {
                        println("NotificationHelper: ERROR creating stop vibration: ${e.message}")
                        e.printStackTrace()
                    }
                } else {
                    println("NotificationHelper: Android version < O, skipping override vibration")
                }
                
                // Schedule additional cancels with Handler to avoid blocking
                Handler(Looper.getMainLooper()).postDelayed({
                    println("NotificationHelper: Second cancel after 50ms - calling vibrator.cancel()")
                    vibrator.cancel()
                    println("NotificationHelper: Second cancel completed")
                }, 50)
                
                Handler(Looper.getMainLooper()).postDelayed({
                    println("NotificationHelper: Third cancel after 100ms - calling vibrator.cancel()")
                    vibrator.cancel()
                    println("NotificationHelper: Third cancel completed")
                }, 100)
                
                Handler(Looper.getMainLooper()).postDelayed({
                    println("NotificationHelper: Final cancel after 200ms - calling vibrator.cancel()")
                    vibrator.cancel()
                    println("NotificationHelper: Final cancel completed")
                    println("NotificationHelper: ===== VIBRATION CANCELLATION COMPLETE =====")
                }, 200)
                
            } catch (e: Exception) {
                println("NotificationHelper: ERROR in cancelVibration Handler.post: ${e.message}")
                println("NotificationHelper: Exception type: ${e.javaClass.name}")
                e.printStackTrace()
            }
        }
        println("NotificationHelper: Handler.post scheduled, exiting cancelVibration()")
    }

    fun cancelNotification() {
        println("NotificationHelper: cancelNotification called")
        
        // Stop vibration first
        cancelVibration()
        
        // Stop all sound
        stopAllSound()
        
        // Cancel notification
        with(NotificationManagerCompat.from(context)) {
            cancel(NOTIFICATION_ID)
            println("NotificationHelper: Coverage notification cancelled")
        }
    }
    
    fun stopSound() {
        println("NotificationHelper: ===== STOP SOUND CALLED =====")
        println("NotificationHelper: Timestamp: ${System.currentTimeMillis()}")
        println("NotificationHelper: shouldVibrate flag BEFORE cancel: $shouldVibrate")
        println("NotificationHelper: vibrationHandler exists: ${vibrationHandler != null}")
        println("NotificationHelper: vibrationRunnable exists: ${vibrationRunnable != null}")
        
        // Set stopping flag FIRST to prevent new vibrations from starting
        isStopping = true
        println("NotificationHelper: Set isStopping = true to prevent vibration restart")
        
        // Cancel vibration first
        cancelVibration()
        
        println("NotificationHelper: shouldVibrate flag AFTER cancel: $shouldVibrate")
        println("NotificationHelper: vibrationHandler exists AFTER cancel: ${vibrationHandler != null}")
        println("NotificationHelper: vibrationRunnable exists AFTER cancel: ${vibrationRunnable != null}")
        
        // Then stop all sound
        stopAllSound()
        
        // Keep isStopping true for a short time to prevent immediate restart
        // Reset it after a delay to allow new vibrations in the future
        Handler(Looper.getMainLooper()).postDelayed({
            isStopping = false
            println("NotificationHelper: Reset isStopping = false after 2 seconds")
        }, 2000)
        
        println("NotificationHelper: ===== STOP SOUND COMPLETE =====")
    }
    
    private fun stopAllSound() {
        println("NotificationHelper: stopAllSound called")
        
        // Cancel timer
        soundTimer?.cancel()
        soundTimer = null
        
        // Set playing flag to false immediately
        setIsPlaying(false)
        
        // Stop current MediaPlayer
        currentMediaPlayer?.let { mediaPlayer ->
            try {
                println("NotificationHelper: Stopping MediaPlayer - isPlaying: ${mediaPlayer.isPlaying}")
                // Clear completion listener first
                mediaPlayer.setOnCompletionListener(null)
                if (mediaPlayer.isPlaying) {
                    mediaPlayer.stop()
                    println("NotificationHelper: MediaPlayer stopped")
                }
                mediaPlayer.reset()
                mediaPlayer.release()
                println("NotificationHelper: MediaPlayer released")
            } catch (e: Exception) {
                println("NotificationHelper: Error stopping MediaPlayer: ${e.message}")
                try {
                    mediaPlayer.release()
                } catch (releaseError: Exception) {
                    println("NotificationHelper: Error force releasing MediaPlayer: ${releaseError.message}")
                }
            }
        }
        currentMediaPlayer = null
        
        // Stop RingtoneManager sounds
        try {
            val ringtoneManager = RingtoneManager(context)
            ringtoneManager.stopPreviousRingtone()
            println("NotificationHelper: RingtoneManager stopped")
        } catch (e: Exception) {
            println("NotificationHelper: Error stopping RingtoneManager: ${e.message}")
        }
        
        // Release wake lock
        releaseWakeLock()
        
        println("NotificationHelper: All sound stopped")
    }
}