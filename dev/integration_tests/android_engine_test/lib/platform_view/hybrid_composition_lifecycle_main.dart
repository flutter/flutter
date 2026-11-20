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

/// Number of UI frames (`2`) pumped per standard state mutation command so both
/// layout and post-frame platform-view registration complete before returning.
const int _kFramesPerStateMutation = 2;

/// Single UI frame (`1`) pumped per step during rapid `0 -> 1 -> 0 -> 1`
/// frame-by-frame Hybrid Composition entry/exit toggling.
const int _kSingleFramePump = 1;

/// Maximum duration (`30` seconds) to wait for a single scheduled frame while
/// pumping forced or normal UI frames.
const Duration _kFramePumpTimeout = Duration(seconds: 30);

/// Logical width and height (`180` dp) of each Hybrid Composition Android
/// platform view.
const double _kPlatformViewExtentLogical = 180.0;

/// Logical vertical spacing (`24` dp) separating the primary and secondary
/// stacked Hybrid Composition platform views so their overlay rects remain
/// disjoint.
const double _kPlatformViewSpacingLogical = 24.0;

/// Logical width (`120` dp) and height (`64` dp) of each translucent Flutter
/// overlay box drawn on top of its corresponding platform view.
const double _kOverlayWidthLogical = 120.0;
const double _kOverlayHeightLogical = 64.0;

/// Translucent alpha (`85%`) allowing both the Flutter overlay box and the
/// underlying Hybrid Composition platform view to remain visible.
const double _kOverlayFillAlpha = 0.85;

/// Theme definitions encapsulating all colors and typography used by the
/// lifecycle test app (avoiding inlined widget colors or styles).
final ThemeData _kPrimaryLifecycleTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.teal,
    surface: Colors.teal,
    secondaryContainer: Colors.orange.withValues(alpha: _kOverlayFillAlpha),
    onSecondaryContainer: Colors.black,
  ),
);

final ThemeData _kAlternateLifecycleTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    surface: Colors.indigo,
    secondaryContainer: Colors.amber.withValues(alpha: _kOverlayFillAlpha),
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

Future<Map<String, Object?>> _queryNativeState() async {
  return await _nativeChannel.invokeMapMethod<String, Object?>('get_hybrid_composition_state') ??
      <String, Object?>{};
}

Future<String> _handleCommand(_LifecycleViewModel viewModel, String? command) async {
  if (command == null || command == 'get_state') {
    return json.encode(await _queryNativeState());
  }
  if (command == 'show_platform_view') {
    viewModel.setShowPrimaryPlatformView(true);
    await _pumpFrames(_kFramesPerStateMutation);
    return json.encode(await _queryNativeState());
  }
  if (command == 'hide_platform_view') {
    viewModel.setShowSecondaryPlatformView(false);
    viewModel.setShowPrimaryPlatformView(false);
    await _pumpFrames(_kFramesPerStateMutation);
    return json.encode(await _queryNativeState());
  }
  if (command == 'rapid_show_platform_view') {
    viewModel.setShowPrimaryPlatformView(true);
    await _pumpFrames(_kSingleFramePump);
    return json.encode(await _queryNativeState());
  }
  if (command == 'rapid_hide_platform_view') {
    viewModel.setShowPrimaryPlatformView(false);
    await _pumpFrames(_kSingleFramePump);
    return json.encode(await _queryNativeState());
  }
  if (command == 'show_second_platform_view') {
    viewModel.setShowPrimaryPlatformView(true);
    viewModel.setShowSecondaryPlatformView(true);
    viewModel.setShowSecondaryOverlay(true);
    await _pumpFrames(_kFramesPerStateMutation);
    return json.encode(await _queryNativeState());
  }
  if (command == 'hide_second_overlay_only') {
    viewModel.setShowSecondaryOverlay(false);
    await _pumpFrames(_kFramesPerStateMutation);
    return json.encode(await _queryNativeState());
  }
  if (command == 'hide_second_platform_view') {
    viewModel.setShowSecondaryPlatformView(false);
    viewModel.setShowSecondaryOverlay(true);
    await _pumpFrames(_kFramesPerStateMutation);
    return json.encode(await _queryNativeState());
  }
  if (command == 'toggle_overlay_color') {
    viewModel.toggleOverlayColor();
    await _pumpFrames(_kFramesPerStateMutation);
    return json.encode(await _queryNativeState());
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

final class _LifecycleViewModel {
  final ValueNotifier<bool> showPrimaryPlatformView = ValueNotifier<bool>(true);
  final ValueNotifier<bool> showSecondaryPlatformView = ValueNotifier<bool>(false);
  final ValueNotifier<bool> showSecondaryOverlay = ValueNotifier<bool>(true);
  final ValueNotifier<bool> alternateOverlayColor = ValueNotifier<bool>(false);

  void setShowPrimaryPlatformView(bool value) {
    if (showPrimaryPlatformView.value == value) {
      return;
    }
    showPrimaryPlatformView.value = value;
  }

  void setShowSecondaryPlatformView(bool value) {
    if (showSecondaryPlatformView.value == value) {
      return;
    }
    showSecondaryPlatformView.value = value;
  }

  void setShowSecondaryOverlay(bool value) {
    if (showSecondaryOverlay.value == value) {
      return;
    }
    showSecondaryOverlay.value = value;
  }

  void toggleOverlayColor() {
    alternateOverlayColor.value = !alternateOverlayColor.value;
  }

  void dispose() {
    showPrimaryPlatformView.dispose();
    showSecondaryPlatformView.dispose();
    showSecondaryOverlay.dispose();
    alternateOverlayColor.dispose();
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
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ValueListenableBuilder<bool>(
                valueListenable: viewModel.showPrimaryPlatformView,
                builder: (BuildContext context, bool isVisible, Widget? child) {
                  return Visibility(
                    visible: isVisible,
                    maintainState: true,
                    maintainSize: true,
                    maintainAnimation: true,
                    child: child!,
                  );
                },
                child: const _PlatformViewSlot(label: 'HC Overlay 1'),
              ),
              const SizedBox(height: _kPlatformViewSpacingLogical),
              ValueListenableBuilder<bool>(
                valueListenable: viewModel.showSecondaryPlatformView,
                builder: (BuildContext context, bool isVisible, Widget? child) {
                  if (!isVisible) {
                    return const SizedBox.shrink();
                  }
                  return _SecondaryPlatformViewSlot(viewModel: viewModel);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _SecondaryPlatformViewSlot extends StatelessWidget {
  const _SecondaryPlatformViewSlot({required this.viewModel});

  final _LifecycleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: viewModel.showSecondaryOverlay,
      builder: (BuildContext context, bool showOverlay, Widget? child) {
        return _PlatformViewSlot(label: 'HC Overlay 2', showOverlay: showOverlay);
      },
    );
  }
}

final class _PlatformViewSlot extends StatelessWidget {
  const _PlatformViewSlot({required this.label, this.showOverlay = true});

  final String label;
  final bool showOverlay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kPlatformViewExtentLogical,
      height: _kPlatformViewExtentLogical,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          const SizedBox.expand(
            child: _HybridCompositionAndroidPlatformView(viewType: 'box_platform_view'),
          ),
          if (showOverlay) _OverlayBadge(label: label),
        ],
      ),
    );
  }
}

final class _OverlayBadge extends StatelessWidget {
  const _OverlayBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return ColoredBox(
      color: colors.secondaryContainer,
      child: SizedBox(
        width: _kOverlayWidthLogical,
        height: _kOverlayHeightLogical,
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSecondaryContainer),
          ),
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
