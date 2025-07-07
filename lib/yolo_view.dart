// lib/yolo_view.dart

import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ultralytics_yolo/utils/logger.dart';
import 'package:ultralytics_yolo/yolo_task.dart';
import 'package:ultralytics_yolo/yolo_streaming_config.dart';

class YOLOViewController {
  MethodChannel? _methodChannel;
  int? _viewId;
  bool get isInitialized => _methodChannel != null;

  void _init(MethodChannel methodChannel, int viewId) {
    _methodChannel = methodChannel;
    _viewId = viewId;
  }
// Add controller methods here if needed, e.g., switchCamera()
}

class YOLOView extends StatefulWidget {
  final String modelPath;
  final YOLOTask task;
  final YOLOViewController? controller;
  final Function(Map<String, dynamic> streamData)? onStreamingData;
  final YOLOStreamingConfig? streamingConfig;

  const YOLOView({
    super.key,
    required this.modelPath,
    required this.task,
    this.controller,
    this.onStreamingData,
    this.streamingConfig,
  });

  @override
  State<YOLOView> createState() => YOLOViewState();
}

class YOLOViewState extends State<YOLOView> {
  late EventChannel _resultEventChannel;
  StreamSubscription<dynamic>? _resultSubscription;
  late MethodChannel _methodChannel;
  late YOLOViewController _effectiveController;
  final String _viewId = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    final resultChannelName = 'com.ultralytics.yolo/detectionResults_$_viewId';
    _resultEventChannel = EventChannel(resultChannelName);
    final controlChannelName = 'com.ultralytics.yolo/controlChannel_$_viewId';
    _methodChannel = MethodChannel(controlChannelName);
    _effectiveController = widget.controller ?? YOLOViewController();
  }

  @override
  void didUpdateWidget(YOLOView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _effectiveController = widget.controller ?? YOLOViewController();
    }
  }

  @override
  void dispose() {
    _resultSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToResults() {
    if (_resultSubscription != null) return; // Already subscribed

    _resultSubscription = _resultEventChannel.receiveBroadcastStream().listen(
          (dynamic event) {
        if (event is Map && widget.onStreamingData != null) {
          widget.onStreamingData!(Map<String, dynamic>.from(event));
        }
      },
      onError: (dynamic error) {
        logInfo('YOLOView: Error on stream: $error. Re-subscribing...');
        // Simple retry logic
        _resultSubscription = null;
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _subscribeToResults();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const viewType = 'com.ultralytics.yolo/YOLOPlatformView';

    final creationParams = <String, dynamic>{
      'viewId': _viewId,
      'modelPath': widget.modelPath,
      'task': widget.task.name,
      if (widget.streamingConfig != null)
        'streamingConfig': {
          'includeOriginalImage': widget.streamingConfig!.includeOriginalImage,
          'maxFPS': widget.streamingConfig!.maxFPS,
        },
    };

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    return const Center(child: Text('Unsupported platform'));
  }

  void _onPlatformViewCreated(int id) {
    _effectiveController._init(_methodChannel, id);
    // Subscribe ONLY after the platform view is created.
    if (widget.onStreamingData != null) {
      _subscribeToResults();
    }
  }
}