// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'message_codec.dart';
import 'system_channels.dart';

/// Converts a given point from the global coordinate system in logical pixels
/// to the local coordinate system for a box.
///
/// Used by [AndroidViewController.pointTransformer].
typedef PointTransformer = Offset Function(Offset position);

/// The [PlatformViewsRegistry] responsible for generating unique identifiers for platform views.
final PlatformViewsRegistry platformViewsRegistry = PlatformViewsRegistry._instance();

/// A registry responsible for generating unique identifier for platform views.
///
/// A Flutter application has a single [PlatformViewsRegistry] which can be accesses
/// through the [platformViewsRegistry] getter.
class PlatformViewsRegistry {
  PlatformViewsRegistry._instance();

  // Always non-negative. The id value -1 is used in the accessibility bridge
  // to indicate the absence of a platform view.
  int _nextPlatformViewId = 0;

  /// Allocates a unique identifier for a platform view.
  ///
  /// A platform view identifier can refer to a platform view that was never created,
  /// a platform view that was disposed, or a platform view that is alive.
  ///
  /// Typically a platform view identifier is passed to a platform view widget
  /// which creates the platform view and manages its lifecycle.
  int getNextPlatformViewId() => _nextPlatformViewId++;
}

/// Callback signature for when a platform view was created.
///
/// `id` is the platform view's unique identifier.
typedef PlatformViewCreatedCallback = void Function(int id);

/// Provides access to the platform views service.
///
/// This service allows creating and controlling platform-specific views.
class PlatformViewsService {
  PlatformViewsService._() {
    SystemChannels.platform_views.setMethodCallHandler(_onMethodCall);
  }

  static final PlatformViewsService _instance = PlatformViewsService._();

  Future<void> _onMethodCall(MethodCall call) {
    switch(call.method) {
      case 'viewFocused':
        final int id = call.arguments as int;
        if (_focusCallbacks.containsKey(id)) {
          _focusCallbacks[id]!();
        }
        break;
      default:
        throw UnimplementedError("${call.method} was invoked but isn't implemented by PlatformViewsService");
    }
    return Future<void>.value();
  }

  /// Maps platform view IDs to focus callbacks.
  ///
  /// The callbacks are invoked when the platform view asks to be focused.
  final Map<int, VoidCallback> _focusCallbacks = <int, VoidCallback>{};

  /// {@template flutter.services.PlatformViewsService.initAndroidView}
  /// Creates a controller for a new Android view.
  ///
  /// `id` is an unused unique identifier generated with [platformViewsRegistry].
  ///
  /// `viewType` is the identifier of the Android view type to be created, a
  /// factory for this view type must have been registered on the platform side.
  /// Platform view factories are typically registered by plugin code.
  /// Plugins can register a platform view factory with
  /// [PlatformViewRegistry#registerViewFactory](/javadoc/io/flutter/plugin/platform/PlatformViewRegistry.html#registerViewFactory-java.lang.String-io.flutter.plugin.platform.PlatformViewFactory-).
  ///
  /// `creationParams` will be passed as the args argument of [PlatformViewFactory#create](/javadoc/io/flutter/plugin/platform/PlatformViewFactory.html#create-android.content.Context-int-java.lang.Object-)
  ///
  /// `creationParamsCodec` is the codec used to encode `creationParams` before sending it to the
  /// platform side. It should match the codec passed to the constructor of [PlatformViewFactory](/javadoc/io/flutter/plugin/platform/PlatformViewFactory.html#PlatformViewFactory-io.flutter.plugin.common.MessageCodec-).
  /// This is typically one of: [StandardMessageCodec], [JSONMessageCodec], [StringCodec], or [BinaryCodec].
  ///
  /// `onFocus` is a callback that will be invoked when the Android View asks to get the
  /// input focus.
  ///
  /// The Android view will only be created after [AndroidViewController.setSize] is called for the
  /// first time.
  ///
  /// The `id, `viewType, and `layoutDirection` parameters must not be null.
  /// If `creationParams` is non null then `creationParamsCodec` must not be null.
  /// {@endtemplate}
  static AndroidViewController initAndroidView({
    required int id,
    required String viewType,
    required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic>? creationParamsCodec,
    VoidCallback? onFocus,
  }) {
    assert(id != null);
    assert(viewType != null);
    assert(layoutDirection != null);
    assert(creationParams == null || creationParamsCodec != null);

    final TextureAndroidViewController controller = TextureAndroidViewController._(
      viewId: id,
      viewType: viewType,
      layoutDirection: layoutDirection,
      creationParams: creationParams,
      creationParamsCodec: creationParamsCodec,
    );

    _instance._focusCallbacks[id] = onFocus ?? () {};
    return controller;
  }

  /// {@macro flutter.services.PlatformViewsService.initAndroidView}
  ///
  /// Alias for [initAndroidView].
  /// This factory is provided for backward compatibility purposes.
  /// In the future, this method will be deprecated.
  static SurfaceAndroidViewController initSurfaceAndroidView({
    required int id,
    required String viewType,
    required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic>? creationParamsCodec,
    VoidCallback? onFocus,
  }) {
    assert(id != null);
    assert(viewType != null);
    assert(layoutDirection != null);
    assert(creationParams == null || creationParamsCodec != null);

    final SurfaceAndroidViewController controller = SurfaceAndroidViewController._(
      viewId: id,
      viewType: viewType,
      layoutDirection: layoutDirection,
      creationParams: creationParams,
      creationParamsCodec: creationParamsCodec,
    );
    _instance._focusCallbacks[id] = onFocus ?? () {};
    return controller;
  }

