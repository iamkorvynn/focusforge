# FocusForge — Pomodoro + Study Timer

A complete, real Pomodoro and study timer for Android. Focus sessions,
breaks, tasks, history and stats — all stored locally on the phone.
No accounts, no ads, no network calls, no demo data: the app starts empty.

## Features

- **Focus sessions** — custom durations (default 25 min focus, 5 min short
  break, 15 min long break, long break after 4 focus sessions)
- **Timer controls** — start, pause, resume, reset, skip
- **Tasks** — link a focus session to a task; tasks track total focus time
  and completed sessions
- **History & stats** — total focus time, session counts, day streak,
  7-day bar chart, focus time per task, full session history
- **Daily goal** — configurable daily focus target with a progress bar
- **Alerts** — notification with sound plus a vibration pulse when a
  session ends (runtime permission requested on Android 13+)
- **Background persistence** — the running timer is saved to SQLite with
  its end time, so it survives the app being killed or the phone
  restarting; on relaunch it resumes or completes and logs the session
- **Auto-start** — optionally start breaks and focus sessions automatically
- **Light & dark themes** — warm orange for focus, teal for breaks

## Tech

- Flutter 3.50 / Dart 3.14, Material 3
- `sqflite` for local storage (tasks, sessions, settings, timer state)
- `flutter_local_notifications` 22.3.3 for session-end alerts
- `permission_handler` 12.x for the notification permission
- `vibration` for the end-of-session pulse
- Core library desugaring enabled; release lint disabled (AGP lint
  crashes on this toolchain)

## Build

```sh
export PATH=~/workspace/flutter-sdk/flutter/bin:$PATH
export ANDROID_HOME=~/workspace/android-sdk
export JAVA_HOME=~/workspace/android-sdk/jdk17
export JAVA_TOOL_OPTIONS="-Djava.net.preferIPv4Stack=true"
export GRADLE_OPTS="-Djava.net.preferIPv4Stack=true"
export GRADLE_USER_HOME=~/workspace/overnight-8-apps/.gradle-home
export TMPDIR=~/workspace/overnight-5-apps/.tmp
export CI=true

flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Gradle is configured for a small VM: 1.5 GB heap, daemon off, 2 workers.
`TMPDIR` must point at workspace storage — `/tmp` is a 512 MB tmpfs and
release builds do not fit there.

## Permissions

- `INTERNET` — declared for the standard release check; the app makes no
  network calls.
- `VIBRATE` — end-of-session pulse.
- `POST_NOTIFICATIONS` — session-end alerts (Android 13+).
- `RECEIVE_BOOT_COMPLETED` — reserved for future timer restore on boot.

## Data

Everything lives in a local SQLite database (`focusforge.db`). Clearing
history deletes session records only; tasks and settings are untouched.
There is no cloud sync and no analytics.

## License

Private project — all rights reserved.
