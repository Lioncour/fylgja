package no.fylgja.app

import android.app.*
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class ConnectivityMonitoringService : Service() {
    private val TAG = "ConnectivityMonitor"
    private var connectivityManager: ConnectivityManager? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var connectivityCallback: ConnectivityManager.NetworkCallback? = null
    private var isMonitoring = false
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "===== SERVICE CREATED =====")
        
        // Acquire wake lock to keep device awake in deep sleep
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "Fylgja::ConnectivityMonitor"
        )
        wakeLock?.acquire(10 * 60 * 1000L) // 10 minutes
        Log.d(TAG, "Wake lock acquired")
        
        // Get connectivity manager
        connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        
        // Create foreground notification channel
        createNotificationChannel()
        
        // Start as foreground service
        startForeground(NOTIFICATION_ID, createNotification())
        
        Log.d(TAG, "Service started as foreground service")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand called")
        
        when (intent?.action) {
            ACTION_START_MONITORING -> {
                Log.d(TAG, "Starting monitoring...")
                startMonitoring()
            }
            ACTION_STOP_MONITORING -> {
                Log.d(TAG, "Stopping monitoring...")
                stopMonitoring()
                stopSelf()
            }
        }
        
        return START_STICKY // Restart if killed
    }
    
    private fun startMonitoring() {
        if (isMonitoring) {
            Log.d(TAG, "Already monitoring")
            return
        }
        
        isMonitoring = true
        Log.d(TAG, "===== STARTING CONNECTIVITY MONITORING =====")
        Log.d(TAG, "Service is in FOREGROUND with WAKE LOCK - works in deep sleep!")
        Log.d(TAG, "Will detect connectivity even when phone is folded/closed")
        
        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .addCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
            .build()
        
        connectivityCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                Log.d(TAG, "===== NETWORK AVAILABLE =====")
                Log.d(TAG, "Network: $network")
                
                // Check if we have internet
                val capabilities = connectivityManager?.getNetworkCapabilities(network)
                val hasInternet = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
                
                Log.d(TAG, "Has internet: $hasInternet")
                
                if (hasInternet) {
                    Log.d(TAG, "===== CONNECTIVITY DETECTED - TRIGGERING ALERT =====")
                    triggerAlert()
                }
            }
            
            override fun onLost(network: Network) {
                Log.d(TAG, "Network lost: $network")
            }
            
            override fun onCapabilitiesChanged(
                network: Network,
                networkCapabilities: NetworkCapabilities
            ) {
                Log.d(TAG, "Capabilities changed: $networkCapabilities")
                
                if (networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) {
                    val hasValidated = networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
                    if (hasValidated) {
                        Log.d(TAG, "===== VALIDATED CONNECTIVITY DETECTED =====")
                        triggerAlert()
                    }
                }
            }
        }
        
        connectivityManager?.registerNetworkCallback(request, connectivityCallback!!)
        Log.d(TAG, "Network callback registered")
    }
    
    private fun stopMonitoring() {
        isMonitoring = false
        Log.d(TAG, "Stopping monitoring...")
        
        connectivityCallback?.let {
            connectivityManager?.unregisterNetworkCallback(it)
            Log.d(TAG, "Network callback unregistered")
        }
        
        connectivityCallback = null
    }
    
    private fun triggerAlert() {
        Log.d(TAG, "===== TRIGGERING NATIVE ALERT =====")
        
        // CRITICAL: Stop monitoring immediately to prevent multiple alerts
        stopMonitoring()
        
        // Trigger the existing NotificationHelper
        NotificationHelper(this).showCoverageNotification()
        
        // CRITICAL: Send broadcast to Flutter so UI knows coverage was found
        val intent = Intent("no.fylgja.app.COVERAGE_FOUND")
        intent.putExtra("timestamp", System.currentTimeMillis())
        sendBroadcast(intent)
        Log.d(TAG, "Broadcast sent to Flutter: coverage found")
        
        Log.d(TAG, "Alert triggered")
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Connectivity Monitoring",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors network connectivity"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created")
        }
    }
    
    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Fylgja ser etter dekning")
            .setContentText("Appen kjører i bakgrunnen og overvåker nettverksdekning")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        Log.d(TAG, "===== SERVICE DESTROYED =====")
        stopMonitoring()
        wakeLock?.release()
        super.onDestroy()
    }
    
    companion object {
        private const val CHANNEL_ID = "connectivity_monitoring_channel"
        private const val NOTIFICATION_ID = 889
        
        const val ACTION_START_MONITORING = "no.fylgja.app.START_MONITORING"
        const val ACTION_STOP_MONITORING = "no.fylgja.app.STOP_MONITORING"
        
        fun startService(context: Context) {
            val intent = Intent(context, ConnectivityMonitoringService::class.java).apply {
                action = ACTION_START_MONITORING
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            
            Log.d("ConnectivityMonitor", "Service start requested")
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, ConnectivityMonitoringService::class.java).apply {
                action = ACTION_STOP_MONITORING
            }
            context.stopService(intent)
            
            Log.d("ConnectivityMonitor", "Service stop requested")
        }
    }
}

