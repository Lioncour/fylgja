# How to Upload Fylgja to Google Play Store

## Quick Answer

**You upload from your local computer, NOT from git.**

The process is:
1. Build the release AAB file locally (on your computer)
2. Upload the AAB file through Google Play Console (web browser)
3. Git is only for code version control - you don't upload from git

## Step-by-Step Upload Process

### Step 1: Build Release AAB File (Local)

On your computer, run:

```bash
flutter build appbundle --release
```

This creates: `build/app/outputs/bundle/release/app-release.aab`

**Important:** This uses your local keystore (`android/keystore.jks`) to sign the app.

### Step 2: Upload to Google Play Console (Web Browser)

1. Go to [Google Play Console](https://play.google.com/console)
2. Sign in with your Google Play Developer account
3. Select your app (or create new app)
4. Go to **Production** → **Create new release**
5. Upload the AAB file: `build/app/outputs/bundle/release/app-release.aab`
6. Fill in release notes
7. Review and publish

## Why NOT from Git?

**Git is for code, not for app distribution:**
- Git stores your source code
- Keystore files are NOT in git (they're in `.gitignore`)
- Google Play Console needs the signed AAB file, which must be built locally with your keystore
- You cannot build or sign apps directly from git

## What About CI/CD?

If you want to automate this in the future, you could:
- Use GitHub Actions or similar CI/CD
- Store keystore securely in CI/CD secrets
- Automatically build and upload on git push

But for now, **upload manually from your local computer**.

## Current Setup Status

✅ **Ready to upload:**
- Keystore created: `android/keystore.jks`
- Keystore configured: `android/key.properties`
- Build system ready
- All Play Store requirements fixed

## Upload Checklist

Before uploading, make sure you have:

- [ ] Google Play Developer account ($25 one-time fee)
- [ ] App created in Play Console
- [ ] Privacy policy URL added: https://janandersekroll.no/privacy
- [ ] Release AAB built: `flutter build appbundle --release`
- [ ] Store listing prepared (description, screenshots, etc.)
- [ ] Content rating completed

## Build Commands

**For testing (APK):**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**For Play Store (AAB):**
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

## Summary

- ✅ Build locally on your computer
- ✅ Upload AAB file through Play Console website
- ❌ Don't upload from git (keystore not in git anyway)
- ✅ Git is just for code version control

The keystore must stay on your local machine to sign the app!
