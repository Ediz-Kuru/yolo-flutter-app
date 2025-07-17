// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:image/image.dart' as img;


/// A screen that demonstrates YOLO inference on a single image.
///
/// This screen allows users to:
/// - Pick an image from the gallery
/// - Run YOLO inference on the selected image
/// - View detection results and annotated image
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





  @override
  void initState() {
    super.initState();
    _initializeYOLO();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Single Image Inference'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _pickAndPredict,
              child: const Text('Pick Image & Run Inference'),
            ),
          ),

          const SizedBox(height: 10),
          if (!_isModelReady && Platform.isIOS)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 10),
                  Text("Preparing local model..."),
                ],
              ),
            )
          else if (!_isModelReady)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 10),
                  Text("Model loading..."),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [


                  if (_annotatedImage != null)
                    SizedBox(
                      height: 300,
                      width: double.infinity,
                      //child: Image.memory(_annotatedImage!),
                      child: GestureDetector(
                        onTap: () {
                          showImageViewer(context, MemoryImage(_annotatedImage!),
                              swipeDismissible: false);
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

                  /*const Text('Detections:'),
                  ..._detections.map((d) {
                    final rawName = d['className'] ?? d['class'] ?? 'Unknown';
                    final className = rawName.toString(); // on le force à String
                    final confidence = d['confidence'] != null
                        ? (d['confidence'] * 100).toStringAsFixed(1)
                        : '?';
                    return Text('$className ($confidence%)');
                  }),*/



                  if (_croppedImages.isNotEmpty)
                    Column(
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
                              if (imgBytes.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: GestureDetector(
                                  onTap: () {
                                    showImageViewer(context, MemoryImage(imgBytes),
                                        swipeDismissible: true);
                                  },
                                  //child: Image.memory(imgBytes, fit: BoxFit.contain),
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

                  SizedBox(height: 12),

                  const Text('Classifications:'),
                  ..._classifications.map((d) {
                    final rawName = d['className'] ?? d['class'] ?? 'Unknown';
                    final className = rawName.toString(); // on le force à String
                    final confidence = d['confidence'] != null
                        ? (d['confidence'] * 100).toStringAsFixed(1)
                        : '?';
                    return Text('$className ($confidence%)');
                  }),


                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
