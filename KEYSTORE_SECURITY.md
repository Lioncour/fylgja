# Keystore Security Guide

## What is a Keystore?

A **keystore** is a secure file that contains cryptographic keys used to digitally sign your Android app. Think of it like a digital signature that proves:
- The app was created by you
- The app hasn't been tampered with
- Updates come from the same developer

## Why is it Critical?

**Google Play Store requires apps to be signed with a keystore.** This is how Google ensures:
1. **App Authenticity**: Only you can publish updates to your app
2. **Security**: Prevents malicious apps from impersonating your app
3. **User Trust**: Users know updates are from the legitimate developer

## What Must Stay Secret?

### 🔴 NEVER Share or Commit These Files:

1. **`android/keystore.jks`** - The keystore file itself
   - Contains your private signing key
   - If someone gets this + password, they can sign apps as you

2. **`android/key.properties`** - Contains keystore passwords
   - Contains: `storePassword`, `keyPassword`, `keyAlias`
   - If exposed, attackers can use your keystore

### ✅ Safe to Share:

- `android/key.properties.template` - Template file (no passwords)
- `android/generate_keystore.*` - Helper scripts (no secrets)

## Current Security Status

✅ **Your keystore files are protected:**
- Both files are in `.gitignore` (lines 115-118)
- They will NOT be committed to git
- They will NOT be pushed to GitHub

## What Happens If You Lose the Keystore?

**⚠️ CRITICAL:** If you lose your keystore file or forget the password:

1. **You CANNOT update your app on Google Play Store**
   - Google requires the SAME keystore for all updates
   - You cannot create a new keystore for the same app

2. **Your only options:**
   - Create a completely new app (new package name)
   - Lose all existing users and reviews
   - Start from scratch

## What Happens If Someone Steals Your Keystore?

If someone gets your keystore file + password:

1. **They can publish malicious updates** to your app
2. **They can impersonate your app** on other platforms
3. **Your users could be at risk**

## Security Best Practices

### ✅ DO:

1. **Backup the keystore securely:**
   - Store `keystore.jks` in a secure location (encrypted USB, password manager, secure cloud storage)
   - Keep multiple backups in different locations
   - Document the password securely (password manager)

2. **Use strong passwords:**
   - Current password: `fylgja2024` (consider changing to something stronger)
   - Use a password manager to store it

3. **Limit access:**
   - Only people who need to publish updates should have access
   - Don't share the keystore file or passwords

4. **Verify git exclusion:**
   ```bash
   git status  # Should NOT show keystore.jks or key.properties
   ```

### ❌ DON'T:

1. **Never commit to git:**
   - Don't add `keystore.jks` or `key.properties` to git
   - Don't push them to GitHub/GitLab/etc.

2. **Never share publicly:**
   - Don't upload to public repositories
   - Don't share in chat/email (unless encrypted)
   - Don't store in unencrypted cloud storage

3. **Never lose it:**
   - Make secure backups immediately
   - Store password in a password manager

## Current Keystore Information

- **Location:** `android/keystore.jks`
- **Password:** `fylgja2024` (stored in `android/key.properties`)
- **Alias:** `upload`
- **Validity:** 10,000 days (~27 years)
- **Status:** ✅ Protected by `.gitignore`

## Verification Commands

Check if keystore files are being tracked by git:
```bash
git ls-files | grep -E "keystore|key.properties"
# Should return nothing if properly ignored
```

Check git status:
```bash
git status
# Should NOT show keystore.jks or key.properties
```

## Summary

**Your keystore is like the master key to your app's identity on Google Play Store.**
- ✅ Currently protected (in `.gitignore`)
- ✅ Safe from accidental git commits
- ⚠️ Make secure backups NOW
- ⚠️ Store password securely
- ⚠️ Never share or commit these files

**If you lose it, you lose the ability to update your app forever!**
