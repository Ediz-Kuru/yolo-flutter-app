import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:ultralytics_yolo/yolo_view.dart';
import 'package:ultralytics_yolo_example/presentation/screens/single_image_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'drawer.dart';
import 'l10n/app_localizations.dart';

final GlobalKey _cameraButtonKey = GlobalKey();
final GlobalKey _shareButtonKey = GlobalKey();
final GlobalKey _yoloViewKey = GlobalKey();
final GlobalKey _imageButtonKey = GlobalKey();
final GlobalKey _tutorialKey = GlobalKey();
final ValueNotifier<bool> tutorialActive = ValueNotifier<bool>(true);

// At the top of your main.dart or a relevant scope
final GlobalKey _drawerKey = GlobalKey();
void main() {
  runApp(
    ShowCaseWidget(
      builder: (context) => const MyApp(),
      onFinish: () async {
      tutorialActive.value = false;
      },

      globalFloatingActionWidget: (showcaseContext) => FloatingActionWidget(
        left: 16,
        bottom: 16,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              ShowCaseWidget.of(showcaseContext).dismiss();
              tutorialActive.value = false;
            }
            ,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffEE5366),
            ),
            child: Text(
              AppLocalizations.of(showcaseContext)!.skip,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
      globalTooltipActionConfig: const TooltipActionConfig(
        position: TooltipActionPosition.inside,
        alignment: MainAxisAlignment.spaceBetween,
        actionGap: 20,
      ),
        globalTooltipActions: [
          TooltipActionButton(
            type: TooltipDefaultActionType.previous,
            textStyle: const TextStyle(
              color: Colors.white,
            ),
            hideActionWidgetForShowcase: [_yoloViewKey],
          ),
          TooltipActionButton(
            type: TooltipDefaultActionType.next,
            textStyle: const TextStyle(
              color: Colors.white,
            ),
            hideActionWidgetForShowcase: [_drawerKey],
          ),
        ],
    )
  );
}

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal, // Try indigo, cyan, blueGrey, etc.
          brightness: Brightness.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      navigatorObservers: [routeObserver],
      initialRoute: AppRoutes.mainPage,
      routes: {
        AppRoutes.mainPage: (context) => const YOLODemo(),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ShowCaseWidget.of(context).startShowCase([
          _yoloViewKey,
          _cameraButtonKey,
          _shareButtonKey,
          _tutorialKey,
          _imageButtonKey,
          _drawerKey,
        ]);
      }
    });
  }


  void restartTutorial() async{
    // Option 1: Direct call (Usually works for button presses)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShowCaseWidget.of(context).dismiss();

      if (mounted) { // Always good to check if mounted
        ShowCaseWidget.of(context).dismiss();
        tutorialActive.value = true;
        ShowCaseWidget.of(context).startShowCase([
          _yoloViewKey,
          _cameraButtonKey,
          _shareButtonKey,
          _imageButtonKey,
          _drawerKey,
        ]);
      }
    });
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
    await _yoloViewController.switchModel('yolo11n', YOLOTask.detect);
  }
  Future<void> captureAndShare() async {
    // Capture current frame with overlays
    final imageData = await _yoloViewController.captureFrame();

    if (imageData != null) {
      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/yolo_capture_$timestamp.jpg');
      await file.writeAsBytes(imageData);

      // Share the captured image
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: AppLocalizations.of(context)!.yoloDetectionResult,
        )
      );
    }
  }


  // Define a YOLOViewController to interact with the view if needed.
  // It's good practice even if you don't use it immediately.
  final YOLOViewController _yoloViewController = YOLOViewController();
  bool cameraStop = false;
  bool isLoading = false;
  bool isLoadingShare = false;
  @override
  Widget build(BuildContext context) {
    _yoloViewController.setNumItemsThreshold(300);
        return
        Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.leafDetector),
            leading: Showcase(
              key: _drawerKey,
              title: AppLocalizations.of(context)!.menu,
              description: AppLocalizations.of(context)!.menuDescription,
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
            Showcase(
                key: _tutorialKey,
                title: AppLocalizations.of(context)!.help,
                description: AppLocalizations.of(context)!.helpDescription,
                child: IconButton(onPressed: restartTutorial, icon: const Icon(Icons.help))),
            Showcase(
              key: _imageButtonKey,
              title: AppLocalizations.of(context)!.quickAccess,
              description: AppLocalizations.of(context)!.quickAccessDescription,
              child: IconButton(
                onPressed: () async {
                  await _yoloViewController.stop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SingleImageScreen()),
                  ).then((_) async {
                    await _yoloViewController.start();
                  });
                },
                icon: const Icon(Icons.image),
              ),
            ),
          ],


        ),
          body:
              Showcase(
                key: _yoloViewKey,
                title: AppLocalizations.of(context)!.leafDetectorTitle,
                description: AppLocalizations.of(context)!.leafDetectorDescription,
                child: YOLOView(
                  modelPath: 'yolo11n',
                  task: YOLOTask.detect,
                  controller: _yoloViewController,
                ),
              ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Showcase(
                key: _cameraButtonKey,
                description: 'Click to stop or resume camera',
                child: FloatingActionButton(
                  onPressed: isLoading ? null: () async{
                    if(cameraStop)
                      {
                        setState(() {
                          cameraStop = false;
                          isLoading = true;
                        });
                        await _yoloViewController.start();
                        await _yoloViewController.switchModel('yolo11n', YOLOTask.detect);
                        setState(() {
                          isLoading = false;
                        });
                      }
                    else
                      {
                        setState(() {
                          cameraStop = true;
                          isLoading = true;
                        });
                        await _yoloViewController.stop();
                        setState(() {
                          isLoading = false;
                        });
                      }
                  },
                  child: isLoading ? const CircularProgressIndicator() : Icon(cameraStop ? Icons.videocam_off : Icons.videocam),
                ),
              ),
              Showcase(
                key: _shareButtonKey,
                description: 'Click to share the captured image',
                child: FloatingActionButton(
                  onPressed: isLoadingShare ? null: () async{
                    setState(() {
                      isLoadingShare = true;
                    });
                    await captureAndShare();
                    setState(() {
                      isLoadingShare = false;
                    });
                  },
                  child: const Icon(Icons.share),
                ),
              )
            ],
          ),
      );
  }
}