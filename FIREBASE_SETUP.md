# Firebase Setup Guide for Neki App

## Overview
This guide walks you through setting up Firebase Authentication with Email/Password, Google Sign-In, and Facebook Login for the Neki App.

## Prerequisites
- Firebase account (https://console.firebase.google.com)
- Google Cloud Console access (for Google Sign-In)
- Facebook Developer account (for Facebook Login)

---

## Part 1: Firebase Project Setup

### 1.1 Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click "Add project" or "Create a project"
3. Enter project name: `neki-tracker` (or your choice)
4. (Optional) Enable Google Analytics
5. Click "Create project"

### 1.2 Enable Authentication Methods
1. In Firebase Console, go to **Build > Authentication**
2. Click "Get started"
3. Go to **Sign-in method** tab
4. Enable the following providers:
   - **Email/Password**: Click, toggle "Enable", Save
   - **Google**: Click, toggle "Enable", Save (we'll configure OAuth later)
   - **Facebook**: Click, toggle "Enable" (we'll add App ID/Secret later)
   - **Apple**: Click, toggle "Enable" (iOS only - see APPLE_SIGNIN_SETUP.md for detailed configuration)

---

## Part 2: Android Configuration

### 2.1 Register Android App in Firebase
1. In Firebase Console, click the **Android icon** (gear/settings icon in project overview)
2. Enter Android package name: 
   - Open `/android/app/src/main/AndroidManifest.xml`
   - Find `package="com.example.neki_app"` (or similar)
   - Use this exact package name
3. (Optional) Enter app nickname: "Neki App Android"
4. (Optional) Debug signing certificate SHA-1:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Copy the SHA-1 from the debug variant (needed for Google Sign-In)
5. Click "Register app"

### 2.2 Download google-services.json
1. Download the `google-services.json` file
2. Move it to: `/android/app/google-services.json`

### 2.3 Update Android Gradle Files

**File: `/android/build.gradle` (or `build.gradle.kts`)**

If using Groovy (`build.gradle`):
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

If using Kotlin DSL (`build.gradle.kts`):
```kotlin
buildscript {
    dependencies {
        // Add this line
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

**File: `/android/app/build.gradle` (or `build.gradle.kts`)**

At the **bottom** of the file, add:
```gradle
// For Groovy
apply plugin: 'com.google.gms.google-services'

// OR for Kotlin DSL
plugins {
    id("com.google.gms.google-services")
}
```

---

## Part 3: iOS Configuration

### 3.1 Register iOS App in Firebase
1. In Firebase Console, click the **iOS icon** (⊕ Add app)
2. Enter iOS bundle ID:
   - Open `/ios/Runner.xcworkspace` in Xcode
   - Select "Runner" project → "Runner" target
   - Look for "Bundle Identifier" (e.g., `com.example.nekiApp`)
   - Use this exact bundle ID
3. (Optional) Enter app nickname: "Neki App iOS"
4. Click "Register app"

### 3.2 Download GoogleService-Info.plist
1. Download the `GoogleService-Info.plist` file
2. Open `/ios/Runner.xcworkspace` in Xcode
3. Right-click on "Runner" folder → "Add Files to Runner"
4. Select `GoogleService-Info.plist`
5. ✅ Ensure "Copy items if needed" is checked
6. ✅ Ensure "Runner" target is selected
7. Click "Add"

### 3.3 Install CocoaPods Dependencies
```bash
cd ios
pod install
cd ..
```

---

## Part 4: Google Sign-In Configuration

### 4.1 Get OAuth Client IDs

**For Android:**
1. The Android OAuth client is auto-created when you add SHA-1 to Firebase
2. Verify in Firebase Console → Settings → General → Your apps → Android app
3. You should see "Web SDK configuration" with a Web client ID

**For iOS:**
1. Go to https://console.cloud.google.com
2. Select your Firebase project
3. Go to **APIs & Services > Credentials**
4. You should see an iOS OAuth client created by Firebase
5. Note the **iOS URL scheme** (format: `com.googleusercontent.apps.REVERSED_CLIENT_ID`)

### 4.2 Configure iOS URL Scheme
1. Open `/ios/Runner/Info.plist` in a text editor
2. Add this before the closing `</dict>` tag:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Replace with your REVERSED_CLIENT_ID from GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

3. Find your `REVERSED_CLIENT_ID` in `GoogleService-Info.plist`:
   - Open `ios/Runner/GoogleService-Info.plist`
   - Look for `<key>REVERSED_CLIENT_ID</key>`
   - Copy the `<string>` value below it
   - Replace `YOUR_REVERSED_CLIENT_ID` in Info.plist

---

## Part 5: Facebook Login Configuration

### 5.1 Create Facebook App
1. Go to https://developers.facebook.com
2. Click "My Apps" → "Create App"
3. Choose "Consumer" use case
4. Enter app name: "Neki Tracker"
5. Enter contact email
6. Click "Create App"

### 5.2 Configure Facebook Login
1. In Facebook App Dashboard, click "Add Product"
2. Find "Facebook Login" and click "Set Up"
3. Choose platform:
   - **iOS**: Enter iOS Bundle ID (same as Firebase iOS bundle)
   - **Android**: Enter Android Package Name (same as Firebase Android package)

### 5.3 Get Facebook App ID and Secret
1. In Facebook App Dashboard, go to **Settings > Basic**
2. Copy **App ID** and **App Secret**

### 5.4 Add Facebook to Firebase
1. Go back to Firebase Console → Authentication → Sign-in method → Facebook
2. Paste **App ID** and **App Secret**
3. Copy the **OAuth redirect URI** shown in Firebase
4. Go back to Facebook Developer Console
5. Navigate to **Facebook Login > Settings**
6. Paste the Firebase OAuth redirect URI into "Valid OAuth Redirect URIs"
7. Click "Save Changes"

### 5.5 Configure Android for Facebook

**File: `/android/app/src/main/res/values/strings.xml`**

Create this file if it doesn't exist:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Neki Tracker</string>
    <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
    <string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
    <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
</resources>
```

Replace `YOUR_FACEBOOK_APP_ID` and `YOUR_FACEBOOK_CLIENT_TOKEN` with values from Facebook Developer Console.

**File: `/android/app/src/main/AndroidManifest.xml`**

Add inside `<application>` tag:
```xml
<meta-data
    android:name="com.facebook.sdk.ApplicationId"
    android:value="@string/facebook_app_id"/>

<meta-data
    android:name="com.facebook.sdk.ClientToken"
    android:value="@string/facebook_client_token"/>

<activity
    android:name="com.facebook.FacebookActivity"
    android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
    android:label="@string/app_name" />

<activity
    android:name="com.facebook.CustomTabActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="@string/fb_login_protocol_scheme" />
    </intent-filter>
</activity>
```

### 5.6 Configure iOS for Facebook

**File: `/ios/Runner/Info.plist`**

Add this before the closing `</dict>` tag:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fbYOUR_FACEBOOK_APP_ID</string>
        </array>
    </dict>
</array>

<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID</string>

<key>FacebookClientToken</key>
<string>YOUR_FACEBOOK_CLIENT_TOKEN</string>

<key>FacebookDisplayName</key>
<string>Neki Tracker</string>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>fbapi</string>
    <string>fb-messenger-share-api</string>
    <string>fbauth2</string>
    <string>fbshareextension</string>
</array>
```

---

## Part 6: Testing

### 6.1 Clean and Build
```bash
flutter clean
flutter pub get
```

### 6.2 Run on Device
```bash
# For Android
flutter run -d <android-device-id>

# For iOS
flutter run -d <ios-device-id>
```

### 6.3 Test Authentication
1. **Email/Password**: Register a new account or sign in with existing credentials
2. **Google Sign-In**: Tap Google sign-in button, select account
3. **Facebook Login**: Tap Facebook login button, authorize app

---

## Troubleshooting

### Android Issues
- **SHA-1 Error**: Run `cd android && ./gradlew signingReport` and add SHA-1 to Firebase
- **Google Services Plugin Error**: Ensure `google-services.json` is in `android/app/`
- **Package Name Mismatch**: Verify package name matches across Firebase, AndroidManifest.xml

### iOS Issues
- **URL Scheme Error**: Double-check `REVERSED_CLIENT_ID` in Info.plist
- **CocoaPods Error**: Run `cd ios && pod deintegrate && pod install`
- **Bundle ID Mismatch**: Verify bundle ID matches between Firebase and Xcode

### Google Sign-In Issues
- **DEVELOPER_ERROR**: Missing or incorrect SHA-1 certificate (Android)
- **No valid OAuth client**: Verify OAuth client exists in Google Cloud Console
- **URL scheme not registered**: Check Info.plist URL schemes (iOS)

### Facebook Login Issues
- **Invalid OAuth Redirect URI**: Verify redirect URI is added to Facebook App Settings
- **App not in development mode**: Set Facebook App to "Live" mode or add test users
- **Package name/Bundle ID mismatch**: Ensure they match in Facebook Developer Console

---

## Summary Checklist

- [ ] Firebase project created
- [ ] Email/Password, Google, Facebook enabled in Firebase Authentication
- [ ] Android app registered, `google-services.json` downloaded and placed
- [ ] iOS app registered, `GoogleService-Info.plist` downloaded and added to Xcode
- [ ] Android Gradle files updated with Google Services plugin
- [ ] iOS CocoaPods installed
- [ ] Google Sign-In: SHA-1 added (Android), URL scheme configured (iOS)
- [ ] Facebook App created and configured
- [ ] Facebook App ID/Secret added to Firebase
- [ ] Facebook redirect URI added to Facebook Developer Console
- [ ] Android: `strings.xml` and `AndroidManifest.xml` updated for Facebook
- [ ] iOS: `Info.plist` updated for Facebook
- [ ] App built and tested on device

---

## Next Steps

After completing this setup:
1. Update UI to add Google and Facebook sign-in buttons
2. Wire buttons to call `authRepository.signInWithGoogle()` and `authRepository.signInWithFacebook()`
3. Test all three authentication methods
4. Add error handling and loading states
