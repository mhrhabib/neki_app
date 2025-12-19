# Fixing Firebase Errors

This guide helps you resolve the `PERMISSION_DENIED`, `Index Required`, and `DEVELOPER_ERROR` logs you are seeing.

## 1. Fix Firestore Permissions

Copy and paste these rules into **Firebase Console > Firestore Database > Rules**. These are updated to be more flexible for development.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own data in any collection
    match /{collection}/{docId} {
      allow read, write: if request.auth != null && (
        docId == request.auth.uid || 
        (resource != null && resource.data.userId == request.auth.uid) ||
        (request.resource != null && request.resource.data.userId == request.auth.uid)
      );
    }
    
    // Profiles allow global reading for leaderboard
    match /profiles/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && userId == request.auth.uid;
    }
  }
}
```

## 2. Fix Index Required Error (DONE)
I have refactored the app to filter data in memory. You **no longer need** to create composite indexes in the Firebase Console. The app should now work immediately.

## 3. Fix Google Sign-In `DEVELOPER_ERROR`

If you are seeing `DEVELOPER_ERROR` or `ConnectionResult{statusCode=DEVELOPER_ERROR}`, it means your **SHA-1 Fingerprint** does not match your Firebase configuration.

### Step 1: Get your SHA-1
Run this in your terminal:
```bash
cd android && ./gradlew signingReport
```
Find the `SHA1` under the `debug` variant.

### Step 2: Add to Firebase
1. Go to [Firebase Console](https://console.firebase.google.com/) > Project Settings (gear icon).
2. Scroll to **Your apps** > **Android app**.
3. Click **Add fingerprint**.
4. Paste the SHA1 from the terminal.
5. **CRITICAL**: Re-download `google-services.json` and replace the one in `android/app/google-services.json`.

## 4. Troubleshooting Package Visibility
If you still see `java.lang.SecurityException: Unknown calling package name 'com.google.android.gms'`, I have already updated your `AndroidManifest.xml` with the required `<queries>` section. Running `flutter clean && flutter pub get` (which you just did) is the final step to apply this.