  /// {@macro flutter.services.PlatformViewsService.initAndroidView}
  ///
  /// When this factory is used, the Android view and Flutter widgets are composed at the
  /// Android view hierarchy level.
  /// This is only useful if the view is a Android SurfaceView. However, using this method
  /// has a performance cost on devices that run below 10, or underpowered devices.
  /// In most situations, you should use [initAndroidView].
  static ExpensiveAndroidViewController initExpensiveAndroidView({
    required int id,
    required String viewType,
    required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic>? creationParamsCodec,
    VoidCallback? onFocus,
  }) {
    final ExpensiveAndroidViewController controller = ExpensiveAndroidViewController._(
      viewId: id,
      viewType: viewType,
      layoutDirection: layoutDirection,
      creationParams: creationParams,
      creationParamsCodec: creationParamsCodec,
    );

    _instance._focusCallbacks[id] = onFocus ?? () {};
    return controller;
  }

  /// Whether the render surface of the Android `FlutterView` should be converted to a `FlutterImageView`.
  @Deprecated(
    'No longer necessary to improve performance. '
    'This feature was deprecated after v2.11.0-0.1.pre.',
  )
  static Future<void> synchronizeToNativeViewHierarchy(bool yes) async {}

  // TODO(amirh): reference the iOS plugin API for registering a UIView factory once it lands.
  /// This is work in progress, not yet ready to be used, and requires a custom engine build. Creates a controller for a new iOS UIView.
  ///
  /// `id` is an unused unique identifier generated with [platformViewsRegistry].
  ///
  /// `viewType` is the identifier of the iOS view type to be created, a
  /// factory for this view type must have been registered on the platform side.
  /// Platform view factories are typically registered by plugin code.
  ///
  /// The `id, `viewType, and `layoutDirection` parameters must not be null.
  /// If `creationParams` is non null then `creationParamsCodec` must not be null.
  static Future<UiKitViewController> initUiKitView({
    required int id,
    required String viewType,
    required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic>? creationParamsCodec,
  }) async {
    assert(id != null);
    assert(viewType != null);
    assert(layoutDirection != null);
    assert(creationParams == null || creationParamsCodec != null);

    // TODO(amirh): pass layoutDirection once the system channel supports it.
    final Map<String, dynamic> args = <String, dynamic>{
      'id': id,
      'viewType': viewType,
    };
    if (creationParams != null) {
      final ByteData paramsByteData = creationParamsCodec!.encodeMessage(creationParams)!;
      args['params'] = Uint8List.view(
        paramsByteData.buffer,
        0,
        paramsByteData.lengthInBytes,
      );
    }
    await SystemChannels.platform_views.invokeMethod<void>('create', args);
    return UiKitViewController._(id, layoutDirection);
  }
}

/// Properties of an Android pointer.
///
/// A Dart version of Android's [MotionEvent.PointerProperties](https://developer.android.com/reference/android/view/MotionEvent.PointerProperties).
class AndroidPointerProperties {
  /// Creates an [AndroidPointerProperties] object.
  ///
  /// All parameters must not be null.
  const AndroidPointerProperties({
    required this.id,
    required this.toolType,
  }) : assert(id != null),
       assert(toolType != null);

  /// See Android's [MotionEvent.PointerProperties#id](https://developer.android.com/reference/android/view/MotionEvent.PointerProperties.html#id).
  final int id;

  /// The type of tool used to make contact such as a finger or stylus, if known.
  /// See Android's [MotionEvent.PointerProperties#toolType](https://developer.android.com/reference/android/view/MotionEvent.PointerProperties.html#toolType).
  final int toolType;

  /// Value for `toolType` when the tool type is unknown.
  static const int kToolTypeUnknown = 0;

  /// Value for `toolType` when the tool type is a finger.
  static const int kToolTypeFinger = 1;

  /// Value for `toolType` when the tool type is a stylus.
  static const int kToolTypeStylus = 2;

  /// Value for `toolType` when the tool type is a mouse.
  static const int kToolTypeMouse = 3;

  /// Value for `toolType` when the tool type is an eraser.
  static const int kToolTypeEraser = 4;

  List<int> _asList() => <int>[id, toolType];

  @override
  String toString() {
    return '${objectRuntimeType(this, 'AndroidPointerProperties')}(id: $id, toolType: $toolType)';
  }
}

/// Position information for an Android pointer.
///
/// A Dart version of Android's [MotionEvent.PointerCoords](https://developer.android.com/reference/android/view/MotionEvent.PointerCoords).
class AndroidPointerCoords {
  /// Creates an AndroidPointerCoords.
  ///
  /// All parameters must not be null.
  const AndroidPointerCoords({
    required this.orientation,
    required this.pressure,
    required this.size,
    required this.toolMajor,
    required this.toolMinor,
    required this.touchMajor,
    required this.touchMinor,
    required this.x,
    required this.y,
  }) : assert(orientation != null),
       assert(pressure != null),
       assert(size != null),
       assert(toolMajor != null),
       assert(toolMinor != null),
       assert(touchMajor != null),
       assert(touchMinor != null),
       assert(x != null),
       assert(y != null);

  /// The orientation of the touch area and tool area in radians clockwise from vertical.
  ///
  /// See Android's [MotionEvent.PointerCoords#orientation](https://developer.android.com/reference/android/view/MotionEvent.PointerCoords.html#orientation).
  final double orientation;

  /// A normalized value that describes the pressure applied to the device by a finger or other tool.
  ///
  /// See Android's [MotionEvent.PointerCoords#pressure](https://developer.android.com/reference/android/view/MotionEvent.PointerCoords.html#pressure).
  final double pressure;

