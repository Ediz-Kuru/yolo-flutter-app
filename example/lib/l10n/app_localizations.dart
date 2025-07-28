import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @leafDetector.
  ///
  /// In en, this message translates to:
  /// **'Leaf Detector'**
  String get leafDetector;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @menuDescription.
  ///
  /// In en, this message translates to:
  /// **'Click to open navigation menu'**
  String get menuDescription;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpDescription.
  ///
  /// In en, this message translates to:
  /// **'Click to restart tutorial'**
  String get helpDescription;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @quickAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Click to see single image scan page'**
  String get quickAccessDescription;

  /// No description provided for @leafDetectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaf Detector'**
  String get leafDetectorTitle;

  /// No description provided for @leafDetectorDescription.
  ///
  /// In en, this message translates to:
  /// **'This is the leaf detector result screen'**
  String get leafDetectorDescription;

  /// No description provided for @stopResumeCameraDescription.
  ///
  /// In en, this message translates to:
  /// **'Click to stop or resume camera'**
  String get stopResumeCameraDescription;

  /// No description provided for @shareImageDescription.
  ///
  /// In en, this message translates to:
  /// **'Click to share the captured image'**
  String get shareImageDescription;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @yoloDetectionResult.
  ///
  /// In en, this message translates to:
  /// **'YOLO Detection Result'**
  String get yoloDetectionResult;

  /// No description provided for @detector.
  ///
  /// In en, this message translates to:
  /// **'Detector'**
  String get detector;

  /// Label for location or place
  ///
  /// In en, this message translates to:
  /// **'Lieu'**
  String get location;

  /// No description provided for @singleImageDetectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Single Image Detection'**
  String get singleImageDetectionTitle;

  /// No description provided for @helpButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'More information about how this page works.'**
  String get helpButtonTooltip;

  /// No description provided for @helpDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpDialogTitle;

  /// No description provided for @helpDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This app uses a YOLO model to classify a selected image.\n\n1- Accept location and file access permissions for the app to work.\n2- Location is used to detect air quality nearby. The higher the AQI, the worse the air quality and the higher the chance it contributes to the observed leaf disease.\n3- Tap the \'Select Image\' button and choose an image to analyze.\n4- When a leaf is detected, boxes appear around the leaf and detected disease traces with confidence percentages.\n5- Below, the disease name, confidence, and separate images for each detection are shown.'**
  String get helpDialogContent;

  /// No description provided for @helpDialogClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get helpDialogClose;

  /// No description provided for @reloadAirQualityTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reload air quality nearby if necessary.'**
  String get reloadAirQualityTooltip;

  /// No description provided for @airQualityLabel.
  ///
  /// In en, this message translates to:
  /// **'Air Quality:'**
  String get airQualityLabel;

  /// No description provided for @airQualityHelpTooltip.
  ///
  /// In en, this message translates to:
  /// **'What is air quality?'**
  String get airQualityHelpTooltip;

  /// No description provided for @airQualityDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Air Quality'**
  String get airQualityDialogTitle;

  /// No description provided for @airQualityDialogContent.
  ///
  /// In en, this message translates to:
  /// **'The Air Quality Index (AQI) is a standard measure indicating pollution in your area. Higher values mean worse air quality.\nComponents detectable include:\nH: Humidity, O3: Ozone, PM2.5: Fine particles ≤ 2.5 µm, W: Wind speed (m/s), NO2: Nitrogen dioxide, P: Atmospheric pressure, T: Temperature (°C), WG: Wind gusts.'**
  String get airQualityDialogContent;

  /// No description provided for @airQualityDialogClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get airQualityDialogClose;

  /// No description provided for @locationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get locationUnknown;

  /// No description provided for @aqiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get aqiUnavailable;

  /// No description provided for @pollutantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pollutants:'**
  String get pollutantsLabel;

  /// No description provided for @aqiAnalysisUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown AQI. Cannot evaluate link with disease.'**
  String get aqiAnalysisUnknown;

  /// No description provided for @airQualityGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get airQualityGood;

  /// No description provided for @airQualityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get airQualityModerate;

  /// No description provided for @airQualityUnhealthySensitive.
  ///
  /// In en, this message translates to:
  /// **'Unhealthy for sensitive groups'**
  String get airQualityUnhealthySensitive;

  /// No description provided for @airQualityUnhealthy.
  ///
  /// In en, this message translates to:
  /// **'Unhealthy'**
  String get airQualityUnhealthy;

  /// No description provided for @airQualityVeryUnhealthy.
  ///
  /// In en, this message translates to:
  /// **'Very Unhealthy'**
  String get airQualityVeryUnhealthy;

  /// No description provided for @airQualityHazardous.
  ///
  /// In en, this message translates to:
  /// **'Hazardous'**
  String get airQualityHazardous;

  /// No description provided for @aqiAnalysisPattern.
  ///
  /// In en, this message translates to:
  /// **'Air quality: {quality} (AQI = {aqi}). There is approximately {probability}% chance that this pollution contributed to the potential disease observed on the leaf.'**
  String aqiAnalysisPattern(Object aqi, Object probability, Object quality);

  /// No description provided for @selectImageButton.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImageButton;

  /// No description provided for @modelLoading.
  ///
  /// In en, this message translates to:
  /// **'Model loading...'**
  String get modelLoading;

  /// No description provided for @classificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Classifications:'**
  String get classificationsTitle;

  /// No description provided for @detectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Detections:'**
  String get detectionsTitle;

  /// No description provided for @locationEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'When location is enabled, it will be used to display the air quality nearby.'**
  String get locationEnabledDescription;

  /// No description provided for @selectImageDescription.
  ///
  /// In en, this message translates to:
  /// **'Click here and select an image to be analyzed.'**
  String get selectImageDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
