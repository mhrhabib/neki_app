# Salah Lock Debugging Guide

## Overview
The automatic device locking feature has multiple steps that must all succeed for it to work. Use this guide to identify which step is failing.

## Issues Fixed
✅ **Prayer times are now recalculated every minute** - Previously, prayer times were calculated once and became stale after midnight
✅ **Comprehensive logging added** - All major functions now log to the console with emoji prefixes for easy debugging
✅ **Error handling improved** - Better error messages from the native Android code

## Debugging Checklist

### Step 1: Settings Are Saved
When you toggle "Lock Device Screen" in settings, check the console for:
```
⚙️ SalahLock: Saving settings - isEnabled: true, lockDeviceAndroid: true
✅ SalahLock: Settings saved successfully
```

**If you don't see this:**
- The toggle callback may not be firing
- Check the UI log for any errors

---

### Step 2: Monitoring Is Active
Once location and salah data are loaded, you should see:
```
📍 SalahLock: Location loaded - 37.7749, -122.4194
⚙️ SalahLock: Settings loaded - isEnabled: true, lockDeviceAndroid: true
🔔 SalahLock: Initial monitoring check started
🔔 SalahLock: Recalculated prayer times
```

**If you don't see location loaded:**
- Location permissions may not be granted
- Check that `LocationCubit` is properly initialized

---

### Step 3: Prayer Detection Works
During prayer times, you should see:
```
🕌 SalahLock: Recalculated prayer times
🕌 SalahLock: Current prayer = Prayer.fajr
🕌 SalahLock: Checking prayer: Fajr
🕌 SalahLock: Fajr completed? false
```

**If you see "Current prayer = Prayer.none":**
- Either not in prayer time window, OR
- Prayer times calculation is incorrect
- Verify location coordinates are accurate
- Check your timezone is correct

**If you see "Fajr completed? true":**
- The app thinks you already performed the prayer
- Go to home screen and reset the daily completion tracking

---

### Step 4: Device Admin Status
Before attempting to lock, the app checks:
```
🔒 SalahLock: lockDeviceAndroid = true
🔒 SalahLock: Device admin active? false
⚠️  SalahLock: Device admin NOT active, requesting...
```

**CRITICAL:** Device admin must be active! If you see `false`:

#### Android Steps to Activate Device Admin:
1. Open Settings
2. Go to **Security** or **Security & Location**
3. Look for **Device Admin Apps** or **Admin Apps**
4. Find **Neki Tracker** (or "Clearwave Systems")
5. Tap it and toggle **ON**
6. Confirm any prompts

**Verify it worked:**
- App should log: `🔒 SalahLock: Device admin active? true`
- Restart monitoring by going back to settings and retoggling "Lock Device Screen"

---

### Step 5: Device Lock Command
If device admin is active, you'll see:
```
🔒 SalahLock: Calling lockDeviceScreen()
✅ SalahLock: Device locked successfully
```

**If you see error instead:**
```
❌ SalahLock: Lock failed - PlatformException(ADMIN_INACTIVE, ...)
or
❌ SalahLock: Lock failed - PlatformException(LOCK_FAILED, ...)
```

This means the native call failed. Check Android logs:
```bash
adb logcat | grep SalahLock
```

Look for lines like:
```
D/SalahLock: lockDevice called
D/SalahLock: Admin is active, calling lockNow()
D/SalahLock: lockNow() succeeded
```

---

## Complete Test Flow

### To test end-to-end:

1. **Enable the feature:**
   - Go to Settings (bottom nav)
   - Find "Salah Lock Settings"
   - Toggle "Enable Salah Lock Mode" → ON
   - Toggle "Lock Device Screen" → ON
   - Note: Device admin must be active first!

2. **Verify settings are persisted:**
   - Close app completely
   - Reopen app
   - Go back to settings
   - Both toggles should still be ON

3. **Wait for next prayer time:**
   - Note the next prayer time from the home screen
   - When that time arrives, the screen should lock
   - Console should show lock sequence logs

4. **Unlock by confirming prayer:**
   - Screen is locked/overlay shown
   - Tap "I've Prayed" button
   - Screen should unlock
   - You should see: `🔓 SalahLock: Prayer completed, unlocking`

---

## Console Log Levels

| Prefix | Meaning | Action |
|--------|---------|--------|
| 📍 | Location tracking | Informational |
| 🕌 | Prayer detection | Informational |
| 🔒 | Device locking attempt | Check if `lockDeviceAndroid = true` |
| 🔓 | Device unlocking | Normal operation |
| 🚫 | App blocker | Informational |
| ⚙️  | Settings change | Verify settings saved |
| ⚠️  | Warning | Needs action (e.g., enable device admin) |
| ✅ | Success | Good state |
| ❌ | Error | Problem occurred |

---

## Common Issues & Fixes

### "Phone not locking even though logs show it tried"
1. Device admin is not actually active
2. Native code is failing silently
3. Solution: Check `adb logcat` for native error, reactivate device admin

### "Settings don't persist after app restart"
1. SharedPreferences not saving properly
2. Repository not being injected correctly
3. Solution: Check DI injection, verify SharedPreferences is initialized

### "Prayer time not being detected correctly"
1. Location is wrong
2. Timezone is incorrect
3. Solution: Go to Home > check prayer times shown match your location

### "Device locks but can still use phone normally"
1. Lock is too subtle
2. Solution: Increase overlay visibility, test app blocker feature

---

## How to View Logs

### In VS Code:
1. Run app in debug mode
2. Open Debug Console
3. All `debugPrint()` statements appear here
4. Filter by "SalahLock" to see relevant logs

### Android Logcat:
```bash
adb logcat | grep -E "SalahLock|DeviceManager"
```

### iOS Console:
```bash
flutter logs
```

---

## Recent Improvements in This Version

1. **Prayer times recalculated every minute** instead of once at startup
2. **Device admin status verified before lock attempt**
3. **Detailed logging at every step**
4. **Try-catch blocks to prevent silent failures**
5. **Native Android code logs added** for troubleshooting platform issues

---

## Next Steps If Still Not Working

1. **Collect logs and check all above conditions**
2. **Verify device admin is active:** Go to Settings > Security > Device Admin > Neki Tracker = ON
3. **Test in emulator vs. physical device** (emulator may not support all features)
4. **Check if running on Android 12+** (may have additional permission requirements)