  /// A normalized value that describes the approximate size of the pointer touch area in relation to the maximum detectable size of the device.
  ///
  /// See Android's [MotionEvent.PointerCoords#size](https://developer.android.com/reference/android/view/MotionEvent.PointerCoords.html#size).
  final double size;

  /// See Android's [MotionEvent.PointerCoords#toolMajor](https://developer.android.com/reference/android/view/MotionEvent.PointerCoords.html#toolMajor).
  final double toolMajor;

  /// See Android's [MotionEvent.PointerCoords#toolMinor](https://developer.android.com/reference/android/view/MotionEvent.PointerCoords.html#toolMinor).
  final double toolMinor;

  /// See Android's [MotionEvent.PointerCoords#touchMajor](https://developer.android.com/reference/android/view/MotionEvent.PointerCoords.html#touchMajor).
  final double touchMajor;

  /// See Android's [MotionEvent.PointerCoords#touchMinor](https://developer.android.com/reference/android/view/MotionEvent.PointerCoords.html#touchMinor).
  final double touchMinor;

  /// The X component of the pointer movement.
  ///
  /// See Android's [MotionEvent.PointerCoords#x](https://developer.android.com/reference/android/view/MotionEvent.PointerCoords.html#x).
  final double x;

  /// The Y component of the pointer movement.
  ///
  /// See Android's [MotionEvent.PointerCoords#y](https://developer.android.com/reference/android/view/MotionEvent.PointerCoords.html#y).
  final double y;

  List<double> _asList() {
    return <double>[
      orientation,
      pressure,
      size,
      toolMajor,
      toolMinor,
      touchMajor,
      touchMinor,
      x,
      y,
    ];
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, 'AndroidPointerCoords')}(orientation: $orientation, pressure: $pressure, size: $size, toolMajor: $toolMajor, toolMinor: $toolMinor, touchMajor: $touchMajor, touchMinor: $touchMinor, x: $x, y: $y)';
  }
}

/// A Dart version of Android's [MotionEvent](https://developer.android.com/reference/android/view/MotionEvent).
///
/// This is used by [AndroidViewController] to describe pointer events that are forwarded to a platform view
/// when Flutter receives an event that it determines is to be handled by that platform view rather than by
/// another Flutter widget.
///
/// See also:
///
///  * [AndroidViewController.sendMotionEvent], which can be used to send an [AndroidMotionEvent] explicitly.
class AndroidMotionEvent {
  /// Creates an AndroidMotionEvent.
  ///
  /// All parameters must not be null.
  AndroidMotionEvent({
    required this.downTime,
    required this.eventTime,
    required this.action,
    required this.pointerCount,
    required this.pointerProperties,
    required this.pointerCoords,
    required this.metaState,
    required this.buttonState,
    required this.xPrecision,
    required this.yPrecision,
    required this.deviceId,
    required this.edgeFlags,
    required this.source,
    required this.flags,
    required this.motionEventId,
  }) : assert(downTime != null),
       assert(eventTime != null),
       assert(action != null),
       assert(pointerCount != null),
       assert(pointerProperties != null),
       assert(pointerCoords != null),
       assert(metaState != null),
       assert(buttonState != null),
       assert(xPrecision != null),
       assert(yPrecision != null),
       assert(deviceId != null),
       assert(edgeFlags != null),
       assert(source != null),
       assert(flags != null),
       assert(pointerProperties.length == pointerCount),
       assert(pointerCoords.length == pointerCount);

  /// The time (in ms) when the user originally pressed down to start a stream of position events,
  /// relative to an arbitrary timeline.
  ///
  /// See Android's [MotionEvent#getDownTime](https://developer.android.com/reference/android/view/MotionEvent.html#getDownTime()).
  final int downTime;

  /// The time this event occurred, relative to an arbitrary timeline.
  ///
  /// See Android's [MotionEvent#getEventTime](https://developer.android.com/reference/android/view/MotionEvent.html#getEventTime()).
  final int eventTime;

  /// A value representing the kind of action being performed.
  ///
  /// See Android's [MotionEvent#getAction](https://developer.android.com/reference/android/view/MotionEvent.html#getAction()).
  final int action;

  /// The number of pointers that are part of this event.
  /// This must be equivalent to the length of `pointerProperties` and `pointerCoords`.
  ///
  /// See Android's [MotionEvent#getPointerCount](https://developer.android.com/reference/android/view/MotionEvent.html#getPointerCount()).
  final int pointerCount;

  /// List of [AndroidPointerProperties] for each pointer that is part of this event.
  final List<AndroidPointerProperties> pointerProperties;

  /// List of [AndroidPointerCoords] for each pointer that is part of this event.
  final List<AndroidPointerCoords> pointerCoords;

  /// The state of any meta / modifier keys that were in effect when the event was generated.
  ///
  /// See Android's [MotionEvent#getMetaState](https://developer.android.com/reference/android/view/MotionEvent.html#getMetaState()).
  final int metaState;

  /// The state of all buttons that are pressed such as a mouse or stylus button.
  ///
  /// See Android's [MotionEvent#getButtonState](https://developer.android.com/reference/android/view/MotionEvent.html#getButtonState()).
  final int buttonState;

  /// The precision of the X coordinates being reported, in physical pixels.
  ///
  /// See Android's [MotionEvent#getXPrecision](https://developer.android.com/reference/android/view/MotionEvent.html#getXPrecision()).
  final double xPrecision;

