// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:image/image.dart' as img;


/// A screen that demonstrates YOLO inference on a single image.
///
/// This screen allows users to:
/// - Pick an image from the gallery
/// - Run YOLO inference on the selected image
/// - View detection results and annotated image
///
///

import 'package:geolocator/geolocator.dart'; // Pour le GPS
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:ultralytics_yolo_example/drawer.dart';

class AirQualityData {
  final int? aqi;
  final City? city;
  final Map<String, Pollutant>? iaqi;



  AirQualityData({this.aqi, this.city, this.iaqi});

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    if (json['status'] != 'ok') {
      debugPrint('API status is not OK: ${json['data']}');
      return AirQualityData();
    }

    final data = json['data'] as Map<String, dynamic>;

    Map<String, Pollutant>? iaqiData;
    if (data['iaqi'] != null) {
      iaqiData = (data['iaqi'] as Map).map(
            (key, value) => MapEntry(key, Pollutant.fromJson(value)),
      ).cast<String, Pollutant>();
    }

    return AirQualityData(
      aqi: data['aqi'] as int?,
      city: data['city'] != null ? City.fromJson(data['city']) : null,
      iaqi: iaqiData,
    );
  }
}

class City {
  final String? name;
  City({this.name});
  factory City.fromJson(Map<String, dynamic> json) {
    return City(name: json['name'] as String?);
  }
}

class Pollutant {
  final double? value;
  Pollutant({this.value});
  factory Pollutant.fromJson(Map<String, dynamic> json) {
    return Pollutant(value: (json['v'] as num?)?.toDouble());
  }
}

class SingleImageScreen extends StatefulWidget {
  const SingleImageScreen({super.key});

  @override
  State<SingleImageScreen> createState() => _SingleImageScreenState();
}

class _SingleImageScreenState extends State<SingleImageScreen> {
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _detections = [];
  List<Map<String, dynamic>> _classifications = [];
  Uint8List? _imageBytes;
  Uint8List? _annotatedImage;
  AirQualityData? _airQualityData;
  bool _isLoadingAQ = true;
  String? _errorMessageAQ;
  final String _apiKey = '30c439655961e0b68355453e7665cdfebbfd51cb';


  late YOLO _yolo;
  final YOLO _classifier = YOLO(
    modelPath: "yolo11n-cls",
    task: YOLOTask.classify,
    useMultiInstance: true,
  );
  String _modelPathForYOLO =
      'yolo11n'; // Default asset path for non-iOS or if local copy fails
  bool _isModelReady = false;

  // Name of the .mlpackage directory in local storage (after unzipping)
  final String _mlPackageDirName =
      'yolo11n-seg.mlpackage'; // Changed to yolo11n
  // Name of the zip file in assets (e.g., assets/models/yolo11n.mlpackage.zip)
  final String _mlPackageZipAssetName =
      'yolo11n-seg.mlpackage.zip'; // Changed to yolo11n





  /// Coupe une image à partir des coordonnées (x1, y1, x2, y2).
  /// [imageBytes] : bytes de l'image complète.
  /// Retourne les bytes PNG de la sous-image.
  Uint8List cropImage(Uint8List imageBytes, int x1, int y1, int x2, int y2) {
    // Decode l'image originale en image manipulable
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      throw Exception('Impossible de décoder l\'image');
    }

    // Calculer largeur et hauteur du crop
    int width = x2 - x1;
    int height = y2 - y1;

    // S'assurer que les coordonnées sont dans les limites
    x1 = x1.clamp(0, originalImage.width - 1);
    y1 = y1.clamp(0, originalImage.height - 1);
    width = width.clamp(1, originalImage.width - x1);
    height = height.clamp(1, originalImage.height - y1);

    // Extraire la région
    img.Image cropped = img.copyCrop(
      originalImage,
      x: x1,
      y: y1,
      width: width,
      height: height,
    );

    // Encoder en PNG
    List<int> pngBytes = img.encodePng(cropped);

