# Apple Sign-In Configuration Guide

## Overview
This guide explains how to configure Sign in with Apple for the Neki App on iOS.

## Prerequisites
- Apple Developer Account (https://developer.apple.com)
- Firebase project already configured
- Xcode installed on macOS

---

## Part 1: Apple Developer Configuration

### 1.1 Enable Sign in with Apple Capability
1. Open `/ios/Runner.xcworkspace` in Xcode
2. Select the "Runner" project in the navigator
3. Select the "Runner" target
4. Go to "Signing & Capabilities" tab
5. Click "+ Capability" button
6. Search for "Sign in with Apple"
7. Add the capability

### 1.2 Register App ID with Sign in with Apple
1. Go to https://developer.apple.com/account
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click on **Identifiers**
4. Find your app's identifier (e.g., `com.example.nekiApp`)
5. Edit the identifier
6. Check "Sign in with Apple"
7. Click "Edit" next to Sign in with Apple
8. Choose "Enable as a primary App ID"
9. Click "Save"
10. Click "Continue" and "Save"

### 1.3 Create Service ID (for OAuth)
1. In **Identifiers**, click the "+" button
2. Select "Services IDs" and click "Continue"
3. Enter a description: "Neki App Sign in with Apple"
4. Enter an identifier: `com.example.nekiApp.signin` (must be different from app identifier)
5. Click "Continue" and "Register"
6. Select your new Service ID from the list
7. Check "Sign in with Apple"
8. Click "Configure" next to Sign in with Apple
9. **Primary App ID**: Select your app's identifier
10. **Domains and Subdomains**: Add `nekiapp-52446.firebaseapp.com`
11. **Return URLs**: Add `https://nekiapp-52446.firebaseapp.com/__/auth/handler`
    - Replace `nekiapp-52446` with your actual Firebase project ID
12. Click "Save" then "Continue" then "Save"

---

## Part 2: Firebase Configuration

### 2.1 Enable Apple Sign-In Provider
1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project (`nekiapp-52446`)
3. Go to **Authentication > Sign-in method**
4. Click on **Apple** provider
5. Click "Enable"
6. **OAuth code flow configuration** (for web/Android if needed):
   - Service ID: `com.example.nekiApp.signin` (from step 1.3)
   - Apple Team ID: Found in Apple Developer Account (top right corner)
   - Key ID: (You'll create this in next step)
   - Private key: (You'll create this in next step)
7. Click "Save"

### 2.2 Create Authentication Key (Optional - for web support)
1. Go to Apple Developer Account > **Certificates, Identifiers & Profiles**
2. Click on **Keys** in the sidebar
3. Click the "+" button
4. Enter key name: "Neki App Sign in with Apple Key"
5. Check "Sign in with Apple"
6. Click "Configure" next to Sign in with Apple
7. Select your primary App ID
8. Click "Save"
9. Click "Continue" then "Register"
10. **Download the .p8 file** (you can only download once!)
11. Note the **Key ID** (10 characters, e.g., `ABC123DEFG`)
12. Note your **Team ID** (found in top right of Apple Developer portal)

### 2.3 Upload Key to Firebase (Optional - for web support)
1. Back in Firebase Console > Authentication > Apple provider
2. Enter the **Key ID** from step 2.2
3. Upload or paste the contents of the .p8 file
4. Enter your **Apple Team ID**
5. Click "Save"

---

## Part 3: iOS App Configuration

### 3.1 Update Info.plist (Already configured by `sign_in_with_apple` package)
The `sign_in_with_apple` package automatically handles the necessary Info.plist configurations.

### 3.2 Update Entitlements
1. In Xcode, select "Runner" project
2. Open `Runner/Runner.entitlements` file
3. Verify it contains:
```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

If the file doesn't exist, Xcode should have created it when you added the capability in step 1.1.

---

## Part 4: Testing

### 4.1 Test on Simulator
1. Ensure you're signed in with an Apple ID in Simulator:
   - Open Simulator > Settings > Sign in with Apple ID
2. Run the app:
   ```bash
   flutter run -d <ios-simulator-id>
   ```
3. Tap "Continue with Apple"
4. Authenticate with Face ID/Touch ID (or use Simulator menu > Features > Face ID > Enrolled)
5. Choose to share or hide your email
6. Complete sign-in

### 4.2 Test on Physical Device
1. Connect iOS device
2. Ensure device is signed in to iCloud (Settings > Apple ID)
3. Run the app:
   ```bash
   flutter run -d <ios-device-id>
   ```
4. Test Apple Sign-In flow

---

## Part 5: Production Considerations

### 5.1 Handle Email Privacy
Apple allows users to hide their email. Your app should handle this case:
- User can provide a relay email: `privaterelay@icloud.com`
- Your app receives: `randomstring@privaterelay.appleid.com`
- This is a valid email that forwards to the user's real email

### 5.2 User Info on First Sign-In Only
Apple provides `givenName` and `familyName` **only on the first sign-in**. The implementation already handles this:
```dart
if (user != null && appleCredential.givenName != null && appleCredential.familyName != null) {
  final displayName = '${appleCredential.givenName} ${appleCredential.familyName}';
  await user.updateDisplayName(displayName);
}
```

### 5.3 Testing First-Time Sign-In Again
To test the first-time flow again:
1. Go to iPhone Settings > Apple ID > Password & Security
2. Tap "Apps Using Apple ID"
3. Find your app and tap "Stop Using Apple ID"
4. Next sign-in will be treated as first-time

---

## OAuth2 Flow Explanation

The implementation uses OAuth2 with PKCE (Proof Key for Code Exchange) for enhanced security:

1. **Nonce Generation**: A cryptographically secure random string is generated
   ```dart
   final rawNonce = _generateNonce();
   final nonce = _sha256ofString(rawNonce);
   ```

2. **Apple Authorization**: User authenticates with Apple
   ```dart
   final appleCredential = await SignInWithApple.getAppleIDCredential(
     scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
     nonce: nonce,
   );
   ```

3. **OAuth Credential Creation**: Create Firebase credential with Apple token
   ```dart
   final oauthCredential = fb_auth.OAuthProvider('apple.com').credential(
     idToken: appleCredential.identityToken,
     rawNonce: rawNonce,
   );
   ```

4. **Firebase Authentication**: Sign in to Firebase
   ```dart
   final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
   ```

The nonce ensures that the token used for authentication was generated by your app and hasn't been tampered with.

---

## Troubleshooting

### Common Issues

**Error: "Invalid client"**
- Service ID not configured correctly in Apple Developer portal
- Domain or Return URL mismatch in Service ID configuration

**Error: "User cancelled"**
- Normal behavior when user taps "Cancel" on Apple Sign-In sheet
- Your app should handle this gracefully (already implemented)

**No name/email received**
- Apple only provides this on first sign-in
- Delete app and test account to test again
- Or revoke access in Settings > Apple ID > Password & Security

**Works in debug but not release**
- Ensure your release provisioning profile includes "Sign in with Apple" capability
- Check that bundle ID matches in both Apple Developer and Firebase

**Sign-In button doesn't appear**
- The button only shows on iOS devices (Platform.isIOS check)
- Android and other platforms won't show the Apple Sign-In option

---

## Summary Checklist

- [ ] Added "Sign in with Apple" capability in Xcode
- [ ] Enabled Sign in with Apple for App ID in Apple Developer portal
- [ ] Created Service ID for OAuth flow
- [ ] Configured domains and return URLs in Service ID
- [ ] Enabled Apple provider in Firebase Authentication
- [ ] (Optional) Created and uploaded Authentication Key for web support
- [ ] Tested on iOS simulator
- [ ] Tested on physical iOS device
- [ ] Handled email privacy (relay emails)
- [ ] Understood first-time user info limitation

---

## Next Steps

After completing Apple Sign-In setup:
1. Test all three social authentication methods (Google, Facebook, Apple)
2. Implement proper error handling and user feedback
3. Add analytics to track authentication success rates
4. Consider adding email/password authentication as fallback
5. Review and comply with Apple's Human Interface Guidelines for Sign in with Apple