  /// The precision of the Y coordinates being reported, in physical pixels.
  ///
  /// See Android's [MotionEvent#getYPrecision](https://developer.android.com/reference/android/view/MotionEvent.html#getYPrecision()).
  final double yPrecision;

  /// See Android's [MotionEvent#getDeviceId](https://developer.android.com/reference/android/view/MotionEvent.html#getDeviceId()).
  final int deviceId;

  /// A bit field indicating which edges, if any, were touched by this MotionEvent.
  ///
  /// See Android's [MotionEvent#getEdgeFlags](https://developer.android.com/reference/android/view/MotionEvent.html#getEdgeFlags()).
  final int edgeFlags;

  /// The source of this event (e.g a touchpad or stylus).
  ///
  /// See Android's [MotionEvent#getSource](https://developer.android.com/reference/android/view/MotionEvent.html#getSource()).
  final int source;

  /// See Android's [MotionEvent#getFlags](https://developer.android.com/reference/android/view/MotionEvent.html#getFlags()).
  final int flags;

  /// Used to identify this [MotionEvent](https://developer.android.com/reference/android/view/MotionEvent.html) uniquely in the Flutter Engine.
  final int motionEventId;

  List<dynamic> _asList(int viewId) {
    return <dynamic>[
      viewId,
      downTime,
      eventTime,
      action,
      pointerCount,
      pointerProperties.map<List<int>>((AndroidPointerProperties p) => p._asList()).toList(),
      pointerCoords.map<List<double>>((AndroidPointerCoords p) => p._asList()).toList(),
      metaState,
      buttonState,
      xPrecision,
      yPrecision,
      deviceId,
      edgeFlags,
      source,
      flags,
      motionEventId,
    ];
  }

  @override
  String toString() {
    return 'AndroidPointerEvent(downTime: $downTime, eventTime: $eventTime, action: $action, pointerCount: $pointerCount, pointerProperties: $pointerProperties, pointerCoords: $pointerCoords, metaState: $metaState, buttonState: $buttonState, xPrecision: $xPrecision, yPrecision: $yPrecision, deviceId: $deviceId, edgeFlags: $edgeFlags, source: $source, flags: $flags, motionEventId: $motionEventId)';
  }
}

enum _AndroidViewState {
  waitingForSize,
  creating,
  created,
  disposed,
}

// Helper for converting PointerEvents into AndroidMotionEvents.
class _AndroidMotionEventConverter {
  _AndroidMotionEventConverter();

  final Map<int, AndroidPointerCoords> pointerPositions =
      <int, AndroidPointerCoords>{};
  final Map<int, AndroidPointerProperties> pointerProperties =
      <int, AndroidPointerProperties>{};
  final Set<int> usedAndroidPointerIds = <int>{};

  PointTransformer get pointTransformer => _pointTransformer;
  late PointTransformer _pointTransformer;
  set pointTransformer(PointTransformer transformer) {
    assert(transformer != null);
    _pointTransformer = transformer;
  }

  int? downTimeMillis;

  void handlePointerDownEvent(PointerDownEvent event) {
    if (pointerProperties.isEmpty) {
      downTimeMillis = event.timeStamp.inMilliseconds;
    }
    int androidPointerId = 0;
    while (usedAndroidPointerIds.contains(androidPointerId)) {
      androidPointerId++;
    }
    usedAndroidPointerIds.add(androidPointerId);
    pointerProperties[event.pointer] = propertiesFor(event, androidPointerId);
  }

  void updatePointerPositions(PointerEvent event) {
    final Offset position = _pointTransformer(event.position);
    pointerPositions[event.pointer] = AndroidPointerCoords(
      orientation: event.orientation,
      pressure: event.pressure,
      size: event.size,
      toolMajor: event.radiusMajor,
      toolMinor: event.radiusMinor,
      touchMajor: event.radiusMajor,
      touchMinor: event.radiusMinor,
      x: position.dx,
      y: position.dy,
    );
  }

  void _remove(int pointer) {
    pointerPositions.remove(pointer);
    usedAndroidPointerIds.remove(pointerProperties[pointer]!.id);
    pointerProperties.remove(pointer);
    if (pointerProperties.isEmpty) {
      downTimeMillis = null;
    }
  }

  void handlePointerUpEvent(PointerUpEvent event) {
    _remove(event.pointer);
  }

  void handlePointerCancelEvent(PointerCancelEvent event) {
    // The pointer cancel event is handled like pointer up. Normally,
    // the difference is that pointer cancel doesn't perform any action,
    // but in this case neither up or cancel perform any action.
    _remove(event.pointer);
  }

