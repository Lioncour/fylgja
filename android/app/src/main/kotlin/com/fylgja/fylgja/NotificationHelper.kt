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

                    // FORCE sound and vibration settings
                    val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    println("NotificationHelper: Sound URI: $soundUri")

                    val audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
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
        
        // Cancel any existing vibration first
        cancelVibration()
        
        // FORCE SOUND FIRST
        try {
            val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val mediaPlayer = MediaPlayer().apply {
                setDataSource(context, soundUri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                prepare()
                start()
                setOnCompletionListener { release() }
            }
            println("NotificationHelper: Sound played directly with MediaPlayer")
        } catch (e: Exception) {
            println("NotificationHelper: Direct sound error: ${e.message}")
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

        // FORCE SOUND AND VIBRATION IN NOTIFICATION
        val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        println("NotificationHelper: Using sound URI: $soundUri")

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("Du har jammen meg dekning!")
            .setContentText("Trykk her for å pause søkingen")
            .setPriority(NotificationCompat.PRIORITY_MAX) // Changed to MAX for standby
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(false)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setSound(soundUri)
            .setVibrate(longArrayOf(0, 1000, 500, 2000))
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setFullScreenIntent(pendingIntent, true) // This helps with standby
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC) // This helps with standby
            .setLights(0xFF0000FF.toInt(), 1000, 1000) // Red light for attention
            .setTimeoutAfter(0) // Don't timeout
            .setShowWhen(true)
            .setWhen(System.currentTimeMillis())
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
        
        // Cancel notification
        with(NotificationManagerCompat.from(context)) {
            cancel(NOTIFICATION_ID)
            println("NotificationHelper: Coverage notification cancelled")
        }
    }

}
