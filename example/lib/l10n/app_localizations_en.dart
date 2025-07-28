// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get leafDetector => 'Leaf Detector';

  @override
  String get menu => 'Menu';

  @override
  String get menuDescription => 'Click to open navigation menu';

  @override
  String get help => 'Help';

  @override
  String get helpDescription => 'Click to restart tutorial';

  @override
  String get quickAccess => 'Quick Access';

  @override
  String get quickAccessDescription => 'Click to see single image scan page';

  @override
  String get leafDetectorTitle => 'Leaf Detector';

  @override
  String get leafDetectorDescription =>
      'This is the leaf detector result screen';

  @override
  String get stopResumeCameraDescription => 'Click to stop or resume camera';

  @override
  String get shareImageDescription => 'Click to share the captured image';

  @override
  String get skip => 'Skip';

  @override
  String get yoloDetectionResult => 'YOLO Detection Result';

  @override
  String get detector => 'Detector';

  @override
  String get location => 'Lieu';

  @override
  String get singleImageDetectionTitle => 'Single Image Detection';

  @override
  String get helpButtonTooltip => 'More information about how this page works.';

  @override
  String get helpDialogTitle => 'Help';

  @override
  String get helpDialogContent =>
      'This app uses a YOLO model to classify a selected image.\n\n1- Accept location and file access permissions for the app to work.\n2- Location is used to detect air quality nearby. The higher the AQI, the worse the air quality and the higher the chance it contributes to the observed leaf disease.\n3- Tap the \'Select Image\' button and choose an image to analyze.\n4- When a leaf is detected, boxes appear around the leaf and detected disease traces with confidence percentages.\n5- Below, the disease name, confidence, and separate images for each detection are shown.';

  @override
  String get helpDialogClose => 'Close';

  @override
  String get reloadAirQualityTooltip =>
      'Reload air quality nearby if necessary.';

  @override
  String get airQualityLabel => 'Air Quality:';

  @override
  String get airQualityHelpTooltip => 'What is air quality?';

  @override
  String get airQualityDialogTitle => 'Air Quality';

  @override
  String get airQualityDialogContent =>
      'The Air Quality Index (AQI) is a standard measure indicating pollution in your area. Higher values mean worse air quality.\nComponents detectable include:\nH: Humidity, O3: Ozone, PM2.5: Fine particles ≤ 2.5 µm, W: Wind speed (m/s), NO2: Nitrogen dioxide, P: Atmospheric pressure, T: Temperature (°C), WG: Wind gusts.';

  @override
  String get airQualityDialogClose => 'Close';

  @override
  String get locationUnknown => 'Unknown';

  @override
  String get aqiUnavailable => 'N/A';

  @override
  String get pollutantsLabel => 'Pollutants:';

  @override
  String get aqiAnalysisUnknown =>
      'Unknown AQI. Cannot evaluate link with disease.';

  @override
  String get airQualityGood => 'Good';

  @override
  String get airQualityModerate => 'Moderate';

  @override
  String get airQualityUnhealthySensitive => 'Unhealthy for sensitive groups';

  @override
  String get airQualityUnhealthy => 'Unhealthy';

  @override
  String get airQualityVeryUnhealthy => 'Very Unhealthy';

  @override
  String get airQualityHazardous => 'Hazardous';

  @override
  String aqiAnalysisPattern(Object aqi, Object probability, Object quality) {
    return 'Air quality: $quality (AQI = $aqi). There is approximately $probability% chance that this pollution contributed to the potential disease observed on the leaf.';
  }

  @override
  String get selectImageButton => 'Select Image';

  @override
  String get modelLoading => 'Model loading...';

  @override
  String get classificationsTitle => 'Classifications:';

  @override
  String get detectionsTitle => 'Detections:';

  @override
  String get locationEnabledDescription =>
      'When location is enabled, it will be used to display the air quality nearby.';

  @override
  String get selectImageDescription =>
      'Click here and select an image to be analyzed.';
}