  AndroidMotionEvent? toAndroidMotionEvent(PointerEvent event) {
    final List<int> pointers = pointerPositions.keys.toList();
    final int pointerIdx = pointers.indexOf(event.pointer);
    final int numPointers = pointers.length;

    // This value must match the value in engine's FlutterView.java.
    // This flag indicates whether the original Android pointer events were batched together.
    const int kPointerDataFlagBatched = 1;

    // Android MotionEvent objects can batch information on multiple pointers.
    // Flutter breaks these such batched events into multiple PointerEvent objects.
    // When there are multiple active pointers we accumulate the information for all pointers
    // as we get PointerEvents, and only send it to the embedded Android view when
    // we see the last pointer. This way we achieve the same batching as Android.
    if (event.platformData == kPointerDataFlagBatched ||
        (isSinglePointerAction(event) && pointerIdx < numPointers - 1)) {
      return null;
    }

    final int action;
    if (event is PointerDownEvent) {
      action = numPointers == 1
          ? AndroidViewController.kActionDown
          : AndroidViewController.pointerAction(pointerIdx, AndroidViewController.kActionPointerDown);
    } else if (event is PointerUpEvent) {
      action = numPointers == 1
          ? AndroidViewController.kActionUp
          : AndroidViewController.pointerAction(pointerIdx, AndroidViewController.kActionPointerUp);
    } else if (event is PointerMoveEvent) {
      action = AndroidViewController.kActionMove;
    } else if (event is PointerCancelEvent) {
      action = AndroidViewController.kActionCancel;
    } else {
      return null;
    }

    return AndroidMotionEvent(
      downTime: downTimeMillis!,
      eventTime: event.timeStamp.inMilliseconds,
      action: action,
      pointerCount: pointerPositions.length,
      pointerProperties: pointers
          .map<AndroidPointerProperties>((int i) => pointerProperties[i]!)
          .toList(),
      pointerCoords: pointers
          .map<AndroidPointerCoords>((int i) => pointerPositions[i]!)
          .toList(),
      metaState: 0,
      buttonState: 0,
      xPrecision: 1.0,
      yPrecision: 1.0,
      deviceId: 0,
      edgeFlags: 0,
      source: 0,
      flags: 0,
      motionEventId: event.embedderId,
    );
  }

  AndroidPointerProperties propertiesFor(PointerEvent event, int pointerId) {
    int toolType = AndroidPointerProperties.kToolTypeUnknown;
    switch (event.kind) {
      case PointerDeviceKind.touch:
        toolType = AndroidPointerProperties.kToolTypeFinger;
        break;
      case PointerDeviceKind.mouse:
        toolType = AndroidPointerProperties.kToolTypeMouse;
        break;
      case PointerDeviceKind.stylus:
        toolType = AndroidPointerProperties.kToolTypeStylus;
        break;
      case PointerDeviceKind.invertedStylus:
        toolType = AndroidPointerProperties.kToolTypeEraser;
        break;
      case PointerDeviceKind.unknown:
      default: // ignore: no_default_cases, to allow adding new device types to [PointerDeviceKind]
               // TODO(moffatman): Remove after landing https://github.com/flutter/flutter/issues/23604
        toolType = AndroidPointerProperties.kToolTypeUnknown;
        break;
    }
    return AndroidPointerProperties(id: pointerId, toolType: toolType);
  }

  bool isSinglePointerAction(PointerEvent event) =>
      event is! PointerDownEvent && event is! PointerUpEvent;
}

/// Controls an Android view that is composed using a GL texture.
///
/// Typically created with [PlatformViewsService.initAndroidView].
// TODO(bparrishMines): Remove abstract methods that are not required by all subclasses.
abstract class AndroidViewController extends PlatformViewController {
  AndroidViewController._({
    required this.viewId,
    required String viewType,
    required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic>? creationParamsCodec,
  })  : assert(viewId != null),
        assert(viewType != null),
        assert(layoutDirection != null),
        assert(creationParams == null || creationParamsCodec != null),
        _viewType = viewType,
        _layoutDirection = layoutDirection,
        _creationParams = creationParams,
        _creationParamsCodec = creationParamsCodec;

  /// Action code for when a primary pointer touched the screen.
  ///
  /// Android's [MotionEvent.ACTION_DOWN](https://developer.android.com/reference/android/view/MotionEvent#ACTION_DOWN)
  static const int kActionDown = 0;

  /// Action code for when a primary pointer stopped touching the screen.
  ///
  /// Android's [MotionEvent.ACTION_UP](https://developer.android.com/reference/android/view/MotionEvent#ACTION_UP)
  static const int kActionUp = 1;

  /// Action code for when the event only includes information about pointer movement.
  ///
  /// Android's [MotionEvent.ACTION_MOVE](https://developer.android.com/reference/android/view/MotionEvent#ACTION_MOVE)
  static const int kActionMove = 2;

  /// Action code for when a motion event has been canceled.
  ///
  /// Android's [MotionEvent.ACTION_CANCEL](https://developer.android.com/reference/android/view/MotionEvent#ACTION_CANCEL)
  static const int kActionCancel = 3;

  /// Action code for when a secondary pointer touched the screen.
  ///
  /// Android's [MotionEvent.ACTION_POINTER_DOWN](https://developer.android.com/reference/android/view/MotionEvent#ACTION_POINTER_DOWN)
  static const int kActionPointerDown = 5;

  /// Action code for when a secondary pointer stopped touching the screen.
  ///
  /// Android's [MotionEvent.ACTION_POINTER_UP](https://developer.android.com/reference/android/view/MotionEvent#ACTION_POINTER_UP)
  static const int kActionPointerUp = 6;

  /// Android's [View.LAYOUT_DIRECTION_LTR](https://developer.android.com/reference/android/view/View.html#LAYOUT_DIRECTION_LTR) value.
  static const int kAndroidLayoutDirectionLtr = 0;

  /// Android's [View.LAYOUT_DIRECTION_RTL](https://developer.android.com/reference/android/view/View.html#LAYOUT_DIRECTION_RTL) value.
  static const int kAndroidLayoutDirectionRtl = 1;

  /// The unique identifier of the Android view controlled by this controller.
  @override
  final int viewId;

  final String _viewType;

  // Helps convert PointerEvents to AndroidMotionEvents.
  final _AndroidMotionEventConverter _motionEventConverter =
      _AndroidMotionEventConverter();

  TextDirection _layoutDirection;

  _AndroidViewState _state = _AndroidViewState.waitingForSize;

  final dynamic _creationParams;

  final MessageCodec<dynamic>? _creationParamsCodec;

