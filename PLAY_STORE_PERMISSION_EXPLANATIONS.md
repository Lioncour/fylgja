# Google Play Console - Permission Explanations

## FOREGROUND_SERVICE_DATA_SYNC

**Why does your app need this permission?**

Fylgja requires the FOREGROUND_SERVICE_DATA_SYNC permission to continuously monitor network connectivity in the background. This is the core functionality of the app - detecting when mobile network or Wi-Fi coverage becomes available.

**How does your app use this permission?**

The app runs a foreground service that:
- Monitors network connectivity status every 2-3 seconds
- Detects when network coverage is found (mobile data or Wi-Fi)
- Alerts users with vibration and sound when coverage is detected
- Works reliably even when the phone is in standby/Doze mode

**Why is this permission essential for your app's functionality?**

Fylgja is designed for outdoor activities (hiking, skiing, etc.) where users need to know when they regain network coverage. The app must:
- Continue monitoring in the background while the phone screen is off
- Work reliably in standby mode and Doze Mode
- Provide immediate alerts when coverage is found

Without this permission, the app cannot function as intended - users would need to keep the app open and screen on, which defeats the purpose of the app.

**User benefit:**

Users can start a search, put their phone away, and receive alerts when network coverage is found, even if the phone is in standby mode. This is critical for safety in outdoor situations.

---

## Alternative Shorter Version (if character limit):

**FOREGROUND_SERVICE_DATA_SYNC is required for the app's core functionality: continuously monitoring network connectivity in the background to detect when mobile or Wi-Fi coverage becomes available. The app runs a foreground service that checks connectivity every 2-3 seconds and alerts users with vibration and sound when coverage is found. This must work reliably even when the phone is in standby mode, which is essential for outdoor activities where users need to know when they regain network coverage.**

---

## Other Permissions You May Need to Explain:

### FOREGROUND_SERVICE_MEDIA_PLAYBACK
**Why:** To play notification sounds continuously when network coverage is found, alerting users even when the phone is in standby mode.

### REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
**Why:** To ensure the connectivity monitoring service continues working reliably in Doze Mode and App Standby, which is essential for the app's core functionality of detecting coverage in background.

### SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM
**Why:** For precise timing of connectivity checks to ensure reliable detection of network coverage changes, especially important when the phone is in standby mode.

### ACCESS_NETWORK_STATE / ACCESS_WIFI_STATE
**Why:** Core functionality - the app monitors network connectivity to detect when coverage becomes available. This is the primary purpose of the app.

### VIBRATE
**Why:** To provide haptic feedback alerts when network coverage is found, ensuring users are notified even when the phone is in their pocket or bag.

### WAKE_LOCK
**Why:** To keep the CPU active enough to perform connectivity checks in background, ensuring the monitoring service works reliably in standby mode.

### POST_NOTIFICATIONS
**Why:** To show persistent notifications indicating the app is monitoring for coverage, and to alert users when coverage is found.

### USE_FULL_SCREEN_INTENT
**Why:** To display full-screen alerts when coverage is found, ensuring users are immediately notified even when the phone is locked.
