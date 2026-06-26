// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'backdrop_filter_blur.dart';
import 'goldens.dart';
import 'image_drawing_canvas.dart';
import 'platform_view.dart';
import 'src/messages.g.dart';
import 'test_scenario_extension.dart';
import 'text_drawing_canvas.dart';
import 'vector_drawings_canvas.dart';

const String _keyMessage = 'message';
const String _keyReason = 'reason';
const String _keyX = 'x';
const String _keyY = 'y';
const String _keyWidth = 'width';
const String _keyHeight = 'height';
const String _keyImageBytes = 'imageBytes';

/// The global key identifying the target [RepaintBoundary] for golden screenshot capturing.
final GlobalKey targetKey = GlobalKey();

class SmokeTestCoordinator implements SmokeTestFlutterApi {
  static final SmokeTestCoordinator instance = SmokeTestCoordinator();
  SmokeTestFlutterApi? delegate;

  @override
  Future<RenderReply> renderTest(RenderRequest request) async {
    final SmokeTestFlutterApi? delegate = this.delegate;
    if (delegate == null) {
      throw StateError('No active SmokeTestFlutterApi delegate registered.');
    }
    return delegate.renderTest(request);
  }

  @override
  Future<CompareGoldenReply> compareGolden(CompareGoldenRequest request) async {
    final SmokeTestFlutterApi? delegate = this.delegate;
    if (delegate == null) {
      throw StateError('No active SmokeTestFlutterApi delegate registered.');
    }
    return delegate.compareGolden(request);
  }
}

void main() async {
  // Required to allow registering Pigeon API message handlers before runApp is called.
  WidgetsFlutterBinding.ensureInitialized();
  SmokeTestFlutterApi.setUp(SmokeTestCoordinator.instance);
  runApp(const MyApp());
}

/// The root application widget for the Android hardware smoke test.
class MyApp extends StatelessWidget {
  const MyApp({super.key, this.imageLoader = defaultImageLoader});

  /// The callback used to lazily fetch image texture assets during test runs.
  final ImageLoader imageLoader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter android hardware smoke test',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: MyWidget(imageLoader: imageLoader),
    );
  }
}

/// A stateful widget rendering vector drawings, blur effects, or platform views based on test driver requests.
class MyWidget extends StatefulWidget {
  const MyWidget({super.key, required this.imageLoader});

  /// The callback used to lazily fetch image texture assets during test runs.
  final ImageLoader imageLoader;

  @override
  State<MyWidget> createState() => _MyState();
}

class _MyState extends State<MyWidget> implements SmokeTestFlutterApi {
  String _message = 'Waiting for message...';
  TestScenario? _activeScenario;
  late Future<String?> _goldenVariantFuture;
  ui.Image? _loadedImage;
  Completer<void>? _platformViewCreatedCompleter;

  Future<ui.Image> _loadImage() async {
    return widget.imageLoader();
  }

  @override
  Future<CompareGoldenReply> compareGolden(CompareGoldenRequest request) async {
    // Handle the out-of-band comparison request. This is triggered by the on-device test runner
    // once it has captured and cropped the platform view screenshot using UiAutomation.
    final Uint8List imageBytes = request.imageBytes;
    final String? goldenVariantValue = await _goldenVariantFuture;
    final String testName = request.scenario.testName;

    final String? failureMessage = await compareGoldenOnDevice(
      testName,
      imageBytes,
      goldenVariantValue,
    );

    return CompareGoldenReply(message: failureMessage ?? 'Comparison Success');
  }