  final List<PlatformViewCreatedCallback> _platformViewCreatedCallbacks =
      <PlatformViewCreatedCallback>[];

  static int _getAndroidDirection(TextDirection direction) {
    assert(direction != null);
    switch (direction) {
      case TextDirection.ltr:
        return kAndroidLayoutDirectionLtr;
      case TextDirection.rtl:
        return kAndroidLayoutDirectionRtl;
    }
  }

  /// Creates a masked Android MotionEvent action value for an indexed pointer.
  static int pointerAction(int pointerId, int action) {
    return ((pointerId << 8) & 0xff00) | (action & 0xff);
  }

  Future<void> _sendDisposeMessage();
  Future<void> _sendCreateMessage();

  /// Creates the Android View.
  ///
  /// Throws an [AssertionError] if view was already disposed.
  Future<void> create() async {
    assert(_state != _AndroidViewState.disposed, 'trying to create a disposed Android view');

    await _sendCreateMessage();

    _state = _AndroidViewState.created;
    for (final PlatformViewCreatedCallback callback in _platformViewCreatedCallbacks) {
      callback(viewId);
    }
  }

  /// Sizes the Android View.
  ///
  /// [size] is the view's new size in logical pixel, it must not be null and must
  /// be bigger than zero.
  ///
  /// The first time a size is set triggers the creation of the Android view.
  ///
  /// Returns the buffer size in logical pixel that backs the texture where the platform
  /// view pixels are written to.
  ///
  /// The buffer size may or may not be the same as [size].
  ///
  /// As a result, consumers are expected to clip the texture using [size], while using
  /// the return value to size the texture.
  Future<Size> setSize(Size size);

  /// Sets the offset of the platform view.
  ///
  /// [off] is the view's new offset in logical pixel.
  ///
  /// On Android, this allows the Android native view to draw the a11y highlights in the same
  /// location on the screen as the platform view widget in the Flutter framework.
  Future<void> setOffset(Offset off);

  /// Returns the texture entry id that the Android view is rendering into.
  ///
  /// Returns null if the Android view has not been successfully created, or if it has been
  /// disposed.
  int? get textureId;

  /// Sends an Android [MotionEvent](https://developer.android.com/reference/android/view/MotionEvent)
  /// to the view.
  ///
  /// The Android MotionEvent object is created with [MotionEvent.obtain](https://developer.android.com/reference/android/view/MotionEvent.html#obtain(long,%20long,%20int,%20float,%20float,%20float,%20float,%20int,%20float,%20float,%20int,%20int)).
  /// See documentation of [MotionEvent.obtain](https://developer.android.com/reference/android/view/MotionEvent.html#obtain(long,%20long,%20int,%20float,%20float,%20float,%20float,%20int,%20float,%20float,%20int,%20int))
  /// for description of the parameters.
  ///
  /// See [AndroidViewController.dispatchPointerEvent] for sending a
  /// [PointerEvent].
  Future<void> sendMotionEvent(AndroidMotionEvent event) async {
    await SystemChannels.platform_views.invokeMethod<dynamic>(
      'touch',
      event._asList(viewId),
    );
  }

  /// Converts a given point from the global coordinate system in logical pixels
  /// to the local coordinate system for this box.
  ///
  /// This is required to convert a [PointerEvent] to an [AndroidMotionEvent].
  /// It is typically provided by using [RenderBox.globalToLocal].
  PointTransformer get pointTransformer => _motionEventConverter._pointTransformer;
  set pointTransformer(PointTransformer transformer) {
    assert(transformer != null);
    _motionEventConverter._pointTransformer = transformer;
  }

  /// Whether the platform view has already been created.
  bool get isCreated => _state == _AndroidViewState.created;

  /// Adds a callback that will get invoke after the platform view has been
  /// created.
  void addOnPlatformViewCreatedListener(PlatformViewCreatedCallback listener) {
    assert(listener != null);
    assert(_state != _AndroidViewState.disposed);
    _platformViewCreatedCallbacks.add(listener);
  }

  /// Removes a callback added with [addOnPlatformViewCreatedListener].
  void removeOnPlatformViewCreatedListener(PlatformViewCreatedCallback listener) {
    assert(listener != null);
    assert(_state != _AndroidViewState.disposed);
    _platformViewCreatedCallbacks.remove(listener);
  }

  /// The created callbacks that are invoked after the platform view has been
  /// created.
  @visibleForTesting
  List<PlatformViewCreatedCallback> get createdCallbacks => _platformViewCreatedCallbacks;

  /// Sets the layout direction for the Android view.
  Future<void> setLayoutDirection(TextDirection layoutDirection) async {
    assert(
      _state != _AndroidViewState.disposed,
      'trying to set a layout direction for a disposed UIView. View id: $viewId',
    );

    if (layoutDirection == _layoutDirection)
      return;

    assert(layoutDirection != null);
    _layoutDirection = layoutDirection;

    // If the view was not yet created we just update _layoutDirection and return, as the new
    // direction will be used in _create.
    if (_state == _AndroidViewState.waitingForSize)
      return;

    await SystemChannels.platform_views
        .invokeMethod<void>('setDirection', <String, dynamic>{
      'id': viewId,
      'direction': _getAndroidDirection(layoutDirection),
    });
  }

