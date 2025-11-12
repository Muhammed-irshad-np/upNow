# Alarm Full-Screen Flow – Manual Validation Checklist

Use these scenarios to confirm the new full-screen/foreground alarm flow is working end-to-end. Repeat on an Android 13+ device (with notification permission gating) and, if possible, on Android 11/12 for regression coverage.

## 1. Notifications granted, app in foreground
- Ensure `POST_NOTIFICATIONS` is granted (Settings → Apps → UpNow → Notifications).
- Schedule an alarm a few minutes ahead while the app is open.
- Expected: when the alarm fires the math task screen (`AlarmActivity`) comes to the front immediately, alarm tone + vibration loop via the foreground service, and solving the task stops the alarm and clears the persistent notification.

## 2. Notifications granted, app backgrounded & device locked
- With notification permission still allowed, press Home and lock the device.
- Wait for the alarm time.
- Expected: device wakes with the full-screen alarm UI on top of the lock screen; tone continues until the task is solved.

## 3. Notification permission denied
- Deny `POST_NOTIFICATIONS` via system settings.
- Attempt to create or re-enable an alarm.
- Expected: the UI blocks scheduling/toggling and surfaces the “Enable notifications so alarms can ring over the lock screen” guidance. No alarm should be scheduled.

## 4. App terminated / cold start
- Force stop the app (Settings → Apps → UpNow → Force stop) with an alarm still scheduled, then lock the device.
- Expected: when the alarm triggers, the foreground service starts, plays sound/vibration, and surfaces the full-screen UI even though the Flutter process was dead. Dismissing the alarm should relaunch the app and navigate as before.

## Known Caveats & Guidance
- If notifications are disabled, the system will suppress the full-screen intent; the Flutter UI warns the user before scheduling.
- Exact alarms still require the OS permission on Android 12+. If it is revoked at the system level, scheduling will fail at the native layer.
- Overlay (“display over other apps”) permission is no longer required; do not prompt users for it.
- OEM-specific battery savers can still interfere. If alarms appear late, guide users to exempt UpNow from battery optimization.

