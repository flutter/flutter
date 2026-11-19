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

/// Number of UI frames (`2`) pumped per state mutation command so both layout
/// and post-frame platform-view registration complete before returning.
const int _kFramesPerStateMutation = 2;

/// Maximum duration (`30` seconds) to wait for a single scheduled frame while
/// pumping forced or normal UI frames.
const Duration _kFramePumpTimeout = Duration(seconds: 30);

/// Logical width and height (`240` dp) of the centered Hybrid Composition
/// Android platform view.
const double _kPlatformViewExtentLogical = 240.0;

/// Logical width (`140` dp) and height (`80` dp) of the translucent Flutter
/// overlay box drawn on top of the Hybrid Composition platform view.
const double _kOverlayWidthLogical = 140.0;
const double _kOverlayHeightLogical = 80.0;

/// Theme definitions encapsulating all colors and typography used by the
/// lifecycle test app (avoiding inlined widget colors or styles).
final ThemeData _kPrimaryLifecycleTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.teal,
    surface: Colors.teal,
    secondaryContainer: Colors.orange.withValues(alpha: 0.85),
    onSecondaryContainer: Colors.black,
  ),
);

final ThemeData _kAlternateLifecycleTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    surface: Colors.indigo,
    secondaryContainer: Colors.amber.withValues(alpha: 0.85),
    onSecondaryContainer: Colors.black,
  ),
);

void main() async {
  ensureAndroidDevice();
  final viewModel = _LifecycleViewModel();
  enableFlutterDriverExtension(
    handler: (String? command) => _handleCommand(viewModel, command),
    commands: <CommandExtension>[nativeDriverCommands],
  );

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(_LifecycleTestApp(viewModel: viewModel));
}

Future<String> _handleCommand(_LifecycleViewModel viewModel, String? command) async {
  if (command == null || command == 'get_state') {
    final Map<String, Object?>? state = await _nativeChannel.invokeMapMethod<String, Object?>(
      'get_hybrid_composition_state',
    );
    return json.encode(state ?? <String, Object?>{});
  }
  if (command == 'show_platform_view') {
    viewModel.setShowPlatformView(true);
    await _pumpFrames(_kFramesPerStateMutation);
    return json.encode(
      await _nativeChannel.invokeMapMethod<String, Object?>('get_hybrid_composition_state') ??
          <String, Object?>{},
    );
  }
  if (command == 'hide_platform_view') {
    viewModel.setShowPlatformView(false);
    await _pumpFrames(_kFramesPerStateMutation);
    return json.encode(
      await _nativeChannel.invokeMapMethod<String, Object?>('get_hybrid_composition_state') ??
          <String, Object?>{},
    );
  }
  if (command == 'toggle_overlay_color') {
    viewModel.toggleOverlayColor();
    await _pumpFrames(_kFramesPerStateMutation);
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
    await _pumpFrames(_kFramesPerStateMutation);
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
    await scheduler.endOfFrame.timeout(_kFramePumpTimeout);
  }
}

final class _LifecycleViewModel extends ChangeNotifier {
  final ValueNotifier<bool> showPlatformView = ValueNotifier<bool>(true);
  final ValueNotifier<bool> alternateOverlayColor = ValueNotifier<bool>(false);

  void setShowPlatformView(bool value) {
    if (showPlatformView.value == value) {
      return;
    }
    showPlatformView.value = value;
    notifyListeners();
  }

  void toggleOverlayColor() {
    alternateOverlayColor.value = !alternateOverlayColor.value;
    notifyListeners();
  }

  @override
  void dispose() {
    showPlatformView.dispose();
    alternateOverlayColor.dispose();
    super.dispose();
  }
}

final class _LifecycleTestApp extends StatelessWidget {
  const _LifecycleTestApp({required this.viewModel});

  final _LifecycleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: viewModel.alternateOverlayColor,
      builder: (BuildContext context, bool useAlternateTheme, Widget? child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: useAlternateTheme ? _kAlternateLifecycleTheme : _kPrimaryLifecycleTheme,
          home: Scaffold(body: _LifecycleScene(viewModel: viewModel)),
        );
      },
    );
  }
}

final class _LifecycleScene extends StatelessWidget {
  const _LifecycleScene({required this.viewModel});

  final _LifecycleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ColoredBox(color: colors.surface),
        ValueListenableBuilder<bool>(
          valueListenable: viewModel.showPlatformView,
          builder: (BuildContext context, bool isVisible, Widget? child) {
            return Visibility(
              visible: isVisible,
              maintainState: true,
              maintainSize: true,
              maintainAnimation: true,
              child: child!,
            );
          },
          child: const _PlatformViewWithOverlay(),
        ),
      ],
    );
  }
}

final class _PlatformViewWithOverlay extends StatelessWidget {
  const _PlatformViewWithOverlay();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const Center(
          child: SizedBox(
            width: _kPlatformViewExtentLogical,
            height: _kPlatformViewExtentLogical,
            child: _HybridCompositionAndroidPlatformView(viewType: 'box_platform_view'),
          ),
        ),
        Center(
          child: ColoredBox(
            color: colors.secondaryContainer,
            child: SizedBox(
              width: _kOverlayWidthLogical,
              height: _kOverlayHeightLogical,
              child: Center(
                child: Text(
                  'HC Overlay',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSecondaryContainer),
                ),
              ),
            ),
          ),
        ),
      ],
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
