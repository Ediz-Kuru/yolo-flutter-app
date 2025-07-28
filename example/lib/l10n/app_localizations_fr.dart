// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get leafDetector => 'Détecteur de Feuilles';

  @override
  String get menu => 'Menu';

  @override
  String get menuDescription => 'Cliquez pour ouvrir le menu de navigation';

  @override
  String get help => 'Aide';

  @override
  String get helpDescription => 'Cliquez pour redémarrer le tutoriel';

  @override
  String get quickAccess => 'Accès Rapide';

  @override
  String get quickAccessDescription =>
      'Cliquez pour voir la page d’analyse d’image unique';

  @override
  String get leafDetectorTitle => 'Détecteur de Feuilles';

  @override
  String get leafDetectorDescription =>
      'Voici l\'écran des résultats du détecteur de feuilles';

  @override
  String get stopResumeCameraDescription =>
      'Cliquez pour arrêter ou reprendre la caméra';

  @override
  String get shareImageDescription => 'Cliquez pour partager l’image capturée';

  @override
  String get skip => 'Passer';

  @override
  String get yoloDetectionResult => 'Résultat de Détection YOLO';

  @override
  String get detector => 'Détecteur';

  @override
  String get location => 'Lieu';

  @override
  String get singleImageDetectionTitle => 'Détection d\'image unique';

  @override
  String get helpButtonTooltip =>
      'Plus d\'informations sur le fonctionnement de la page.';

  @override
  String get helpDialogTitle => 'Aide';

  @override
  String get helpDialogContent =>
      'Cette application utilise un modèle YOLO pour classifier une image sélectionnée.\n\n1- Acceptez les demandes de permissions de localisation et accès aux fichiers pour le fonctionnement de l’application.\n2- La localisation est utilisée pour détecter la qualité de l’air dans les environs. Plus le AQI est élevé, moins l’air est bon. Et plus il y a des chances que cela soit responsable pour la feuille malade.\n3- Cliquez sur le bouton \'Select Image\' et choisissez une image à analyser.\n4- Lorsqu’une feuille est détectée, des boîtes apparaissent autour de la feuille et des traces de maladies détectées avec le pourcentage de certitude.\n5- Plus bas sont affichés le nom de la maladie détectée, sa certitude, et des images séparées pour chaque chose détectée.';

  @override
  String get helpDialogClose => 'Fermer';

  @override
  String get reloadAirQualityTooltip =>
      'Pour recharger la qualité de l\'air dans les alentours si nécessaire.';

  @override
  String get airQualityLabel => 'Qualité de l’air :';

  @override
  String get airQualityHelpTooltip => 'Qu’est-ce que la qualité de l’air ?';

  @override
  String get airQualityDialogTitle => 'Qualité de l’air';

  @override
  String get airQualityDialogContent =>
      'L’indice de qualité de l’air (AQI) est une mesure standard qui indique la pollution de l’air dans votre région. Plus la valeur est élevée, plus la qualité de l’air est mauvaise.\nListe des composants dans l’air qui peuvent être détectés :\nH : Humidité, O3 : Ozone, PM2.5 : Particules fines ≤ 2,5 µm, W : Vitesse du vent (m/s), NO2 : Dioxyde d’azote, P : Pression atmosphérique, T : Température (°C), WG : Rafales de vent.';

  @override
  String get airQualityDialogClose => 'Fermer';

  @override
  String get locationUnknown => 'Inconnu';

  @override
  String get aqiUnavailable => 'N/A';

  @override
  String get pollutantsLabel => 'Polluants :';

  @override
  String get aqiAnalysisUnknown =>
      'AQI inconnu. Impossible d’évaluer le lien avec la maladie.';

  @override
  String get airQualityGood => 'Bonne';

  @override
  String get airQualityModerate => 'Modérée';

  @override
  String get airQualityUnhealthySensitive =>
      'Mauvaise pour les groupes sensibles';

  @override
  String get airQualityUnhealthy => 'Mauvaise';

  @override
  String get airQualityVeryUnhealthy => 'Très mauvaise';

  @override
  String get airQualityHazardous => 'Dangereuse';

  @override
  String aqiAnalysisPattern(Object aqi, Object probability, Object quality) {
    return 'Qualité de l’air : $quality (AQI = $aqi). Il y a environ $probability% de chances que cette pollution soit un facteur ayant contribué à la potentielle maladie observée sur la feuille.';
  }

  @override
  String get selectImageButton => 'Sélectionner une image';

  @override
  String get modelLoading => 'Chargement du modèle...';

  @override
  String get classificationsTitle => 'Classifications :';

  @override
  String get detectionsTitle => 'Détections :';

  @override
  String get locationEnabledDescription =>
      'Quand la localisation est activée, celle-ci sera utilisée pour afficher la qualité de l\'air dans les alentours.';

  @override
  String get selectImageDescription =>
      'Cliquez ici et sélectionnez une image afin qu\'elle soit analysée.';
}
