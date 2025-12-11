# Google Sign-In Setup Fix

## Error: `com.google.android.gms.common.api.ApiException: 10`

This error means Google Sign-In is not properly configured. Follow these steps:

## Step 1: Get SHA-1 Fingerprint

### For Debug Build (Development):

Open PowerShell in your project root and run:

```powershell
cd android
./gradlew signingReport
```

Look for the **debug** section and copy the **SHA-1** fingerprint. It will look like:
```
SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:00:AA:BB:CC:DD
```

### Alternative Method (if gradlew doesn't work):

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Copy the **SHA-1** value.

## Step 2: Configure Firebase/Google Cloud Console

### Option A: Using Firebase (Recommended)

1. Go to https://console.firebase.google.com/
2. Create a new project or select existing one
3. Click **Add app** → Select **Android**
4. Enter package name: `fyp.main.kd_dev`
5. Download `google-services.json`
6. Place it in `android/app/` folder
7. Go to **Authentication** → **Sign-in method**
8. Enable **Google** sign-in
9. Go to **Project Settings** → **Your apps** → **Android app**
10. Add SHA-1 fingerprint from Step 1
11. Click **Save**

### Option B: Using Google Cloud Console

1. Go to https://console.cloud.google.com/
2. Select your project or create new one
3. Go to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth 2.0 Client ID**
5. Select **Android**
6. Enter:
   - Name: `Kinder Pal Android`
   - Package name: `fyp.main.kd_dev`
   - SHA-1 fingerprint: (paste from Step 1)
7. Click **Create**
8. Copy the **Client ID** (optional, not needed for mobile)

## Step 3: Update Android Configuration (If Using Firebase)

Add to `android/build.gradle.kts` (at the top):

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

Add to `android/app/build.gradle.kts` (at the bottom):

```kotlin
apply(plugin = "com.google.gms.google-services")
```

## Step 4: Verify google-services.json

Make sure `android/app/google-services.json` exists and contains:

```json
{
  "project_info": {
    "project_number": "YOUR_PROJECT_NUMBER",
    "project_id": "YOUR_PROJECT_ID"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "...",
        "android_client_info": {
          "package_name": "fyp.main.kd_dev"
        }
      },
      "oauth_client": [
        {
          "client_id": "...",
          "client_type": 1,
          "android_info": {
            "package_name": "fyp.main.kd_dev",
            "certificate_hash": "YOUR_SHA1_HERE"
          }
        }
      ]
    }
  ]
}
```

## Step 5: Rebuild the App

```powershell
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

## Email Verification Deep Link Fix

The email verification redirect is now properly configured. The "untitled" issue happens because the deep link opens but isn't handled.

### What I Fixed:

1. **Updated MainActivity.kt** to handle deep link intents
2. **Updated SupabaseService** to listen for auth state changes
3. **Updated EmailVerificationScreen** to auto-navigate on success

### Testing:

1. Sign up with new email
2. Check email and click verification link
3. App should open and navigate to YouTube API setup
4. If it shows "untitled", the app will still authenticate in background
5. Close and reopen app - you should be logged in

## Alternative: Skip Google Sign-In for Now

If you want to test other features first, you can:

1. Comment out Google Sign-in button in `login_screen.dart`
2. Use email/password sign-in instead
3. Set up Google Sign-in later when ready

## Troubleshooting

### Google Sign-In Still Fails:
- ✅ Verify SHA-1 is added to Firebase/Google Cloud
- ✅ Check package name is exactly: `fyp.main.kd_dev`
- ✅ Make sure `google-services.json` is in `android/app/`
- ✅ Rebuild app after adding google-services.json
- ✅ Try uninstalling and reinstalling the app

### Email Link Shows "Untitled":
- ✅ This is normal - the app is processing the deep link
- ✅ Wait 2-3 seconds, then close the browser tab
- ✅ Open your app manually - you should be logged in
- ✅ Check app logs for "User signed in via deep link"

### Email Link Still Goes to Browser:
- ✅ Make sure you set redirect URL in Supabase dashboard: `io.supabase.kinderpal://login-callback/`
- ✅ Rebuild app after AndroidManifest changes
- ✅ Uninstall and reinstall app

## Quick Test Commands

```powershell
# Get SHA-1
cd android
./gradlew signingReport

# Clean and rebuild
cd ..
flutter clean
flutter pub get
flutter run

# Check if deep link is registered
adb shell dumpsys package fyp.main.kd_dev | findstr "scheme"
```

The deep link should show:
```
io.supabase.kinderpal://login-callback/
```
