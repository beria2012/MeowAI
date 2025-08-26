# MeowAI App Permissions

## Overview
This document outlines the permissions required by MeowAI for camera and gallery access to identify cat breeds from photos.

## Android Permissions

### Essential Permissions
- **CAMERA** - Required to take photos of cats for breed recognition
- **READ_EXTERNAL_STORAGE** (API ≤32) - Required to read images from gallery
- **READ_MEDIA_IMAGES** (API ≥33) - Modern permission for reading images from gallery  
- **WRITE_EXTERNAL_STORAGE** (API ≤32) - Required to save recognized cat photos

### Network & System Permissions
- **INTERNET** - Required for Firebase authentication and cloud sync
- **ACCESS_NETWORK_STATE** - Required to check network connectivity
- **VIBRATE** - For haptic feedback during photo capture
- **RECEIVE_BOOT_COMPLETED** - For background notifications
- **WAKE_LOCK** - For maintaining app functionality during processing

### Hardware Features
- **android.hardware.camera** (required) - Camera hardware must be present
- **android.hardware.camera.autofocus** (optional) - Autofocus feature
- **android.hardware.camera.flash** (optional) - Camera flash
- **android.hardware.camera.ar** (optional) - AR features for future enhancements

## iOS Permissions

### Camera & Photo Library
- **NSCameraUsageDescription** - "MeowAI needs camera access to take photos of cats for breed recognition."
- **NSPhotoLibraryUsageDescription** - "MeowAI needs photo library access to select cat images for breed recognition."
- **NSPhotoLibraryAddUsageDescription** - "MeowAI can save recognized cat photos to your photo library."

### Network Access
- **NSLocalNetworkUsageDescription** - "MeowAI uses local network access for Firebase services and cloud synchronization."
- **NSBonjourServices** - Firebase and network service discovery

## Removed Permissions

### What We Don't Request
❌ **Video Recording** - App focuses only on photo capture and analysis
❌ **Microphone Access** (removed from iOS) - Not needed for photo-only functionality  
❌ **Location Access** - Not required for cat breed identification
❌ **Contacts/SMS** - Not relevant to app functionality

## Permission Flow

### First Launch
1. User opens app
2. App requests camera permission when user tries to take photo
3. App requests gallery permission when user tries to select photo
4. All permissions are optional - user can still use other app features

### Runtime Permissions
- Permissions are requested only when needed
- Clear explanations provided for each permission request
- Graceful handling if permissions are denied

## Privacy Compliance

### Data Usage
- Photos are processed locally on device using TensorFlow Lite
- No photos are uploaded to servers without explicit user consent
- Recognition results can be optionally saved to user's photo library
- Firebase authentication uses minimal data (email/Google account)

### User Control
- Users can revoke permissions at any time in system settings
- App continues to function with limited features if permissions denied
- Clear privacy policy explains data usage

## Technical Implementation

### Android Configuration
```xml
<!-- Essential camera and storage permissions -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

### iOS Configuration  
```xml
<!-- Photo-only permissions -->
<key>NSCameraUsageDescription</key>
<string>MeowAI needs camera access to take photos of cats for breed recognition.</string>
```

### Camera Service Configuration
```dart
// Photo-only mode - no audio/video recording
CameraController(
  camera,
  resolution,
  enableAudio: false,  // Disabled for photo-only
  imageFormatGroup: ImageFormatGroup.jpeg,
)
```

## Future Considerations

If video recording features are added later, these additional permissions would be needed:
- Android: `RECORD_AUDIO`, `WRITE_EXTERNAL_STORAGE`
- iOS: `NSMicrophoneUsageDescription`

For now, the app is optimized for photo capture and gallery access only.