  /// Converts the [PointerEvent] and sends an Android [MotionEvent](https://developer.android.com/reference/android/view/MotionEvent)
  /// to the view.
  ///
  /// This method can only be used if a [PointTransformer] is provided to
  /// [AndroidViewController.pointTransformer]. Otherwise, an [AssertionError]
  /// is thrown. See [AndroidViewController.sendMotionEvent] for sending a
  /// `MotionEvent` without a [PointTransformer].
  ///
  /// The Android MotionEvent object is created with [MotionEvent.obtain](https://developer.android.com/reference/android/view/MotionEvent.html#obtain(long,%20long,%20int,%20float,%20float,%20float,%20float,%20int,%20float,%20float,%20int,%20int)).
  /// See documentation of [MotionEvent.obtain](https://developer.android.com/reference/android/view/MotionEvent.html#obtain(long,%20long,%20int,%20float,%20float,%20float,%20float,%20int,%20float,%20float,%20int,%20int))
  /// for description of the parameters.
  @override
  Future<void> dispatchPointerEvent(PointerEvent event) async {
    if (event is PointerHoverEvent) {
      return;
    }

    if (event is PointerDownEvent) {
      _motionEventConverter.handlePointerDownEvent(event);
    }

    _motionEventConverter.updatePointerPositions(event);

    final AndroidMotionEvent? androidEvent =
        _motionEventConverter.toAndroidMotionEvent(event);

    if (event is PointerUpEvent) {
      _motionEventConverter.handlePointerUpEvent(event);
    } else if (event is PointerCancelEvent) {
      _motionEventConverter.handlePointerCancelEvent(event);
    }

    if (androidEvent != null) {
      await sendMotionEvent(androidEvent);
    }
  }

  /// Clears the focus from the Android View if it is focused.
  @override
  Future<void> clearFocus() {
    if (_state != _AndroidViewState.created) {
      return Future<void>.value();
    }
    return SystemChannels.platform_views.invokeMethod<void>('clearFocus', viewId);
  }

  /// Disposes the Android view.
  ///
  /// The [AndroidViewController] object is unusable after calling this.
  /// The identifier of the platform view cannot be reused after the view is
  /// disposed.
  @override
  Future<void> dispose() async {
    if (_state == _AndroidViewState.creating || _state == _AndroidViewState.created)
      await _sendDisposeMessage();
    _platformViewCreatedCallbacks.clear();
    _state = _AndroidViewState.disposed;
    PlatformViewsService._instance._focusCallbacks.remove(viewId);
  }
}

/// Controls an Android view that is composed using a GL texture.
/// This controller is created from the [PlatformViewsService.initSurfaceAndroidView] factory,
/// and is defined for backward compatibility.
class SurfaceAndroidViewController extends TextureAndroidViewController{
    SurfaceAndroidViewController._({
    required int viewId,
    required String viewType,
    required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic>? creationParamsCodec,
  })  : super._(
          viewId: viewId,
          viewType: viewType,
          layoutDirection: layoutDirection,
          creationParams: creationParams,
          creationParamsCodec: creationParamsCodec,
        );
}

/// Controls an Android view that is composed using the Android view hierarchy.
/// This controller is created from the [PlatformViewsService.initExpensiveAndroidView] factory.
class ExpensiveAndroidViewController extends AndroidViewController {
  ExpensiveAndroidViewController._({
    required int viewId,
    required String viewType,
    required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic>? creationParamsCodec,
  })  : super._(
          viewId: viewId,
          viewType: viewType,
          layoutDirection: layoutDirection,
          creationParams: creationParams,
          creationParamsCodec: creationParamsCodec,
        );

  @override
  Future<void> _sendCreateMessage() {
    final Map<String, dynamic> args = <String, dynamic>{
      'id': viewId,
      'viewType': _viewType,
      'direction': AndroidViewController._getAndroidDirection(_layoutDirection),
      'hybrid': true,
    };
    if (_creationParams != null) {
      final ByteData paramsByteData =
          _creationParamsCodec!.encodeMessage(_creationParams)!;
      args['params'] = Uint8List.view(
        paramsByteData.buffer,
        0,
        paramsByteData.lengthInBytes,
      );
    }
    return SystemChannels.platform_views.invokeMethod<void>('create', args);
  }

  @override
  int get textureId {
    throw UnimplementedError('Not supported for $SurfaceAndroidViewController.');
  }

  @override
  Future<void> _sendDisposeMessage() {
    return SystemChannels.platform_views
        .invokeMethod<void>('dispose', <String, dynamic>{
      'id': viewId,
      'hybrid': true,
    });
  }

  @override
  Future<Size> setSize(Size size) {
    throw UnimplementedError('Not supported for $SurfaceAndroidViewController.');
  }

  @override
  Future<void> setOffset(Offset off) {
    throw UnimplementedError('Not supported for $SurfaceAndroidViewController.');
  }
}

/// Controls an Android view that is rendered to a texture.
///
/// This is typically used by [AndroidView] to display an Android View in the Android view hierarchy.
///
/// Typically created with [PlatformViewsService.initAndroidView].
class TextureAndroidViewController extends AndroidViewController {
  TextureAndroidViewController._({
    required int viewId,
    required String viewType,
    required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic>? creationParamsCodec,
  }) : super._(
          viewId: viewId,
          viewType: viewType,
          layoutDirection: layoutDirection,
          creationParams: creationParams,
          creationParamsCodec: creationParamsCodec,
        );

  /// The texture entry id into which the Android view is rendered.
  int? _textureId;

  /// Returns the texture entry id that the Android view is rendering into.
  ///
  /// Returns null if the Android view has not been successfully created, or if it has been
  /// disposed.
  @override
  int? get textureId => _textureId;

  /// The size used to create the platform view.
  Size? _initialSize;

  /// The current offset of the platform view.
  Offset _off = Offset.zero;

