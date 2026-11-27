// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:android_driver_extensions/extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import '../src/allow_list_devices.dart';

const MethodChannel _nativeChannel = MethodChannel('native_driver');

void main() async {
  ensureAndroidDevice();
  final controller = _LifecycleAppController();
  enableFlutterDriverExtension(
    handler: (String? command) => _handleCommand(controller, command),
    commands: <CommandExtension>[nativeDriverCommands],
  );

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(_MainApp(controller: controller));
}

Future<String> _handleCommand(_LifecycleAppController controller, String? command) async {
  if (command == null || command == 'get_state') {
    final Map<String, Object?>? state = await _nativeChannel.invokeMapMethod<String, Object?>(
      'get_hybrid_composition_state',
    );
    return json.encode(state ?? <String, Object?>{});
  }
  if (command == 'show_platform_view') {
    controller.setShowPlatformView(true);
    await _pumpFrames(2);
    return json.encode(
      await _nativeChannel.invokeMapMethod<String, Object?>('get_hybrid_composition_state') ??
          <String, Object?>{},
    );
  }
  if (command == 'hide_platform_view') {
    controller.setShowPlatformView(false);
    await _pumpFrames(2);
    return json.encode(
      await _nativeChannel.invokeMapMethod<String, Object?>('get_hybrid_composition_state') ??
          <String, Object?>{},
    );
  }
  if (command == 'toggle_overlay_color') {
    controller.toggleOverlayColor();
    await _pumpFrames(2);
    return json.encode(
      await _nativeChannel.invokeMapMethod<String, Object?>('get_hybrid_composition_state') ??
          <String, Object?>{},
    );
  }
  const resizePrefix = 'resize_flutter_view:';
  if (command.startsWith(resizePrefix)) {
    final int? height = int.tryParse(command.substring(resizePrefix.length));
    final Map<String, Object?>? size = await _nativeChannel.invokeMapMethod<String, Object?>(
      'resize_flutter_view',
      <String, Object?>{'height': height},
    );
    await _pumpFrames(2);
    return json.encode(size ?? <String, Object?>{});
  }
  throw ArgumentError.value(command, 'command', 'Unsupported test command');
}

Future<void> _pumpFrames(int count) async {
  final SchedulerBinding scheduler = SchedulerBinding.instance;
  for (var i = 0; i < count; i++) {
    if (scheduler.framesEnabled) {
      scheduler.scheduleFrame();
    } else {
      scheduler.scheduleForcedFrame();
    }
    await scheduler.endOfFrame.timeout(const Duration(seconds: 30));
  }
}

final class _LifecycleAppController extends ChangeNotifier {
  bool showPlatformView = true;
  bool alternateOverlayColor = false;

  void setShowPlatformView(bool value) {
    if (showPlatformView == value) {
      return;
    }
    showPlatformView = value;
    notifyListeners();
  }

  void toggleOverlayColor() {
    alternateOverlayColor = !alternateOverlayColor;
    notifyListeners();
  }
}

final class _MainApp extends StatelessWidget {
  const _MainApp({required this.controller});

  final _LifecycleAppController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: ListenableBuilder(
          listenable: controller,
          builder: (BuildContext context, Widget? child) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ColoredBox(color: controller.alternateOverlayColor ? Colors.indigo : Colors.teal),
                Visibility(
                  visible: controller.showPlatformView,
                  maintainState: true,
                  maintainSize: true,
                  maintainAnimation: true,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      const Center(
                        child: SizedBox(
                          width: 240,
                          height: 240,
                          child: _HybridCompositionAndroidPlatformView(
                            viewType: 'box_platform_view',
                          ),
                        ),
                      ),
                      Center(
                        child: ColoredBox(
                          color: controller.alternateOverlayColor
                              ? Colors.amber.withValues(alpha: 0.85)
                              : Colors.orange.withValues(alpha: 0.85),
                          child: const SizedBox(
                            width: 140,
                            height: 80,
                            child: Center(
                              child: Text('HC Overlay', style: TextStyle(color: Colors.black)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _HybridCompositionAndroidPlatformView extends StatelessWidget {
  const _HybridCompositionAndroidPlatformView({required this.viewType});

  final String viewType;

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory: (BuildContext context, PlatformViewController controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (PlatformViewCreationParams params) {
        return PlatformViewsService.initExpensiveAndroidView(
            id: params.id,
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParamsCodec: const StandardMessageCodec(),
          )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create();
      },
    );
  }
}
