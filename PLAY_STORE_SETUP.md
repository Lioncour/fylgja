# Google Play Store Release Setup

This document outlines the steps needed to prepare the app for Google Play Store release.

## ✅ Completed Fixes

1. **Removed unnecessary permissions:**
   - Removed `RECORD_AUDIO` (app doesn't record audio, only plays sounds)
   - Removed `WRITE_EXTERNAL_STORAGE` (deprecated and not needed)

2. **Fixed app name:**
   - Changed from "fylgja" to "Fylgja" (capital F)

3. **Release signing configuration:**
   - Updated `build.gradle` to support release signing
   - Created `key.properties.template` for keystore configuration

## 🔧 Required Steps Before Publishing

### 1. Generate Release Keystore

Run this command in the project root to generate a keystore:

```bash
keytool -genkey -v -keystore android/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You'll be prompted for:
- Keystore password (remember this!)
- Key password (can be same as keystore password)
- Your name and organization details

**IMPORTANT:** Keep the keystore file and passwords safe! You'll need them for all future updates.

### 2. Create key.properties File

1. Copy the template:
   ```bash
   cp android/key.properties.template android/key.properties
   ```

2. Edit `android/key.properties` and fill in your keystore details:
   ```
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=../keystore.jks
   ```

### 3. Build Release APK/AAB

For Google Play Store, you should upload an AAB (Android App Bundle):

```bash
flutter build appbundle --release
```

The AAB will be located at: `build/app/outputs/bundle/release/app-release.aab`

### 4. Test Release Build

Before uploading, test the release build:

```bash
flutter build apk --release
flutter install --release
```

### 5. Google Play Console Setup

1. **App Information:**
   - App name: "Fylgja" ✅
   - Package name: `no.fylgja.app` ✅

2. **Privacy Policy:**
   - Privacy Policy URL: https://janandersekroll.no/privacy ✅

3. **Content Rating:**
   - Complete the content rating questionnaire

4. **Store Listing:**
   - App description
   - Screenshots (required)
   - Feature graphic
   - App icon (already configured)

5. **Permissions Declaration:**
   - Declare why you need each permission:
     - `VIBRATE`: For notification alerts when coverage is found
     - `WAKE_LOCK`: To keep app running in background/standby mode
     - `FOREGROUND_SERVICE`: For continuous connectivity monitoring
     - `POST_NOTIFICATIONS`: For coverage alerts
     - `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`: To ensure app works in standby mode
     - `SCHEDULE_EXACT_ALARM`: For precise timing of connectivity checks
     - `ACCESS_NETWORK_STATE` / `ACCESS_WIFI_STATE`: Core functionality for detecting coverage

## 📋 Pre-Upload Checklist

- [ ] Keystore generated and `key.properties` configured
- [ ] Release AAB built successfully
- [ ] Release build tested on device
- [ ] Privacy policy URL added to Play Console
- [ ] App screenshots prepared
- [ ] Store listing description written
- [ ] Content rating completed
- [ ] Permissions declared with justifications

## 🔒 Security Notes

- **NEVER** commit `key.properties` or `keystore.jks` to version control
- These files are already in `.gitignore`
- Store keystore backup in a secure location
- You'll need the same keystore for all future app updates

## 📱 Version Information

Current version: `1.0.24+81`
- Version name: `1.0.24`
- Version code: `81`

To update version, edit `pubspec.yaml`:
```yaml
version: 1.0.24+81  # Format: versionName+versionCode
```
