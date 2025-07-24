import 'dart:async';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:ultralytics_yolo/yolo_streaming_config.dart';
import 'package:ultralytics_yolo/yolo_view.dart';
import 'package:ultralytics_yolo_example/presentation/screens/single_image_screen.dart';
import 'package:ultralytics_yolo_example/waqi.dart';

import 'drawer.dart';

void main() => runApp( MyApp());
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class MyApp extends StatelessWidget {
  MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      initialRoute: AppRoutes.mainPage,
      routes: {
        AppRoutes.mainPage: (context) => const YOLODemo(),
        AppRoutes.waqiPage: (context) => const AirQualityPage(),
        AppRoutes.singleImagePage: (context) => const SingleImageScreen(),
      },
    );
  }
}
class YOLODemo extends StatefulWidget {
  const YOLODemo({super.key});
  @override
  _YOLODemoState createState() => _YOLODemoState();
}

class _YOLODemoState extends State<YOLODemo> with RouteAware{
  // The classifier instance for processing frames received from the stream.

  final _keyQuestion = GlobalKey();
  final _keyResults = GlobalKey();
  final _keySecPage = GlobalKey();

  YOLO classifier = YOLO(
    modelPath: 'yolo11n-cls',
    task: YOLOTask.classify,
      useMultiInstance:true
  );
  // State variables
  List<dynamic> _classificationResults = [];
  bool _isLoading = true;
  bool _isProcessingFrame = false;

  // Add a stopwatch to measure performance
  final Stopwatch _stopwatch = Stopwatch();
  int _processingTimeMs = 0;

  @override
  void initState() {
    super.initState();
    // We only load the model now. Subscription happens after the view is created.
    loadYOLOModel();
    WidgetsBinding.instance!.addPostFrameCallback(
        (_) => ShowCaseWidget.of(context)!.startShowCase([_keyResults, _keyQuestion, _keySecPage])
    );

  }
  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }
  @override
  Future<void> didPushNext()
  async {
    await _yoloViewController.stop();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  Future<void> didPopNext() async {
    // Coming back to this page
    await _yoloViewController.start();
    await loadYOLOModel();
  }

  Future<void> loadYOLOModel() async {
    setState(() => _isLoading = true);
    await classifier.loadModel();
    setState(() => _isLoading = false);
  }
  /// Processes a single frame from the camera stream.
  Future<void> _processFrame(Uint8List imageData) async {
    if(_isProcessingFrame) return;
    _isProcessingFrame = true;
    _stopwatch.reset();
    _stopwatch.start();
    final results = await classifier.predict(imageData);
    _stopwatch.stop();
      if (mounted) {
        setState(() {
          _classificationResults = results['detections'] ?? [];
          _processingTimeMs = _stopwatch.elapsedMilliseconds;
        });
      }
    _isProcessingFrame = false;
  }

  // Define a YOLOViewController to interact with the view if needed.
  // It's good practice even if you don't use it immediately.
  YOLOViewController _yoloViewController = YOLOViewController();

  @override
  Widget build(BuildContext context) {
        return
        Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('YOLO Live Classification'),
          leading: Showcase(
            key: _keySecPage,
            description: "Clique ici pour ouvrir le menu de navigation",
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
                  key: _keyQuestion,
                  targetPadding: const EdgeInsets.all(8),
                  description: "Plus d'informations sur le fonctionnement de la page.",
                  targetShapeBorder: const CircleBorder(),
                  tooltipBackgroundColor: Colors.blueAccent,
                  child: const Icon(Icons.help_outline)
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Aide'),
                      content: const Text(
                        'Cette application utilise un modèle YOLO pour classifier en temps réel ce que la caméra peut voir.\n\n'
                            '1- Veuillez accepter les permissions de caméra afin que l’application puisse fonctionner correctement. \n'
                            '2- Pointez votre caméra vers une feuille afin qu’elle soit détectée et analysée. Il se peut qu’une feuille ne soit pas détectée du premier coup. \n'
                            '3- Lorsqu’une feuille est détectée, des boites apparaitront de celle-ci. D’autres apparaitront aussi autour des traces de maladies sur la feuilles. Le % affiché est la certitude du résultat.\n'
                            '4- En bas est affiché le nom de la maladie détectée et sa certitude. \n.'
                            ,
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
              onPressed: () async {
                await _yoloViewController.stop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SingleImageScreen()),
                ).then((_) async {
                  await _yoloViewController.start();
                  await loadYOLOModel();
                });
              },
              icon: const Icon(Icons.image),
            ),
          ],


        ),
    body: Column(
    children: [
    Expanded(
    flex: 3,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : YOLOView(
                // We pass a key to ensure the widget is properly rebuilt if needed.
                key: ValueKey(classifier.instanceId),
                modelPath: 'yolo11n',
                task: YOLOTask.detect,
                controller: _yoloViewController,
                streamingConfig: YOLOStreamingConfig.throttled(
                  maxFPS: 10,
                  includeOriginalImage: true,
                ),
                // The onStreamingData callback is the most direct way to get frame data.
                onStreamingData: (data) {
                  final image = data['originalImage'] as Uint8List?;
                  if (image != null) {
                    _processFrame(image);
                  }
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.black,
                width: double.infinity,
                child: Center(
                  child: Showcase(
                    key: _keyResults,
                    title: "Résultat",
                    description: "Affiche la classe de l'objet détecté, ainsi que le % de confiance.",
                    showArrow: true,
                    tooltipBackgroundColor: Colors.blueAccent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Live Classification Result',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_classificationResults.isNotEmpty)
                          Text(
                            'Class: ${_classificationResults.first['className']}\n'
                                'Confidence: ${(_classificationResults.first['confidence'] * 100).toStringAsFixed(1)}%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.lightGreenAccent,
                              fontSize: 18,
                            ),
                          )
                        else
                          const Text(
                            'Detecting...',
                            style: TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          'Processing Time: $_processingTimeMs ms',
                          style: const TextStyle(color: Colors.amber, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
          drawer: const AppDrawer(),
      );

  }
}