  @override
  Future<RenderReply> renderTest(RenderRequest request) async {
    final TestScenario scenario = request.scenario;
    final bool performAppSideGoldenCompare = request.performAppSideGoldenCompare;
    final bool captureScreenshot = request.captureScreenshot;

    final String testName = scenario.testName;

    if (scenario == TestScenario.platformViewHybridCompositionPlusPlus) {
      final bool isHcpp = await HybridAndroidViewController.checkIfSupported();
      if (!isHcpp) {
        return RenderReply(
          message: 'Skipped',
          reason:
              'HCPP is not supported on this device/configuration (requires Vulkan and Android 14+)',
        );
      }
    }

    // Lazily load the image asset only when requested. This avoids loading it
    // unnecessarily, blocks rendering until fully loaded, and catches load
    // failures to explicitly fail the host-side driver test.
    if (scenario == TestScenario.image && _loadedImage == null) {
      try {
        final ui.Image img = await _loadImage();
        if (!mounted) {
          img.dispose();
          return RenderReply(message: 'Widget unmounted during image load');
        }
        setState(() {
          _loadedImage = img;
        });
      } catch (e, stackTrace) {
        return RenderReply(message: 'Failed to load image asset: $e\n$stackTrace');
      }
    }

    final completer = Completer<RenderReply>();

    final bool isPlatformView = scenario.name.startsWith('platformView');
    if (isPlatformView) {
      _platformViewCreatedCompleter = Completer<void>();
    } else {
      _platformViewCreatedCompleter = null;
    }

    setState(() {
      _activeScenario = scenario;
      _message = testName;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (captureScreenshot) {
        final replyCompleter = Completer<Map<String, Object?>>();
        handleGoldenRequest(
          testName,
          replyCompleter,
          performAppSideGoldenCompare,
          targetKey,
          _goldenVariantFuture,
          settleFuture: _platformViewCreatedCompleter?.future,
        );
        replyCompleter.future
            .then((result) {
              final base64Str = result[_keyImageBytes] as String?;
              final Uint8List? imageBytes = base64Str != null ? base64.decode(base64Str) : null;
              completer.complete(
                RenderReply(
                  message: result[_keyMessage]! as String,
                  reason: result[_keyReason] as String?,
                  x: result[_keyX] as int?,
                  y: result[_keyY] as int?,
                  width: result[_keyWidth] as int?,
                  height: result[_keyHeight] as int?,
                  imageBytes: imageBytes,
                ),
              );
            })
            .catchError((Object error) {
              completer.complete(RenderReply(message: 'Error handling golden request: $error'));
            });
      } else {
        completer.complete(RenderReply(message: 'Rendered $testName'));
      }
    }, debugLabel: 'Rendered $testName');

    return completer.future;
  }

  @override
  void initState() {
    super.initState();
    _goldenVariantFuture = NativeSupportApi().getImpellerBackend();
    SmokeTestCoordinator.instance.delegate = this;
  }

  @override
  void dispose() {
    _loadedImage?.dispose();
    SmokeTestCoordinator.instance.delegate = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void onPlatformViewCreated() {
      if (_platformViewCreatedCompleter?.isCompleted == false) {
        _platformViewCreatedCompleter?.complete();
      }
    }

    final Widget testContent = switch (_activeScenario) {
      TestScenario.backdropFilterBlur => const BackdropFilterBlur(),
      TestScenario.platformViewTextureLayer => AndroidPlatformView(
        mode: PlatformViewMode.textureLayer,
        onCreated: onPlatformViewCreated,
      ),
      TestScenario.platformViewHybridComposition => AndroidPlatformView(
        mode: PlatformViewMode.hybridComposition,
        onCreated: onPlatformViewCreated,
      ),
      TestScenario.platformViewHybridCompositionPlusPlus => AndroidPlatformView(
        mode: PlatformViewMode.hybridCompositionPlusPlus,
        onCreated: onPlatformViewCreated,
      ),
      TestScenario.text => const TextDrawingCanvas(),
      TestScenario.image => ImageDrawingCanvas(image: _loadedImage),
      _ => VectorDrawingsCanvas(scenario: _activeScenario),
    };

    return SafeArea(
      child: Stack(
        children: <Widget>[
          RepaintBoundary(
            key: targetKey,
            child: SizedBox(width: 150, height: 150, child: testContent),
          ),
          Align(child: Text(_message)),
        ],
      ),
    );
  }
}