    return Uint8List.fromList(pngBytes);
  }
  List<Uint8List> _croppedImages = [];








  /// Initializes the YOLO model for inference
  ///
  /// For iOS:
  /// - Copies the .mlpackage from assets to local storage
  /// - Uses the local path for model loading
  /// For other platforms:
  /// - Uses the default asset path
  Future<void> _initializeYOLO() async {
    if (Platform.isIOS) {
      try {
        final localPath = await _copyMlPackageFromAssets();
        if (localPath != null) {
          _modelPathForYOLO = localPath;
          debugPrint('iOS: Using local .mlpackage path: $_modelPathForYOLO');
        } else {
          debugPrint(
            'iOS: Failed to copy .mlpackage, using default asset path.',
          );
        }
      } catch (e) {
        debugPrint('Error during .mlpackage copy for iOS: $e');
      }
    }

    _yolo = YOLO(
      modelPath: _modelPathForYOLO,
      task: YOLOTask.detect,
      useMultiInstance: true,
    );

    try {
      await _yolo.loadModel();
      await _classifier.loadModel();
      if (mounted) {
        setState(() {
          _isModelReady = true;
        });
      }
      debugPrint(
        'YOLO model initialized. Path: $_modelPathForYOLO, Ready: $_isModelReady',
      );
    } catch (e) {
      debugPrint('Error loading YOLO model: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading model: $e')));
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _fetchAirQualityData() async {
    setState(() {
      _isLoadingAQ = true;
      _errorMessageAQ = null;
      _airQualityData = null;
    });

    try {
      final position = await _determinePosition();
      final Uri uri = Uri.parse(
        'https://api.waqi.info/feed/geo:${position.latitude};${position.longitude}/?token=$_apiKey',
      );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final data = AirQualityData.fromJson(jsonResponse);

        if (data.aqi != null) {
          setState(() => _airQualityData = data);
        } else {
          setState(() => _errorMessageAQ = 'No AQI data found.');
        }
      } else {
        setState(() => _errorMessageAQ = 'Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessageAQ = 'Error fetching AQI data: $e');
    } finally {
      setState(() => _isLoadingAQ = false);
    }
  }


  /// Copies the .mlpackage from assets to local storage
  ///
  /// This is required for iOS to properly load the model.
  /// Returns the path to the local .mlpackage directory if successful,
  /// null otherwise.
  Future<String?> _copyMlPackageFromAssets() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String localMlPackageDirPath =
          '${appDocDir.path}/$_mlPackageDirName';
      final Directory localMlPackageDir = Directory(localMlPackageDirPath);

      final manifestFile = File('$localMlPackageDirPath/Manifest.json');
      if (await localMlPackageDir.exists() && await manifestFile.exists()) {
        debugPrint(
          '.mlpackage directory and Manifest.json already exist and are correctly placed: $localMlPackageDirPath',
        );
        return localMlPackageDirPath;
      } else {
        if (await localMlPackageDir.exists()) {
          debugPrint(
            'Manifest.json not found at expected location or .mlpackage directory is incomplete. Will attempt to re-extract.',
          );
          // To ensure a clean state, you might consider deleting the directory first:
          // await localMlPackageDir.delete(recursive: true);
          // debugPrint('Deleted existing incomplete directory: $localMlPackageDirPath');
        }
        // Ensure the base directory exists before extraction
        if (!await localMlPackageDir.exists()) {
          await localMlPackageDir.create(recursive: true);
          debugPrint(
            'Created .mlpackage directory for extraction: $localMlPackageDirPath',
          );
        }
      }

      final String assetZipPath = 'assets/models/$_mlPackageZipAssetName';

      debugPrint(
        'Attempting to copy and unzip $assetZipPath to $localMlPackageDirPath',
      );

      final ByteData zipData = await rootBundle.load(assetZipPath);
      final List<int> zipBytes = zipData.buffer.asUint8List(
        zipData.offsetInBytes,
        zipData.lengthInBytes,
      );

      final archive = ZipDecoder().decodeBytes(zipBytes);

      for (final fileInArchive in archive) {
        final String originalFilenameInZip = fileInArchive.name;
        String filenameForExtraction = originalFilenameInZip;

        final String expectedPrefix = '$_mlPackageDirName/';
        if (originalFilenameInZip.startsWith(expectedPrefix)) {
          filenameForExtraction = originalFilenameInZip.substring(
            expectedPrefix.length,
          );
        }

        if (filenameForExtraction.isEmpty) {
          debugPrint(
            'Skipping empty filename after prefix strip: $originalFilenameInZip',
          );
          continue;
        }

        final filePath = '${localMlPackageDir.path}/$filenameForExtraction';

        if (fileInArchive.isFile) {
          final data = fileInArchive.content as List<int>;
          final localFile = File(filePath);
          try {
            await localFile.parent.create(recursive: true);
            await localFile.writeAsBytes(data);
            debugPrint(
              'Extracted file: $filePath (Size: ${data.length} bytes)',
            );
            if (filenameForExtraction == 'Manifest.json') {
              debugPrint('Manifest.json was written to $filePath');
            }
          } catch (e) {
            debugPrint('!!! Failed to write file $filePath: $e');
          }
        } else {
          final localDir = Directory(filePath);
          try {
            await localDir.create(recursive: true);
            debugPrint('Created directory: $filePath');
          } catch (e) {
            debugPrint('!!! Failed to create directory $filePath: $e');
          }
        }
      }

      final manifestFileAfterExtraction = File(
        '$localMlPackageDirPath/Manifest.json',
      );
      if (await manifestFileAfterExtraction.exists()) {
        debugPrint(
          'CONFIRMED: Manifest.json exists at ${manifestFileAfterExtraction.path}',
        );
      } else {
        debugPrint(
          'ERROR: Manifest.json DOES NOT exist at ${manifestFileAfterExtraction.path} after extraction loop.',
        );
      }

      debugPrint(
        'Successfully finished attempt to unzip .mlpackage to local storage: $localMlPackageDirPath',
      );
      return localMlPackageDirPath;
    } catch (e) {
      debugPrint('Error in _copyMlPackageFromAssets (outer try-catch): $e');
      return null;
    }
  }

  String analyzeAQIAndDiseaseLink(int? aqi) {
    if (aqi == null) return "AQI inconnu. Impossible d’évaluer le lien avec la maladie.";

    String quality;
    double probability;

    if (aqi <= 50) {
      quality = "Bonne";
      probability = 0.05;
    } else if (aqi <= 100) {
      quality = "Modérée";
      probability = 0.10;
    } else if (aqi <= 150) {
      quality = "Mauvaise pour les groupes sensibles";
      probability = 0.25;
    } else if (aqi <= 200) {
      quality = "Mauvaise";
      probability = 0.45;
    } else if (aqi <= 300) {
      quality = "Très mauvaise";
      probability = 0.65;
    } else {
      quality = "Dangereuse";
      probability = 0.85;
    }

    return "Qualité de l’air : $quality (AQI = $aqi). "
        "Il y a environ ${(probability * 100).toStringAsFixed(0)}% de chances "
        "que cette pollution soit un facteur ayant contribué à la potentielle maladie observée sur la feuille.";
  }


  /// Picks an image from the gallery and runs inference
  ///
  /// This method:
  /// - Opens the image picker
  /// - Runs YOLO inference on the selected image
  /// - Updates the UI with detection results and annotated image
  Future<void> _pickAndPredict() async {
    if (!_isModelReady) {
      debugPrint('Model not ready yet for inference.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model is loading, please wait...')),
        );
      }
      return;
    }

    PermissionStatus status;
    if (Platform.isAndroid) {
      status = await Permission.photos.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        status = await Permission.photos.request();
      }
    } else if (Platform.isIOS) {
      status = await Permission.photos.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        status = await Permission.photos.request();
      }
    } else {
      status = PermissionStatus.granted;
    }

    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission refusée. Impossible d’ouvrir la galerie.')),
        );
      }
      return;
    }

    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final detectionResults = await _yolo.predict(bytes);
    final classificationResults = await _classifier.predict(bytes);

    if (mounted) {
      setState(() {
        _imageBytes = bytes;
        if (detectionResults.containsKey('boxes') &&
            detectionResults['boxes'] is List &&
            _imageBytes != null) {
          _detections = List<Map<String, dynamic>>.from(detectionResults['boxes']);

          // Générer les images cropped pour chaque détection
          _croppedImages = _detections.map((d) {
            try {
              // Récupère et convertit les coordonnées en int
              int x1 = (d['x1'] as num).toInt();
              int y1 = (d['y1'] as num).toInt();
              int x2 = (d['x2'] as num).toInt();
              int y2 = (d['y2'] as num).toInt();

              return cropImage(_imageBytes!, x1, y1, x2, y2);
            } catch (e) {
              debugPrint('Erreur cropping: $e');
              return Uint8List(0); // image vide en cas d'erreur
            }
          }).toList();

          _classifications = List<Map<String, dynamic>>.from(
            classificationResults['detections'],
          );

        } else {
          _detections = [];
          _croppedImages = [];
          _classifications = [];
        }


        if (detectionResults.containsKey('annotatedImage') &&
            detectionResults['annotatedImage'] is Uint8List) {
          _annotatedImage = detectionResults['annotatedImage'] as Uint8List;
        } else {
          _annotatedImage = null;
        }

        _imageBytes = bytes;
      });
    }
  }

  final _keyResult = GlobalKey();
  final _keyLoca = GlobalKey();
  final _keyReload = GlobalKey();
  final _keyInfo = GlobalKey();
  final _keyReturn = GlobalKey();
  BuildContext? MyContext;
  @override
  void initState() {
    super.initState();
    _initializeYOLO();
    _fetchAirQualityData();

    WidgetsBinding.instance!.addPostFrameCallback((_) {ShowCaseWidget.of(MyContext!)!.startShowCase([_keyResult, _keyLoca, _keyReload, _keyInfo, _keyReturn]);
      });}

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(builder: (context) {
      MyContext = context;
      return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Single Image Detection'),
        leading: Showcase(
          key: _keyReturn,
          description: "Cliquez ici pour ouvrir le menu de navigation",
          child: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ),

        actions: [
          IconButton(
            icon: Showcase(
                key: _keyInfo,
                targetPadding: const EdgeInsets.all(8),
                description: "Plus d'informations sur le fonctionnement de la page.",
                targetShapeBorder: const CircleBorder(),
                tooltipBackgroundColor: Colors.blueAccent,

                child: const Icon(Icons.help_outline)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Aide'),
                    content: const Text(
                      'Cette application utilise un modèle YOLO pour classifier une image sélectionné.\n\n'
                          '1- Acceptez les demandes de permissions de localisation et accès aux fichiers pour le fonctionnement de l’application. \n'
                          '2- La localisation est utilisée  pour détecter la qualité de l’air dans les environs. Plus le AQI est élévé, moins l’air est bon. Et plus y a des chances que cela soit responsable pour la feuille malade.. \n'
                          '3- Cliquez sur le bouton ’Select Image’ et choisissez une image à analyser. \n'
                          '4- Lorsqu’une feuille est détectée, des boites apparaitront autours de la feuille et ses traces de maladies détectées. Le % affiché est la certitude du résultat.\n'
                          '5- Plus bas est affiché le nom de la maladie détectée, sa certitude, et des images séparées pour chaque chose détectée. \n',
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Fermer'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: Showcase(

                key: _keyReload,
                targetPadding: const EdgeInsets.all(8),
                description: "Pour recharger la qualité de l'air dans les alentours si nécessaire.",
                targetShapeBorder: const CircleBorder(),
                tooltipBackgroundColor: Colors.blueAccent,

                child: const Icon(Icons.refresh)),
            onPressed: _fetchAirQualityData,
          ),
        ],
      ),
      body: SingleChildScrollView( // <--- TOUT est scrollable maintenant
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const SizedBox(height: 20),

            if (_isLoadingAQ)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessageAQ != null)
              Text(
                _errorMessageAQ!,
                style: const TextStyle(color: Colors.red),
              )
            else if (_airQualityData != null)
                Showcase(
                  key: _keyLoca,
                  //targetPadding: const EdgeInsets.all(8),
                  description: "Quand la localisation est activée, celle-ci sera utilisée pour afficher la qualité de l'air dans les alentours.",
                  //targetShapeBorder: const CircleBorder(),
                  tooltipBackgroundColor: Colors.blueAccent,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Qualité de l’air :',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline, size: 20),
                            tooltip: 'Qu’est-ce que la qualité de l’air ?',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Qualité de l’air'),
                                  content: const Text(
                                    'L’indice de qualité de l’air (AQI) est une mesure standard '
                                        'qui indique la pollution de l’air dans votre région. '
                                        'Plus la valeur est élevée, plus la qualité de l’air est mauvaise.'
                                        '\n Liste des componants dans l’air qui peuvent etre détectés:'
                                        '\n, H: Humidité, O3: Ozone, PM2.5: Particules fines de diamètres ≤ 2.5 µm'
                                        ', W: Vitesse du vent en m/s, NO2: Dioxyde d’azote, P: Pression atmosphérique'
                                        ', T: Température en °C, WG: Rafales de vent (Wind Gust)'
                                    ,


                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Fermer'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Text('Lieu : ${_airQualityData!.city?.name ?? 'Inconnu'}'),
                      Text('AQI : ${_airQualityData!.aqi ?? 'N/A'}'),
                      const SizedBox(height: 8),
                      const Text('Polluants :'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16, // espace horizontal entre colonnes
                        runSpacing: 8, // espace vertical entre lignes
                        children: _airQualityData!.iaqi?.entries.map((e) {
                          return SizedBox(
                            width: MediaQuery.of(context).size.width / 2 - 24, // pour faire 2 colonnes
                            child: Text(
                              '${e.key.toUpperCase()} : ${e.value.value?.toStringAsFixed(2) ?? 'N/A'}',
                            ),
                          );
                        }).toList() ?? [],
                      ),
                    ],
                  ),
                ),

            if (_airQualityData != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  analyzeAQIAndDiseaseLink(_airQualityData!.aqi),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),


            const SizedBox(height: 20),

            Center(
              child: Showcase(
                key: _keyResult,
                targetPadding: const EdgeInsets.all(20),
                description: "Cliquez ici et sélectionnez une image afin qu'elle soit analysée.",
                targetShapeBorder: const CircleBorder(),
                tooltipBackgroundColor: Colors.blueAccent,
                child: ElevatedButton(
                  onPressed: _pickAndPredict,
                  child: const Text('Select Image'),
                ),
              ),
            ),


            const SizedBox(height: 10),

            if (!_isModelReady)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(width: 10),
                    Text("Model loading..."),
                  ],
                ),
              ),

            if (_annotatedImage != null)
              SizedBox(
                height: 300,
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    showImageViewer(
                      context,
                      MemoryImage(_annotatedImage!),
                      swipeDismissible: false,
                    );
                  },
                  child: Image.memory(_annotatedImage!),
                ),
              )
            else if (_imageBytes != null)
              SizedBox(
                height: 300,
                width: double.infinity,
                child: Image.memory(_imageBytes!),
              ),

            const SizedBox(height: 12),

            const Text('Classifications:'),
            ..._classifications.map((d) {
              final className = (d['className'] ?? d['class'] ?? 'Unknown').toString();
              final confidence = d['confidence'] != null
                  ? (d['confidence'] * 100).toStringAsFixed(1)
                  : '?';
              return Text('$className ($confidence%)');
            }),

            const SizedBox(height: 10),

            if (_croppedImages.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text('Détections :'),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _croppedImages.length,
                      itemBuilder: (context, index) {
                        final imgBytes = _croppedImages[index];
                        if (imgBytes.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: GestureDetector(
                            onTap: () {
                              showImageViewer(
                                context,
                                MemoryImage(imgBytes),
                                swipeDismissible: true,
                              );
                            },
                            child: Column(
                              children: [
                                Expanded(
                                  child: Image.memory(imgBytes, fit: BoxFit.contain),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _detections.length > index
                                      ? '${_detections[index]['className'] ?? _detections[index]['class'] ?? 'Unknown'} '
                                      '(${((_detections[index]['confidence'] ?? 0) * 100).toStringAsFixed(1)}%)'
                                      : 'Unknown',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
        drawer:  const AppDrawer(),
    );
    }
    );
  }
}