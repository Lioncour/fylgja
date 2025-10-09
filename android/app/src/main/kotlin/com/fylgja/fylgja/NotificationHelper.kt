package com.fylgja.fylgja

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
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
        fun emergencyStop() {
            println("NotificationHelper: emergencyStop called")
            try {
                currentMediaPlayer?.let { mediaPlayer ->
                    try {
                        if (mediaPlayer.isPlaying) {
                            mediaPlayer.stop()
                        }
                    } catch (e: Exception) {
                        println("NotificationHelper: Error stopping mediaPlayer: ${e.message}")
                    }
                    try {
                        mediaPlayer.release()
                    } catch (e: Exception) {
                        println("NotificationHelper: Error releasing mediaPlayer: ${e.message}")
                    }
                }
            } catch (e: Exception) {
                println("NotificationHelper: Error in emergencyStop: ${e.message}")
            } finally {
                currentMediaPlayer = null
            }
            
            // Release wake lock
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
        
        // Acquire wake lock for standby mode sound playback
        fun acquireWakeLock(context: Context) {
            try {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = powerManager.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "Fylgja::CoverageSound"
                )
                wakeLock?.acquire(30000) // 30 seconds timeout
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

    fun showCoverageNotification() {
        println("NotificationHelper: showCoverageNotification called")
        
        // Acquire wake lock for standby mode sound playback
        acquireWakeLock(context)
        
        // Cancel any existing vibration first
        cancelVibration()
        
        // FORCE SOUND FIRST - Multiple strategies for standby mode
        val soundUri = Uri.parse("android.resource://${context.packageName}/raw/notification_sound")
        
        try {
            // Stop any existing sound first
            currentMediaPlayer?.release()
            
            currentMediaPlayer = MediaPlayer().apply {
                setDataSource(context, soundUri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM) // Use ALARM for standby mode
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED or AudioAttributes.FLAG_HW_AV_SYNC)
                        .build()
                )
                setVolume(1.0f, 1.0f) // Maximum volume
                prepare()
                start()
                setOnCompletionListener { 
                    // Restart the sound to create pip pip effect
                    try {
                        start()
                    } catch (e: Exception) {
                        println("NotificationHelper: Sound restart error: ${e.message}")
                        release()
                        currentMediaPlayer = null
                    }
                }
            }
            println("NotificationHelper: Sound played continuously with MediaPlayer (ALARM usage)")
        } catch (e: Exception) {
            println("NotificationHelper: Direct sound error: ${e.message}")
        }
        
        // FALLBACK: Also use RingtoneManager for standby mode
        try {
            val ringtone = RingtoneManager.getRingtone(context, soundUri)
            ringtone?.play()
            println("NotificationHelper: Fallback sound played with RingtoneManager")
        } catch (e: Exception) {
            println("NotificationHelper: RingtoneManager fallback error: ${e.message}")
        }
        
        // SIMPLIFIED VIBRATION - Single pattern that's easier to cancel
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vibratorManager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
            
            // Check if vibrator is available
            if (vibrator.hasVibrator()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    // Single, shorter vibration pattern that's easier to cancel
                    val vibrationEffect = VibrationEffect.createWaveform(longArrayOf(0, 500, 200, 500), 0)
                    vibrator.vibrate(vibrationEffect)
                    println("NotificationHelper: Vibration triggered (simplified pattern)")
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(longArrayOf(0, 500, 200, 500), 0)
                    println("NotificationHelper: Vibration triggered (legacy)")
                }
            } else {
                println("NotificationHelper: Vibrator not available")
            }
        } catch (e: Exception) {
            println("NotificationHelper: Vibration error: ${e.message}")
        }

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
            .setVibrate(longArrayOf(0, 1000, 500, 2000, 500, 1000)) // Aggressive vibration
            .setDefaults(NotificationCompat.DEFAULT_ALL)
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
    }


    private fun cancelVibration() {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vibratorManager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
            
            // Cancel any ongoing vibration multiple times to ensure it stops
            vibrator.cancel()
            Thread.sleep(50) // Small delay
            vibrator.cancel()
            Thread.sleep(50) // Small delay
            vibrator.cancel()
            
            // Force stop with zero amplitude vibration
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val stopVibration = VibrationEffect.createOneShot(1, 0) // 1ms with 0 amplitude
                vibrator.vibrate(stopVibration)
            }
            
            println("NotificationHelper: Vibration cancelled aggressively")
            
        } catch (e: Exception) {
            println("NotificationHelper: Error cancelling vibration: ${e.message}")
        }
    }

    fun cancelNotification() {
        println("NotificationHelper: cancelNotification called")
        
        // Stop vibration first
        cancelVibration()
        
        // Stop continuous sound
        currentMediaPlayer?.let { mediaPlayer ->
            try {
                mediaPlayer.stop()
                mediaPlayer.release()
                println("NotificationHelper: Continuous sound stopped")
            } catch (e: Exception) {
                println("NotificationHelper: Error stopping sound: ${e.message}")
            }
        }
        currentMediaPlayer = null
        
        // Release wake lock
        releaseWakeLock()
        
        // Cancel notification
        with(NotificationManagerCompat.from(context)) {
            cancel(NOTIFICATION_ID)
            println("NotificationHelper: Coverage notification cancelled")
        }
    }
    

}
