# Email Verification Fix - Supabase Configuration

## The Problem
Email verification links were redirecting to `localhost:3000` instead of your Flutter app, causing "OTP expired" errors.

## What I Fixed in the Code

### 1. Updated Auth Service (`lib/services/auth_service.dart`)
- Added `emailRedirectTo` parameter to signup and resend email functions
- Redirect URL: `io.supabase.kinderpal://login-callback/`

### 2. Updated Android Manifest (`android/app/src/main/AndroidManifest.xml`)
- Added deep link intent filter for email verification
- Added INTERNET permission
- Configured scheme: `io.supabase.kinderpal`
- Configured host: `login-callback`

### 3. Updated Email Verification Screen
- Added deep link listener to automatically detect when user clicks email link
- Auto-navigates to YouTube API setup when verified

## REQUIRED: Supabase Dashboard Configuration

⚠️ **IMPORTANT**: You MUST configure these settings in your Supabase dashboard for email verification to work!

### Step 1: Configure Redirect URLs

1. Go to https://supabase.com/dashboard
2. Select your project: `qtuutontplzkqnsldmav`
3. Go to **Authentication** → **URL Configuration**
4. Add these URLs to **Redirect URLs**:

```
io.supabase.kinderpal://login-callback/
io.supabase.kinderpal://**
```

5. Click **Save**

### Step 2: Configure Email Templates (Optional but Recommended)

1. Go to **Authentication** → **Email Templates**
2. Select **Confirm signup** template
3. Make sure the confirmation link uses the redirect URL
4. The default template should work, but verify it contains:
```
{{ .ConfirmationURL }}
```

### Step 3: Disable Email Confirmations for Testing (Optional)

If you want to test without email verification temporarily:

1. Go to **Authentication** → **Providers** → **Email**
2. Uncheck **"Confirm email"**
3. Click **Save**

⚠️ **Remember to re-enable this for production!**

## Testing the Fix

### Test 1: New Signup
1. Clear app data or uninstall/reinstall app
2. Sign up with a new email
3. Check email inbox
4. Click the verification link
5. Should open the app and navigate to YouTube API setup

### Test 2: Resend Email
1. On email verification screen, click "Resend Verification Email"
2. Check email inbox (also check spam folder)
3. Click the new verification link
4. Should open the app

## Troubleshooting

### Email Not Received
- **Check Spam Folder**: Supabase emails often go to spam
- **Check Supabase Logs**: Go to Authentication → Logs to see if email was sent
- **Rate Limiting**: Supabase limits emails to 3-4 per hour per email address
- **Wait 5-10 minutes**: Sometimes there's a delay

### Email Link Still Goes to localhost
- **Clear browser cache**: If testing in browser
- **Verify Redirect URLs**: Make sure you added them in Supabase dashboard
- **Wait for changes to propagate**: Supabase changes can take 1-2 minutes

### App Doesn't Open from Email Link
- **Android Only**: Make sure you're testing on Android device/emulator
- **Reinstall App**: After changing AndroidManifest.xml
- **Check Intent Filter**: Verify the deep link is registered in AndroidManifest.xml

### "OTP Expired" Error
- **Links expire in 1 hour**: Request a new verification email
- **Each link can only be used once**: Don't click the same link twice
- **Clear old sessions**: Sign out and try again

## For iOS (Future)

If you need iOS support, add this to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>io.supabase.kinderpal</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.kinderpal</string>
        </array>
    </dict>
</array>
<key>FlutterDeepLinkingEnabled</key>
<true/>
```

## Alternative: Skip Email Verification

If you want to skip email verification entirely for development:

### Option 1: Disable in Supabase
1. Go to Authentication → Providers → Email
2. Uncheck "Confirm email"
3. Update code to skip verification screen

### Option 2: Auto-confirm in Code
Update the signup flow to navigate directly to YouTube API setup instead of verification screen.

## Summary

**What You Need to Do:**
1. ✅ Go to Supabase Dashboard
2. ✅ Add redirect URLs: `io.supabase.kinderpal://login-callback/`
3. ✅ Save changes
4. ✅ Rebuild the Flutter app: `flutter clean && flutter run`
5. ✅ Test signup with a new email

The code changes are complete. You just need to configure the Supabase dashboard redirect URLs!
