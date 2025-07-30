// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'dart:io';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:image/image.dart' as img;

import 'package:geolocator/geolocator.dart'; // Pour le GPS
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:ultralytics_yolo_example/drawer.dart';
import 'package:ultralytics_yolo_example/l10n/app_localizations.dart';

import '../../waqi.dart';

class SingleImageScreen extends StatefulWidget {
  const SingleImageScreen({super.key});

  @override
  State<SingleImageScreen> createState() => _SingleImageScreenState();
}

class _SingleImageScreenState extends State<SingleImageScreen> {
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _detections = [];
  Uint8List? _imageBytes;
  Uint8List? _annotatedImage;
  AirQualityData? _airQualityData;
  bool _isLoadingAQ = true;
  String? _errorMessageAQ;
  final String _apiKey = '30c439655961e0b68355453e7665cdfebbfd51cb';


  late YOLO _yolo;
  final String _modelPathForYOLO =
      'yolo11n'; // Default asset path for non-iOS or if local copy fails
  bool _isModelReady = false;

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

  Future<void> _initializeYOLO() async {

    _yolo = YOLO(
      modelPath: _modelPathForYOLO,
      task: YOLOTask.detect,
      useMultiInstance: true,
    );

    try {
      await _yolo.loadModel();
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


  String analyzeAQIAndDiseaseLink(int? aqi) {
    if (aqi == null) return AppLocalizations.of(context)!.aqiAnalysisUnknown;

    String quality;
    double probability;

    if (aqi <= 50) {
      quality = AppLocalizations.of(context)!.airQualityGood;
      probability = 0.05;
    } else if (aqi <= 100) {
      quality = AppLocalizations.of(context)!.airQualityModerate;
      probability = 0.10;
    } else if (aqi <= 150) {
      quality = AppLocalizations.of(context)!.airQualityUnhealthySensitive;
      probability = 0.25;
    } else if (aqi <= 200) {
      quality = AppLocalizations.of(context)!.airQualityUnhealthy;
      probability = 0.45;
    } else if (aqi <= 300) {
      quality = AppLocalizations.of(context)!.airQualityVeryUnhealthy;
      probability = 0.65;
    } else {
      quality = AppLocalizations.of(context)!.airQualityHazardous;
      probability = 0.85;
    }
    return AppLocalizations.of(context)!.aqiAnalysisPattern(aqi, (probability * 100).toStringAsFixed(0), quality);

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

        } else {
          _detections = [];
          _croppedImages = [];
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
  BuildContext? myContext;
  @override
  void initState() {
    super.initState();
    _initializeYOLO();
    _fetchAirQualityData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (myContext != null && mounted) {
        ShowCaseWidget.of(myContext!).startShowCase([
          _keyResult,
          _keyLoca,
          _keyReload,
          _keyInfo,
        ]);
      }
    });


  }

  @override
  Widget build(BuildContext context) {
      myContext = context;
      return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.singleImageDetectionTitle),
        actions: [
          IconButton(
            icon: Showcase(
                key: _keyInfo,
                targetPadding: const EdgeInsets.all(8),
                description: AppLocalizations.of(context)!.helpButtonTooltip,
                targetShapeBorder: const CircleBorder(),
                child: const Icon(Icons.help_outline)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Aide'),
                    content:
                    Text(AppLocalizations.of(context)!.helpDialogContent),
                    actions: [
                      TextButton(
                        child: Text(AppLocalizations.of(context)!.helpDialogClose),
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
                description: AppLocalizations.of(context)!.reloadAirQualityTooltip,
                targetShapeBorder: const CircleBorder(),

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

                  description: AppLocalizations.of(context)!.locationEnabledDescription,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Text(
                            AppLocalizations.of(context)!.airQualityLabel,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline, size: 20),
                            tooltip: AppLocalizations.of(context)!.airQualityHelpTooltip,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(AppLocalizations.of(context)!.airQualityDialogTitle),
                                  content: Text(AppLocalizations.of(context)!.airQualityDialogContent),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text(AppLocalizations.of(context)!.airQualityDialogClose),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Text(
                          AppLocalizations.of(context)!.location + " : ${_airQualityData!.city?.name ?? AppLocalizations.of(context)!.locationUnknown}"
                      ),
                      Text(
                          'AQI : ${_airQualityData!.aqi ?? AppLocalizations.of(context)!.aqiUnavailable}'
                      ),

                      const SizedBox(height: 8),
                      Text(AppLocalizations.of(context)!.pollutantsLabel),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
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
                description: AppLocalizations.of(context)!.selectImageDescription,
                targetShapeBorder: const CircleBorder(),
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
                  children:  [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 10),
                    Text(AppLocalizations.of(context)!.modelLoading),
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


            const SizedBox(height: 10),

            if (_croppedImages.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context)!.detectionsTitle),
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
                                      ? '${_detections[index]['className'] ?? _detections[index]['class'] ?? AppLocalizations.of(context)!.locationUnknown} '
                                      '(${((_detections[index]['confidence'] ?? 0) * 100).toStringAsFixed(1)}%)'
                                      : AppLocalizations.of(context)!.locationUnknown,
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
}