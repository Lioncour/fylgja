# Fylgja - Network Connectivity Monitor

A Flutter application that monitors network connectivity in the background and notifies users with strong vibration and sound when connectivity is found.

## Features

- **Background Monitoring**: Continuously monitors network connectivity even when the app is in the background
- **Strong Notifications**: Uses vibration patterns and looping audio to alert users when connectivity is found
- **Pause Functionality**: Users can pause monitoring for a configurable duration (1-15 minutes)
- **Beautiful UI**: Matches the provided mockups with custom color palette and animations
- **Norwegian Language**: Full Norwegian text support

## Color Palette

- **Primary Background**: #FFFDE7 (Light Yellow)
- **Bottom Panel**: #4A3F55 (Dark Purple)
- **Notification Panel**: #D9D5D8 (Light Gray/Purple)
- **Button & About Page**: #F5ECEB (Light Pink/Beige)
- **Indicator & Icon**: #D4AF37 (Golden Yellow)

## Setup Instructions

1. **Install Flutter**: Make sure you have Flutter installed on your system
2. **Install Dependencies**: Run `flutter pub get` to install all required packages
3. **Add Audio File**: Replace `assets/audio/notification_sound.mp3` with your desired notification sound
4. **Run the App**: Use `flutter run` to start the application

## Required Permissions

### Android
- `INTERNET` - For network connectivity checks
- `VIBRATE` - For vibration notifications
- `WAKE_LOCK` - For background processing
- `FOREGROUND_SERVICE` - For background service

### iOS
- Background App Refresh must be enabled
- The app will request necessary permissions when needed

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── theme/
│   └── app_theme.dart       # Color palette and theme configuration
├── viewmodels/
│   └── main_viewmodel.dart  # State management with Provider
├── services/
│   └── background_service.dart # Background connectivity monitoring
└── pages/
    ├── main_page.dart       # Main UI with animated status indicator
    └── about_page.dart      # About page with pause duration settings
```

## Key Dependencies

- `provider`: State management
- `flutter_background_service`: Background processing
- `connectivity_plus`: Network connectivity detection
- `vibration`: Device vibration control
- `audioplayers`: Audio notification playback
- `shared_preferences`: User settings persistence
- `google_fonts`: Typography

## Usage

1. **Start Monitoring**: Tap "Start søk" to begin monitoring for network connectivity
2. **Coverage Found**: When connectivity is detected, the app will vibrate and play a looping sound
3. **Pause Monitoring**: Tap the notification panel to pause monitoring for the configured duration
4. **Adjust Settings**: Use the About page to configure pause duration (1-15 minutes)

## Background Service

The app uses `flutter_background_service` to ensure reliable background monitoring:

- Checks connectivity every 15 seconds
- Maintains foreground service on Android with persistent notification
- Handles iOS background app refresh
- Automatically stops monitoring when connectivity is lost

## Customization

### Audio Notification
Replace `assets/audio/notification_sound.mp3` with your preferred notification sound. The sound will loop continuously until the user pauses or connectivity is lost.

### Vibration Pattern
The current vibration pattern is `[0, 1000, 500, 2000]` (immediate start, 1s vibrate, 0.5s pause, 2s vibrate, repeat). This can be modified in `lib/services/background_service.dart`.

### Monitoring Interval
The connectivity check interval is set to 15 seconds. This can be adjusted in the `_startMonitoring` method of `background_service.dart`.

## Troubleshooting

1. **Background Service Not Working**: Ensure all required permissions are granted
2. **Audio Not Playing**: Check that the audio file exists and is properly formatted
3. **Vibration Not Working**: Verify device vibration is enabled and permissions are granted
4. **iOS Background Issues**: Ensure Background App Refresh is enabled in device settings

## Development

To build the app for production:

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## License

This project is created for educational and personal use.

