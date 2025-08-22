import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'app_localizations_en.dart';

/// Callers can lookup localized strings with Localizations.of<AppLocalizations>(context)!.
///
/// You should rarely need to create an instance of this class manually.
/// Prefer using the static getters in [AppLocalizations.of] for most use cases.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ru'),
    Locale('uk'),
    Locale('zh'),
    Locale('pt'),
    Locale('de'),
    Locale('fr'),
    Locale('ja'),
    Locale('ar'),
    Locale('it'),
    Locale('ko'),
    Locale('tr'),
    Locale('hi'),
  ];

  // Common UI strings
  String get appTitle => 'MeowAI';
  
  String get welcome => 'Welcome';
  
  String get hello => 'Hello';
  
  String get takePhoto => 'Take Photo';
  
  String get fromGallery => 'From Gallery';
  
  String get recognizeBreed => 'Recognize Breed';
  
  String get loading => 'Loading...';
  
  String get processing => 'Processing...';
  
  String get analyzing => 'Analyzing...';
  
  String get cancel => 'Cancel';
  
  String get retry => 'Retry';
  
  String get save => 'Save';
  
  String get share => 'Share';
  
  String get delete => 'Delete';
  
  String get edit => 'Edit';
  
  String get close => 'Close';
  
  String get back => 'Back';
  
  String get next => 'Next';
  
  String get done => 'Done';
  
  String get settings => 'Settings';
  
  String get profile => 'Profile';
  
  String get about => 'About';
  
  String get help => 'Help';
  
  String get feedback => 'Feedback';
  
  // Navigation
  String get home => 'Home';
  
  String get encyclopedia => 'Encyclopedia';
  
  String get history => 'History';
  
  String get favorites => 'Favorites';
  
  String get challenges => 'Challenges';
  
  // Cat breed recognition
  String get catBreedRecognition => 'Cat Breed Recognition';
  
  String get recognitionResult => 'Recognition Result';
  
  String get confidence => 'Confidence';
  
  String get alternativePredictions => 'Alternative Predictions';
  
  String get breedInformation => 'Breed Information';
  
  String get characteristics => 'Characteristics';
  
  String get temperament => 'Temperament';
  
  String get origin => 'Origin';
  
  String get lifeSpan => 'Life Span';
  
  String get weight => 'Weight';
  
  String get energyLevel => 'Energy Level';
  
  String get sheddingLevel => 'Shedding Level';
  
  String get socialNeeds => 'Social Needs';
  
  String get groomingNeeds => 'Grooming Needs';
  
  String get hypoallergenic => 'Hypoallergenic';
  
  String get rare => 'Rare';
  
  // Messages
  String get readyToDiscover => 'Ready to discover your cat\'s breed?';
  
  String get captureACat => 'Capture a cat';
  
  String get choosePhoto => 'Choose photo';
  
  String get breedOfTheDay => 'Breed of the Day';
  
  String get yourStats => 'Your Stats';
  
  String get recognized => 'Recognized';
  
  String get breedsFound => 'Breeds Found';
  
  String get streakDays => 'Streak Days';
  
  String get exploreFeatures => 'Explore Features';
  
  String get learnAboutCatBreeds => 'Learn about cat breeds';
  
  String get viewPastRecognitions => 'View past recognitions';
  
  String get savedBreedsAndPhotos => 'Saved breeds & photos';
  
  String get shareYourDiscoveries => 'Share your discoveries';
  
  // Error messages
  String get errorOccurred => 'An error occurred';
  
  String get cameraPermissionRequired => 'Camera permission is required';
  
  String get storagePermissionRequired => 'Storage permission is required';
  
  String get noImageSelected => 'No image selected';
  
  String get failedToLoadImage => 'Failed to load image';
  
  String get recognitionFailed => 'Recognition failed';
  
  String get networkError => 'Network error';
  
  String get tryAgain => 'Try again';
  
  // Achievements and challenges
  String get achievement => 'Achievement';
  
  String get challenge => 'Challenge';
  
  String get completed => 'Completed';
  
  String get inProgress => 'In Progress';
  
  String get expired => 'Expired';
  
  String get daysLeft => 'days left';
  
  String get hoursLeft => 'hours left';
  
  String get minutesLeft => 'minutes left';
  
  // Search and filter
  String get search => 'Search';
  
  String get filter => 'Filter';
  
  String get sortBy => 'Sort by';
  
  String get name => 'Name';
  
  String get popularity => 'Popularity';
  
  String get rarity => 'Rarity';
  
  String get showAll => 'Show all';
  
  String get showOnlyRare => 'Show only rare';
  
  String get showHypoallergenic => 'Show hypoallergenic';
  
  // Dynamic strings with parameters
  String confidencePercentage(int percentage) => '$percentage%';
  
  String recognitionsCount(int count) => '$count recognitions';
  
  String breedsCount(int count) => '$count breeds';
  
  String daysCount(int count) => '$count days';
  
  String hoursCount(int count) => '$count hours';
  
  String minutesCount(int count) => '$count minutes';
  
  String recognizedOn(String date) => 'Recognized on $date';
  
  String addedToFavorites(String breedName) => '$breedName added to favorites';
  
  String removedFromFavorites(String breedName) => '$breedName removed from favorites';
  
  String sharedSuccessfully(String breedName) => '$breedName shared successfully';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'ru', 'uk', 'zh', 'pt', 'de', 'fr', 'ja', 'ar', 'it', 'ko', 'tr', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEn(); // TODO: Implement AppLocalizationsEs
    case 'ru': return AppLocalizationsEn(); // TODO: Implement AppLocalizationsRu
    case 'uk': return AppLocalizationsEn(); // TODO: Implement AppLocalizationsUk
    case 'zh': return AppLocalizationsEn(); // TODO: Implement AppLocalizationsZh
    case 'pt': return AppLocalizationsEn(); // TODO: Implement AppLocalizationsPt
    case 'de': return AppLocalizationsEn(); // TODO: Implement AppLocalizationsDe
    case 'fr': return AppLocalizationsEn(); // TODO: Implement AppLocalizationsFr
    case 'ja': return AppLocalizationsEn(); // TODO: Implement AppLocalizationsJa
    case 'ar': return AppLocalizationsEn(); // TODO: Implement AppLocalizationsAr
    case 'it': return AppLocalizationsEn(); // TODO: Implement AppLocalizationsIt
    case 'ko': return AppLocalizationsEn(); // TODO: Implement AppLocalizationsKo
    case 'tr': return AppLocalizationsEn(); // TODO: Implement AppLocalizationsTr
    case 'hi': return AppLocalizationsEn(); // TODO: Implement AppLocalizationsHi
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. '
  );
}