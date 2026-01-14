package no.fylgja.app

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
        
        // List of ALL active MediaPlayers to stop them all
        private val activeMediaPlayers = mutableListOf<MediaPlayer>()
        
        // Wake lock for standby mode sound playback
        private var wakeLock: PowerManager.WakeLock? = null
        
        // Audio focus request for Android O+
        private var audioFocusRequest: android.media.AudioFocusRequest? = null
        
        // STATIC lock object for synchronizing MediaPlayer creation (companion object level)
        private val mediaPlayerLock = Any()
        
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
        
        // Reset isStopping flag when starting a new notification - allows new vibration to start
        if (isStopping) {
            println("NotificationHelper: Resetting isStopping flag to allow new vibration to start")
            isStopping = false
        }
        
        // If app is in foreground, NEVER show notification regardless of parameter
        val shouldShowNotification = showNotification && !isAppInForeground()
        println("NotificationHelper: Final decision - shouldShowNotification: $shouldShowNotification")
        
        // CRITICAL: Single synchronized block for everything to prevent race conditions
        synchronized(mediaPlayerLock) {
            // Check if already playing FIRST (before doing anything)
            if (getIsPlaying() || currentMediaPlayer != null) {
                println("NotificationHelper: ❌ Sound already playing or MediaPlayer exists, ignoring new request (prevented by lock)")
                return
            }
            
            // Stop ALL existing MediaPlayers FIRST to prevent multiple sounds
            // Stop currentMediaPlayer
            currentMediaPlayer?.let { existingPlayer ->
                println("NotificationHelper: ⚠️ Existing MediaPlayer found, stopping it first to prevent multiple sounds")
                try {
                    existingPlayer.isLooping = false
                    existingPlayer.setOnCompletionListener(null)
                    existingPlayer.setOnPreparedListener(null)
                    existingPlayer.setOnErrorListener(null)
                    try {
                        if (existingPlayer.isPlaying) {
                            existingPlayer.pause()
                            println("NotificationHelper: Existing MediaPlayer paused")
                        }
                    } catch (pauseError: Exception) {
                        println("NotificationHelper: Error pausing existing MediaPlayer: ${pauseError.message}")
                    }
                    try {
                        existingPlayer.stop()
                        println("NotificationHelper: Existing MediaPlayer stopped")
                    } catch (stopError: Exception) {
                        println("NotificationHelper: Error stopping existing MediaPlayer: ${stopError.message}")
                    }
                    existingPlayer.reset()
                    existingPlayer.release()
                    println("NotificationHelper: ✅ Existing MediaPlayer stopped and released")
                } catch (e: Exception) {
                    println("NotificationHelper: Error stopping existing MediaPlayer: ${e.message}")
                    try {
                        existingPlayer.release()
                    } catch (releaseError: Exception) {
                        println("NotificationHelper: Error force releasing existing MediaPlayer: ${releaseError.message}")
                    }
                }
            }
            
            // Stop ALL MediaPlayers in the active list
            synchronized(activeMediaPlayers) {
                activeMediaPlayers.forEach { player ->
                    try {
                        println("NotificationHelper: Stopping MediaPlayer from active list")
                        player.isLooping = false
                        player.setOnCompletionListener(null)
                        player.setOnPreparedListener(null)
                        player.setOnErrorListener(null)
                        try {
                            if (player.isPlaying) {
                                player.pause()
                            }
                        } catch (e: Exception) {
                            // Ignore
                        }
                        try {
                            player.stop()
                        } catch (e: Exception) {
                            // Ignore
                        }
                        player.reset()
                        player.release()
                        println("NotificationHelper: ✅ MediaPlayer from active list stopped and released")
                    } catch (e: Exception) {
                        println("NotificationHelper: Error stopping MediaPlayer from active list: ${e.message}")
                        try {
                            player.release()
                        } catch (releaseError: Exception) {
                            // Ignore
                        }
                    }
                }
                activeMediaPlayers.clear()
            }
            
            currentMediaPlayer = null
            setIsPlaying(false) // Reset flag after stopping
            
            println("NotificationHelper: ✅ Not playing, proceeding to create MediaPlayer (inside synchronized block)")
            
            // Acquire wake lock for standby mode sound playback
            acquireWakeLock(context)
            
            // Create new MediaPlayer with continuous looping
            // Create manually so we can set audio attributes before preparing
            val resourceId = context.resources.getIdentifier("notification_sound", "raw", context.packageName)
            println("NotificationHelper: Resource ID for notification_sound: $resourceId")
            
            // Request audio focus first
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val audioFocusResult = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val focusRequest = android.media.AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    // Don't use setAcceptsDelayedFocusGain - requires a listener
                    .build()
                audioFocusRequest = focusRequest // Store for later abandonment
                val result = audioManager.requestAudioFocus(focusRequest)
                println("NotificationHelper: Audio focus requested (O+): result = $result")
                result
            } else {
                @Suppress("DEPRECATION")
                val result = audioManager.requestAudioFocus(
                    null,
                    AudioManager.STREAM_ALARM,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
                )
                println("NotificationHelper: Audio focus requested (legacy): result = $result")
                result
            }
            
            if (audioFocusResult != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                println("NotificationHelper: ⚠️ Audio focus not granted, but continuing anyway")
            }
            
            try {
                val newMediaPlayer = MediaPlayer().apply {
                setOnErrorListener { mp, what, extra ->
                    println("NotificationHelper: ❌ MediaPlayer ERROR - what: $what, extra: $extra")
                    println("NotificationHelper: Error codes - MEDIA_ERROR_UNKNOWN: 1, MEDIA_ERROR_SERVER_DIED: 100")
                    println("NotificationHelper: Extra codes - MEDIA_ERROR_IO: -1004, MEDIA_ERROR_MALFORMED: -1007, MEDIA_ERROR_UNSUPPORTED: -1010, MEDIA_ERROR_TIMED_OUT: -110")
                    when (extra) {
                        -19 -> println("NotificationHelper: Error -19 = MEDIA_ERROR_UNSUPPORTED - Audio format may not be supported")
                        -1004 -> println("NotificationHelper: Error -1004 = MEDIA_ERROR_IO - File I/O error")
                        -1007 -> println("NotificationHelper: Error -1007 = MEDIA_ERROR_MALFORMED - File is malformed")
                        -1010 -> println("NotificationHelper: Error -1010 = MEDIA_ERROR_UNSUPPORTED - Format not supported")
                        -110 -> println("NotificationHelper: Error -110 = MEDIA_ERROR_TIMED_OUT - Operation timed out")
                        else -> println("NotificationHelper: Unknown error code: $extra")
                    }
                    setIsPlaying(false)
                    true // Return true to indicate error was handled
                }
                
                setOnPreparedListener { mp ->
                    println("NotificationHelper: ✅ MediaPlayer prepared successfully!")
                    try {
                        mp.start()
                        println("NotificationHelper: ✅ MediaPlayer started with looping enabled!")
                        println("NotificationHelper: MediaPlayer isPlaying: ${mp.isPlaying}")
                    } catch (e: Exception) {
                        println("NotificationHelper: ❌ Error starting MediaPlayer after prepare: ${e.message}")
                        e.printStackTrace()
                        setIsPlaying(false)
                    }
                }
                
                // Set audio attributes FIRST (before setDataSource)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
                        .build()
                )
                println("NotificationHelper: AudioAttributes set to USAGE_ALARM")
                
                // Set data source using resource ID or URI
                if (resourceId != 0) {
                    val soundUri = Uri.parse("android.resource://${context.packageName}/raw/notification_sound")
                    println("NotificationHelper: Setting data source using resource URI: $soundUri")
                    setDataSource(context, soundUri)
                } else {
                    val soundUri = Uri.parse("android.resource://${context.packageName}/raw/notification_sound")
                    println("NotificationHelper: Resource ID not found, using URI fallback: $soundUri")
                    setDataSource(context, soundUri)
                }
                
                setVolume(1.0f, 1.0f)
                isLooping = true // Loop continuously for smooth playback
                
                println("NotificationHelper: Volume set to: 1.0")
                println("NotificationHelper: Looping enabled: $isLooping")
                println("NotificationHelper: Preparing MediaPlayer asynchronously...")
                
                    prepareAsync() // Use async prepare
                }
                
                // Store the MediaPlayer reference
                currentMediaPlayer = newMediaPlayer
                
                // Add to active list for tracking
                synchronized(activeMediaPlayers) {
                    activeMediaPlayers.add(newMediaPlayer)
                    println("NotificationHelper: MediaPlayer added to active list (total: ${activeMediaPlayers.size})")
                }
                
                // Set playing flag AFTER MediaPlayer is created and added to list
                setIsPlaying(true)
                println("NotificationHelper: ✅ MediaPlayer created and will start when prepared! (isPlaying set to true)")
            } catch (e: Exception) {
                println("NotificationHelper: ❌ Error creating MediaPlayer: ${e.message}")
                e.printStackTrace()
                setIsPlaying(false)
            }
        }
        
        // NO FALLBACK - only use MediaPlayer to prevent multiple sounds
        
        // CONTINUOUS VIBRATION - Use NON-REPEATING pattern with Handler restart for better control
        // Only start new vibration if not already vibrating AND not in the process of stopping
        if (isStopping) {
            println("NotificationHelper: ⚠️ WARNING - isStopping is true, NOT starting vibration (prevented restart after stop)")
            return // Don't start vibration if we're stopping
        }
        
        if (!shouldVibrate) {
            println("NotificationHelper: Starting new continuous vibration with Handler-based restart")
            shouldVibrate = true
            vibrationHandler = Handler(Looper.getMainLooper())
        } else {
            println("NotificationHelper: Vibration already running, not starting new one")
            return // Don't start new vibration if already running
        }
        
        // Get vibrator instance once
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        
        if (!vibrator.hasVibrator()) {
            println("NotificationHelper: Vibrator not available")
            shouldVibrate = false
            vibrationHandler = null
            return
        }
        
        // Create a NON-REPEATING vibration pattern (repeat index -1 means don't repeat)
        // We'll restart it manually via Handler for better control
        // Pattern: vibrate 5000ms, pause 50ms, vibrate 5000ms, pause 50ms, vibrate 5000ms = 15100ms total
        // This creates a much more continuous feeling - 15 seconds of vibration with only 0.1s of pauses
        val vibrationPattern = longArrayOf(0, 5000, 50, 5000, 50, 5000) // Total: 15100ms (15s vibration, 0.1s pause)
        val vibrationDuration = vibrationPattern.sum() // Total duration of one cycle
        println("NotificationHelper: Vibration pattern: ${vibrationPattern.contentToString()}, total duration: ${vibrationDuration}ms (${vibrationDuration/1000.0}s) - ${(vibrationDuration-100)/1000.0}s vibration, 0.1s pause")
        
        vibrationRunnable = object : Runnable {
            override fun run() {
                val timestamp = System.currentTimeMillis()
                println("NotificationHelper: ===== VIBRATION RUNNABLE EXECUTED ===== (Timestamp: $timestamp)")
                
                // CRITICAL: Check flags FIRST before doing ANYTHING - must be the very first check
                // Read flags into local variables to ensure we check the current state
                val shouldVibrateNow = shouldVibrate
                val isStoppingNow = isStopping
                
                println("NotificationHelper: Flag check - shouldVibrate: $shouldVibrateNow, isStopping: $isStoppingNow")
                
                if (!shouldVibrateNow || isStoppingNow) {
                    println("NotificationHelper: ✅✅✅ VIBRATION STOPPED - shouldVibrate: $shouldVibrateNow, isStopping: $isStoppingNow, EXITING RUNNABLE IMMEDIATELY (stop worked!)")
                    return // Exit immediately - don't do anything else
                }
                
                println("NotificationHelper: Flags OK, proceeding with vibration")
                
                // Double-check handler still exists
                val currentHandler = vibrationHandler
                println("NotificationHelper: currentHandler exists: ${currentHandler != null}")
                if (currentHandler == null) {
                    println("NotificationHelper: Handler is null, exiting runnable")
                    return
                }
                
                try {
                    // DON'T cancel existing vibration - let it finish naturally, then start new one
                    // Only cancel if we're actually stopping (which is checked by flags above)
                    // This prevents interrupting the current vibration pattern
                    
                    // Use NON-REPEATING pattern (repeat index -1) with amplitude for stronger vibration
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        // Create amplitude array - use maximum amplitude (255) for all vibration segments
                        // Pattern: [0, 2000, 100, 2000, 100, 2000] = 6 elements
                        // Amplitudes: [0, 255, 0, 255, 0, 255] = 6 elements (must match!)
                        val amplitudes = intArrayOf(0, 255, 0, 255, 0, 255) // Max amplitude for vibration, 0 for pauses
                        val vibrationEffect = VibrationEffect.createWaveform(vibrationPattern, amplitudes, -1) // -1 = don't repeat
                        println("NotificationHelper: Creating NON-REPEATING vibration effect with MAX amplitude (255) - will restart via Handler")
                        println("NotificationHelper: Pattern length: ${vibrationPattern.size}, Amplitude length: ${amplitudes.size}")
                        vibrator.vibrate(vibrationEffect)
                        println("NotificationHelper: ✅ Vibration triggered with MAX amplitude (non-repeating, will restart in ${vibrationDuration}ms)")
                    } else {
                        @Suppress("DEPRECATION")
                        // For older Android, use non-repeating pattern (no repeat parameter = don't repeat)
                        vibrator.vibrate(vibrationPattern, -1) // -1 = don't repeat
                        println("NotificationHelper: Vibration triggered (legacy, non-repeating, will restart in ${vibrationDuration}ms)")
                    }
                    
                    // Schedule next vibration restart BEFORE current one ends (at 99% of duration)
                    // This ensures continuous vibration without gaps - restart just before pattern ends
                    // Using 99% to make it feel more continuous with longer patterns
                    val restartDelay = (vibrationDuration * 0.99).toLong()
                    println("NotificationHelper: Scheduling next vibration restart in ${restartDelay}ms (99% of ${vibrationDuration}ms = ${vibrationDuration/1000.0}s duration)")
                    
                    // Double-check flags and handler before scheduling
                    val shouldSchedule = shouldVibrate && !isStopping && currentHandler != null
                    println("NotificationHelper: Scheduling check - shouldVibrate: $shouldVibrate, isStopping: $isStopping, handler exists: ${currentHandler != null}, shouldSchedule: $shouldSchedule")
                    
                    if (shouldSchedule) {
                        currentHandler!!.postDelayed(this, restartDelay)
                        println("NotificationHelper: ✅ Next vibration scheduled successfully - will execute in ${restartDelay}ms")
                    } else {
                        println("NotificationHelper: ❌ NOT scheduling next vibration - shouldVibrate: $shouldVibrate, isStopping: $isStopping, handler: ${currentHandler != null}")
                    }
                } catch (e: Exception) {
                    println("NotificationHelper: ❌ Vibration error: ${e.message}")
                    e.printStackTrace()
                    // Retry after delay only if flags are still true
                    if (shouldVibrate && !isStopping && currentHandler != null) {
                        currentHandler.postDelayed(this, 1000)
                        println("NotificationHelper: Retrying vibration after error in 1 second")
                    } else {
                        println("NotificationHelper: Not retrying - flags changed")
                    }
                }
            }
        }
        
        // Start vibration immediately
        vibrationHandler?.post(vibrationRunnable!!)
        println("NotificationHelper: ✅ Continuous vibration handler started - will restart every ~${vibrationDuration}ms until stopSound() is called")

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
                // Removed setFullScreenIntent() - not allowed by Google Play policy (only for alarms/calls)
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
        val timestamp = System.currentTimeMillis()
        println("NotificationHelper: ===== CANCEL VIBRATION CALLED ===== (Timestamp: $timestamp)")
        println("NotificationHelper: shouldVibrate BEFORE: $shouldVibrate")
        println("NotificationHelper: isStopping BEFORE: $isStopping")
        println("NotificationHelper: vibrationHandler BEFORE: ${vibrationHandler != null}")
        println("NotificationHelper: vibrationRunnable BEFORE: ${vibrationRunnable != null}")
        
        // CRITICAL: Set flags FIRST and SYNCHRONOUSLY to stop runnable from rescheduling
        // Use synchronized block or ensure atomic flag setting
        shouldVibrate = false
        isStopping = true // Also set isStopping to prevent any restart
        println("NotificationHelper: ✅ Set shouldVibrate = false and isStopping = true (flags set synchronously)")
        
        // Give a tiny delay to ensure flags are visible to other threads
        // This is a safety measure - the @Volatile annotation should handle this, but this ensures it
        Thread.sleep(1) // 1ms delay to ensure flags propagate
        println("NotificationHelper: Flags propagated, any executing runnable should now see them")
        
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
        println("NotificationHelper: ===== STOP ALL SOUND CALLED =====")
        println("NotificationHelper: currentMediaPlayer exists: ${currentMediaPlayer != null}")
        
        // Cancel timer
        soundTimer?.cancel()
        soundTimer = null
        
        // Set playing flag to false immediately
        setIsPlaying(false)
        
        // Stop current MediaPlayer - ALWAYS try to stop, even if in error state
        val playerToStop: MediaPlayer?
        synchronized(mediaPlayerLock) {
            playerToStop = currentMediaPlayer
            currentMediaPlayer = null // Clear reference immediately to prevent race conditions
        }
        
        playerToStop?.let { mediaPlayer ->
            println("NotificationHelper: Stopping MediaPlayer (reference obtained)...")
            try {
                // Disable looping first to prevent restart
                try {
                    mediaPlayer.isLooping = false
                    println("NotificationHelper: Looping disabled")
                } catch (e: Exception) {
                    println("NotificationHelper: Error disabling looping: ${e.message}")
                }
                
                // Clear all listeners FIRST to prevent callbacks
                try {
                    mediaPlayer.setOnCompletionListener(null)
                    mediaPlayer.setOnPreparedListener(null)
                    mediaPlayer.setOnErrorListener(null)
                    println("NotificationHelper: All listeners cleared")
                } catch (e: Exception) {
                    println("NotificationHelper: Error clearing listeners: ${e.message}")
                }
                
                // For looping MediaPlayers, pause first, then stop
                try {
                    // Pause first to immediately stop playback (works better with looping)
                    try {
                        mediaPlayer.pause()
                        println("NotificationHelper: ✅ MediaPlayer.pause() called (stops looping immediately)")
                    } catch (pauseError: Exception) {
                        println("NotificationHelper: Error calling pause(): ${pauseError.message}")
                    }
                    
                    // Then stop
                    mediaPlayer.stop()
                    println("NotificationHelper: ✅ MediaPlayer.stop() called")
                } catch (e: Exception) {
                    println("NotificationHelper: Error calling stop(): ${e.message}")
                    // Continue anyway - try reset and release
                }
                
                // Reset
                try {
                    mediaPlayer.reset()
                    println("NotificationHelper: ✅ MediaPlayer.reset() called")
                } catch (e: Exception) {
                    println("NotificationHelper: Error calling reset(): ${e.message}")
                }
                
                // Release
                try {
                    mediaPlayer.release()
                    println("NotificationHelper: ✅ MediaPlayer.release() called - sound should be stopped")
                } catch (e: Exception) {
                    println("NotificationHelper: Error calling release(): ${e.message}")
                }
                
                // Remove from active list
                synchronized(activeMediaPlayers) {
                    activeMediaPlayers.remove(mediaPlayer)
                    println("NotificationHelper: MediaPlayer removed from active list")
                }
            } catch (e: Exception) {
                println("NotificationHelper: ❌ Exception in stopAllSound: ${e.message}")
                e.printStackTrace()
                // Force release as last resort
                try {
                    mediaPlayer.release()
                    println("NotificationHelper: Force released MediaPlayer")
                } catch (releaseError: Exception) {
                    println("NotificationHelper: Error force releasing MediaPlayer: ${releaseError.message}")
                }
                // Remove from active list
                synchronized(activeMediaPlayers) {
                    activeMediaPlayers.remove(mediaPlayer)
                }
            }
        }
        
        // Stop ALL MediaPlayers in active list (in case some escaped)
        synchronized(activeMediaPlayers) {
            if (activeMediaPlayers.isNotEmpty()) {
                println("NotificationHelper: ⚠️ Found ${activeMediaPlayers.size} MediaPlayer(s) in active list, stopping all")
                activeMediaPlayers.forEach { player ->
                    try {
                        player.isLooping = false
                        player.setOnCompletionListener(null)
                        player.setOnPreparedListener(null)
                        player.setOnErrorListener(null)
                        try {
                            if (player.isPlaying) {
                                player.pause()
                            }
                        } catch (e: Exception) {
                            // Ignore
                        }
                        try {
                            player.stop()
                        } catch (e: Exception) {
                            // Ignore
                        }
                        player.reset()
                        player.release()
                        println("NotificationHelper: ✅ Stopped and released MediaPlayer from active list")
                    } catch (e: Exception) {
                        println("NotificationHelper: Error stopping MediaPlayer from active list: ${e.message}")
                        try {
                            player.release()
                        } catch (releaseError: Exception) {
                            // Ignore
                        }
                    }
                }
                activeMediaPlayers.clear()
                println("NotificationHelper: ✅ All MediaPlayers from active list stopped and cleared")
            } else {
                println("NotificationHelper: No MediaPlayers in active list to stop")
            }
        }
        
        // Release audio focus
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let { request ->
                    val result = audioManager.abandonAudioFocusRequest(request)
                    println("NotificationHelper: Audio focus abandoned (O+): result = $result")
                } ?: run {
                    println("NotificationHelper: No audio focus request to abandon")
                }
            } else {
                @Suppress("DEPRECATION")
                val result = audioManager.abandonAudioFocus(null)
                println("NotificationHelper: Audio focus abandoned (legacy): result = $result")
            }
            audioFocusRequest = null
        } catch (e: Exception) {
            println("NotificationHelper: Error abandoning audio focus: ${e.message}")
            e.printStackTrace()
        }
        
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