  @override
  Future<Size> setSize(Size size) async {
    assert(_state != _AndroidViewState.disposed, 'trying to size a disposed Android View. View id: $viewId');

    assert(size != null);
    assert(!size.isEmpty);

    if (_state == _AndroidViewState.waitingForSize) {
      _initialSize = size;
      await create();
      return size;
    }

    final Map<Object?, Object?>? meta = await SystemChannels.platform_views.invokeMapMethod<Object?, Object?>(
      'resize',
      <String, dynamic>{
        'id': viewId,
        'width': size.width,
        'height': size.height,
      },
    );
    assert(meta != null);
    assert(meta!.containsKey('width'));
    assert(meta!.containsKey('height'));
    return Size(meta!['width']! as double, meta['height']! as double);
  }

  @override
  Future<void> setOffset(Offset off) async {
    if (off == _off)
      return;

    // Don't set the offset unless the Android view has been created.
    // The implementation of this method channel throws if the Android view for this viewId
    // isn't addressable.
    if (_state != _AndroidViewState.created)
      return;

    _off = off;

    await SystemChannels.platform_views.invokeMethod<void>(
      'offset',
      <String, dynamic>{
        'id': viewId,
        'top': off.dy,
        'left': off.dx,
      },
    );
  }

  /// Creates the Android View.
  ///
  /// This should not be called before [AndroidViewController.setSize].
  ///
  /// Throws an [AssertionError] if view was already disposed.
  @override
  Future<void> create() async {
    if (_initialSize != null)
      return super.create();
  }

  @override
  Future<void> _sendCreateMessage() async {
    assert(_initialSize != null, 'trying to create $TextureAndroidViewController without setting an initial size.');
    assert(!_initialSize!.isEmpty, 'trying to create $TextureAndroidViewController without setting a valid size.');

    final Map<String, dynamic> args = <String, dynamic>{
      'id': viewId,
      'viewType': _viewType,
      'width': _initialSize!.width,
      'height': _initialSize!.height,
      'direction': AndroidViewController._getAndroidDirection(_layoutDirection),
    };
    if (_creationParams != null) {
      final ByteData paramsByteData = _creationParamsCodec!.encodeMessage(_creationParams)!;
      args['params'] = Uint8List.view(
        paramsByteData.buffer,
        0,
        paramsByteData.lengthInBytes,
      );
    }
    _textureId = await SystemChannels.platform_views.invokeMethod<int>('create', args);
  }

  @override
  Future<void> _sendDisposeMessage() {
    return SystemChannels
        .platform_views.invokeMethod<void>('dispose', <String, dynamic>{
      'id': viewId,
      'hybrid': false,
    });
  }
}

/// Controls an iOS UIView.
///
/// Typically created with [PlatformViewsService.initUiKitView].
class UiKitViewController {
  UiKitViewController._(
    this.id,
    TextDirection layoutDirection,
  ) : assert(id != null),
      assert(layoutDirection != null),
      _layoutDirection = layoutDirection;


  /// The unique identifier of the iOS view controlled by this controller.
  ///
  /// This identifier is typically generated by
  /// [PlatformViewsRegistry.getNextPlatformViewId].
  final int id;

  bool _debugDisposed = false;

  TextDirection _layoutDirection;

  /// Sets the layout direction for the iOS UIView.
  Future<void> setLayoutDirection(TextDirection layoutDirection) async {
    assert(!_debugDisposed, 'trying to set a layout direction for a disposed iOS UIView. View id: $id');

    if (layoutDirection == _layoutDirection)
      return;

    assert(layoutDirection != null);
    _layoutDirection = layoutDirection;

    // TODO(amirh): invoke the iOS platform views channel direction method once available.
  }

  /// Accept an active gesture.
  ///
  /// When a touch sequence is happening on the embedded UIView all touch events are delayed.
  /// Calling this method releases the delayed events to the embedded UIView and makes it consume
  /// any following touch events for the pointers involved in the active gesture.
  Future<void> acceptGesture() {
    final Map<String, dynamic> args = <String, dynamic>{
      'id': id,
    };
    return SystemChannels.platform_views.invokeMethod('acceptGesture', args);
  }

  /// Rejects an active gesture.
  ///
  /// When a touch sequence is happening on the embedded UIView all touch events are delayed.
  /// Calling this method drops the buffered touch events and prevents any future touch events for
  /// the pointers that are part of the active touch sequence from arriving to the embedded view.
  Future<void> rejectGesture() {
    final Map<String, dynamic> args = <String, dynamic>{
      'id': id,
    };
    return SystemChannels.platform_views.invokeMethod('rejectGesture', args);
  }

  /// Disposes the view.
  ///
  /// The [UiKitViewController] object is unusable after calling this.
  /// The `id` of the platform view cannot be reused after the view is
  /// disposed.
  Future<void> dispose() async {
    _debugDisposed = true;
    await SystemChannels.platform_views.invokeMethod<void>('dispose', id);
  }
}

/// An interface for controlling a single platform view.
///
/// Used by [PlatformViewSurface] to interface with the platform view it embeds.
abstract class PlatformViewController {
  /// The viewId associated with this controller.
  ///
  /// The viewId should always be unique and non-negative.
  ///
  /// See also:
  ///
  ///  * [PlatformViewsRegistry], which is a helper for managing platform view IDs.
  int get viewId;

  /// Dispatches the `event` to the platform view.
  Future<void> dispatchPointerEvent(PointerEvent event);

  /// Disposes the platform view.
  ///
  /// The [PlatformViewController] is unusable after calling dispose.
  Future<void> dispose();

  /// Clears the view's focus on the platform side.
  Future<void> clearFocus();
}
