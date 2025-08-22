# MeowAI 🐱

A cross-platform mobile application built with Flutter that uses AI to identify cat breeds offline. Discover your cat's breed with just a photo!

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)](https://flutter.dev/)

## ✨ Features

### 🔍 Core Functionality
- **Offline AI Recognition**: Identify cat breeds using local TensorFlow Lite models
- **Camera Integration**: Take photos or select from gallery
- **Breed Encyclopedia**: Comprehensive database of 50+ cat breeds
- **Recognition History**: Save and review past identifications
- **Favorites System**: Bookmark favorite breeds and photos

### 🌟 Advanced Features
- **AR Experience**: View cat breeds in augmented reality
- **Multi-language Support**: Available in 13 languages
- **Social Sharing**: Share discoveries on social media
- **Google Photos Integration**: Save recognized photos to cloud
- **Accessibility**: Full screen reader and TTS support
- **Dark Mode**: Automatic theme switching

### 🎨 User Experience
- **Cat-themed UI**: Playful design with paw print animations
- **Smooth Animations**: Flutter Animate powered transitions
- **Responsive Design**: Optimized for all screen sizes
- **Offline-first**: Works without internet connection
- **Fast Performance**: Optimized for 60fps smooth experience

## 🏗️ Architecture

### Technology Stack
- **Framework**: Flutter 3.10+
- **Language**: Dart 3.0+
- **AI/ML**: TensorFlow Lite
- **State Management**: Riverpod
- **Local Database**: SQLite + Hive
- **Authentication**: Firebase Auth
- **Cloud Storage**: Google Photos API
- **AR Framework**: ARCore (Android)

### Project Structure
```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── cat_breed.dart
│   ├── recognition_result.dart
│   ├── user.dart
│   └── challenge.dart
├── screens/                     # UI screens
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── camera_screen.dart
│   ├── ar_screen.dart
│   ├── encyclopedia_screen.dart
│   ├── breed_detail_screen.dart
│   └── basic_screens.dart
├── services/                    # Business logic
│   ├── ml_service.dart
│   ├── camera_service.dart
│   ├── database_service.dart
│   ├── authentication_service.dart
│   ├── google_photos_service.dart
│   ├── notification_service.dart
│   ├── accessibility_service.dart
│   ├── sharing_service.dart
│   ├── ar_service.dart
│   ├── performance_service.dart
│   └── breed_data_service.dart
├── widgets/                     # Reusable UI components
│   └── cat_paw_button.dart
├── utils/                       # Utilities and helpers
│   ├── theme.dart
│   ├── app_localizations.dart
│   └── app_localizations_*.dart
└── firebase_options.dart        # Firebase configuration

assets/
├── images/                      # App images and breed photos
├── models/                      # TensorFlow Lite models
│   ├── cat_breed_classifier.tflite
│   └── labels.txt
├── icons/                       # App icons and UI icons
├── animations/                  # Lottie animations
├── data/                        # Static data files
│   └── cat_breeds.json
└── fonts/                       # Custom fonts
    └── Poppins/

test/
├── unit_tests.dart              # Unit tests
└── integration_test/
    └── app_test.dart            # Integration tests
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10 or higher
- Dart SDK 3.0 or higher
- Android Studio / VS Code
- Xcode (for iOS development)
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/meowai.git
   cd meowai
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a new Firebase project
   - Add Android and iOS apps
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the respective platform folders
   - Update `firebase_options.dart` with your configuration

4. **Generate code**
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

### Configuration

#### Firebase Setup
1. Enable Authentication (Google Sign-In)
2. Set up Google Photos API
3. Configure Firebase Analytics
4. Enable Crashlytics (optional)

#### ML Model Setup
1. Place your TensorFlow Lite model in `assets/models/`
2. Update model path in `MLService`
3. Ensure labels.txt matches your model output

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Performance Testing
```bash
flutter run --profile
```

## 📱 Building for Production

### Android
```bash
# APK
flutter build apk --release

# App Bundle (recommended)
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

For detailed deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

## 🔧 Performance Optimization

This app is optimized for:
- **Startup time**: < 3 seconds cold start
- **ML inference**: < 2 seconds per recognition
- **Memory usage**: < 150MB average
- **Battery efficiency**: Optimized camera and ML usage
- **App size**: < 50MB download size

For detailed optimization strategies, see [OPTIMIZATION.md](OPTIMIZATION.md).

## 🌍 Localization

Supported languages:
- English (en)
- Spanish (es)
- Russian (ru)
- Ukrainian (uk)
- Chinese Simplified (zh)
- Portuguese (pt)
- German (de)
- French (fr)
- Japanese (ja)
- Arabic (ar)
- Italian (it)
- Korean (ko)
- Turkish (tr)
- Hindi (hi)

### Adding New Languages
1. Create `app_localizations_[code].dart` in `utils/`
2. Add language to `supportedLocales` in `main.dart`
3. Update `AppLocalizations.delegate`

## 🔒 Privacy & Security

- **Local Processing**: All AI recognition happens on-device
- **Optional Cloud Sync**: Google Photos integration is opt-in
- **Data Encryption**: User data encrypted at rest
- **Privacy Controls**: Granular permission management
- **GDPR Compliant**: Full data export and deletion support

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new features
5. Ensure all tests pass
6. Submit a pull request

### Development Guidelines
- Follow Flutter/Dart style guide
- Write comprehensive tests
- Update documentation
- Use semantic commit messages
- Ensure accessibility compliance

## 📊 Analytics & Monitoring

- **Firebase Analytics**: User engagement tracking
- **Performance Monitoring**: App performance metrics
- **Crash Reporting**: Automatic crash detection
- **Custom Events**: ML accuracy and feature usage

## 🐛 Known Issues

- AR features require ARCore-compatible Android devices
- Some breeds may have lower recognition accuracy
- Large image files may cause memory pressure on older devices

## 🗺️ Roadmap

### Version 1.1
- [ ] Video recognition support
- [ ] Multiple cat detection
- [ ] Breed comparison feature
- [ ] Enhanced AR experiences

### Version 1.2
- [ ] Community features
- [ ] Vet recommendations
- [ ] Health insights
- [ ] Breeding information

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- TensorFlow team for the ML framework
- Flutter team for the amazing framework
- Cat breed data from various public sources
- Icons from Material Design Icons
- Fonts from Google Fonts

## 📞 Support

- **Email**: support@meowai.com
- **Issues**: [GitHub Issues](https://github.com/yourusername/meowai/issues)
- **Documentation**: [Wiki](https://github.com/yourusername/meowai/wiki)

---

**Made with ❤️ and 🐱 by the MeowAI Team**

## ✨ Features

### 🎯 Core Features
- **Offline Cat Breed Recognition**: Uses TensorFlow Lite for on-device AI inference
- **Camera Integration**: Take photos or select from gallery
- **Multi-language Support**: 13 languages including English, Spanish, Russian, Chinese, and more
- **Cat-themed UI**: Playful design with animations and rounded elements

### 📚 Additional Features
- **Breed Encyclopedia**: Comprehensive database of cat breeds with detailed information
- **Recognition History**: Keep track of all your past recognitions
- **Favorites & Notes**: Save favorite breeds and add personal notes
- **Challenges & Achievements**: Gamification elements to encourage exploration
- **Social Sharing**: Share discoveries with friends
- **Google Photos Integration**: Save recognized photos directly to Google Photos
- **AR Overlays**: Optional augmented reality features (planned)
- **Dark Mode**: Full accessibility support

## 🚀 Getting Started

### Prerequisites

1. **Flutter SDK** (>=3.10.0)
   ```bash
   # Install Flutter from https://flutter.dev/docs/get-started/install
   flutter doctor
   ```

2. **Platform Setup**
   - **Android**: Android Studio with Android SDK
   - **iOS**: Xcode (macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/MeowAI.git
   cd MeowAI
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate model files** (if needed)
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Configure Firebase** (for authentication and cloud features)
   - Create a Firebase project at https://console.firebase.google.com/
   - Add your Android/iOS apps to the project
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate platform directories
   - Update `lib/firebase_options.dart` with your configuration

5. **Add ML Model**
   - Place your trained cat breed classifier model at `assets/models/cat_breed_classifier.tflite`
   - Ensure the labels file matches your model's output classes

### Running the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Specific platform
flutter run -d android
flutter run -d ios
```

## 🏗️ Architecture

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── cat_breed.dart
│   ├── recognition_result.dart
│   ├── user.dart
│   └── challenge.dart
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── camera_screen.dart
│   └── basic_screens.dart
├── services/                 # Business logic
│   ├── ml_service.dart
│   ├── camera_service.dart
│   └── breed_data_service.dart
├── utils/                    # Utilities
│   ├── theme.dart
│   └── app_localizations.dart
└── widgets/                  # Reusable widgets
    └── cat_paw_button.dart
```

### Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod/Provider
- **Machine Learning**: TensorFlow Lite
- **Database**: SQLite + Hive (local storage)
- **Authentication**: Firebase Auth + Google Sign-In
- **Cloud Storage**: Google Photos API
- **Localization**: Flutter Intl
- **Animations**: Flutter Animate

## 🤖 Machine Learning

### Model Requirements
- **Input**: 224x224 RGB images
- **Output**: Probability distribution over cat breeds
- **Format**: TensorFlow Lite (.tflite)
- **Size**: Optimized for mobile (< 50MB recommended)

### Supported Breeds
The app currently supports 50+ cat breeds including:
- Persian, Maine Coon, Siamese
- British Shorthair, Ragdoll, Bengal
- Russian Blue, Sphynx, Scottish Fold
- And many more...

## 🌍 Localization

Supported languages:
- 🇺🇸 English
- 🇪🇸 Spanish
- 🇷🇺 Russian
- 🇺🇦 Ukrainian
- 🇨🇳 Chinese (Simplified)
- 🇧🇷 Portuguese (Brazilian)
- 🇩🇪 German
- 🇫🇷 French
- 🇯🇵 Japanese
- 🇸🇦 Arabic
- 🇮🇹 Italian
- 🇰🇷 Korean
- 🇹🇷 Turkish
- 🇮🇳 Hindi

## 📱 Platform Support

- ✅ Android (API 21+)
- ✅ iOS (11.0+)
- 🚧 Web (limited features)

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Generate coverage report
flutter test --coverage
```

## 📦 Building for Release

### Android (APK/AAB)
```bash
# APK
flutter build apk --release

# App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### iOS (IPA)
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Cat breed data sourced from various feline organizations
- ML model training inspired by pet classification research
- Icons and animations from the Flutter community
- Special thanks to cat lovers worldwide! 🐱

## 📞 Support

If you encounter any issues or have questions:
- 📧 Email: support@meowai.app
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/MeowAI/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/MeowAI/discussions)

---

**Made with ❤️ for cat lovers everywhere**
