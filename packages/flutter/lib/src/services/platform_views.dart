// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'message_codec.dart';
import 'system_channels.dart';

/// The [PlatformViewsRegistry] responsible for generating unique identifiers for platform views.
final PlatformViewsRegistry platformViewsRegistry = PlatformViewsRegistry._instance();

/// A registry responsible for generating unique identifier for platform views.
///
/// A Flutter application has a single [PlatformViewsRegistry] which can be accesses
/// through the [platformViewsRegistry] getter.
///
/// See also:
///   * [PlatformView], a widget that shows a platform view.
class PlatformViewsRegistry {
  PlatformViewsRegistry._instance();

  int _nextPlatformViewId = 0;

  /// Allocates a unique identifier for a platform view.
  ///
  /// A platform view identifier can refer to a platform view that was never created,
  /// a platform view that was disposed, or a platform view that is alive.
  ///
  /// Typically a platform view identifier is passed to a [PlatformView] widget
  /// which creates the platform view and manages its lifecycle.
  int getNextPlatformViewId() => _nextPlatformViewId++;
}

/// Callback signature for when a platform view was created.
///
/// `id` is the platform view's unique identifier.
typedef PlatformViewCreatedCallback = void Function(int id);

/// Provides access to the platform views service.
///
/// This service allows creating and controlling Android views.
///
/// See also: [PlatformView].
class PlatformViewsService {
  PlatformViewsService._();

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
  /// The Android view will only be created after [AndroidViewController.setSize] is called for the
  /// first time.
  ///
  /// The `id, `viewType, and `layoutDirection` parameters must not be null.
  /// If `creationParams` is non null then `cretaionParamsCodec` must not be null.
  static AndroidViewController initAndroidView({
    @required int id,
    @required String viewType,
    @required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic> creationParamsCodec,
    PlatformViewCreatedCallback onPlatformViewCreated,
  }) {
    assert(id != null);
    assert(viewType != null);
    assert(layoutDirection != null);
    assert(creationParams == null || creationParamsCodec != null);
    return AndroidViewController._(
      id,
      viewType,
      creationParams,
      creationParamsCodec,
      layoutDirection,
      onPlatformViewCreated,
    );
  }

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
  /// If `creationParams` is non null then `cretaionParamsCodec` must not be null.
  static Future<UiKitViewController> initUiKitView({
    @required int id,
    @required String viewType,
    @required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic> creationParamsCodec,
  }) async {
    assert(id != null);
    assert(viewType != null);
    assert(layoutDirection != null);
    assert(creationParams == null || creationParamsCodec != null);

    // TODO(amirh): pass layoutDirection once the system channel supports it.
    final Map<String, dynamic> args = <String, dynamic> {
      'id': id,
      'viewType': viewType,
    };
    if (creationParams != null) {
      final ByteData paramsByteData = creationParamsCodec.encodeMessage(creationParams);
      args['params'] = Uint8List.view(
        paramsByteData.buffer,
        0,
        paramsByteData.lengthInBytes,
      );
    }
    await SystemChannels.platform_views.invokeMethod('create', args);
    return UiKitViewController._(id, layoutDirection);
  }
}

/// Properties of an Android pointer.
///
/// A Dart version of Android's [MotionEvent.PointerProperties](https://developer.android.com/reference/android/view/MotionEvent.PointerProperties).
class AndroidPointerProperties {
  /// Creates an AndroidPointerProperties.
  ///
  /// All parameters must not be null.
  const AndroidPointerProperties({
    @required this.id,
    @required this.toolType
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
    return 'AndroidPointerProperties(id: $id, toolType: $toolType)';
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
    @required this.orientation,
    @required this.pressure,
    @required this.size,
    @required this.toolMajor,
    @required this.toolMinor,
    @required this.touchMajor,
    @required this.touchMinor,
    @required this.x,
    @required this.y
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
    return 'AndroidPointerCoords(orientation: $orientation, pressure: $pressure, size: $size, toolMajor: $toolMajor, toolMinor: $toolMinor, touchMajor: $touchMajor, touchMinor: $touchMinor, x: $x, y: $y)';
  }
}

/// A Dart version of Android's [MotionEvent](https://developer.android.com/reference/android/view/MotionEvent).
class AndroidMotionEvent {
  /// Creates an AndroidMotionEvent.
  ///
  /// All parameters must not be null.
  AndroidMotionEvent({
    @required this.downTime,
    @required this.eventTime,
    @required this.action,
    @required this.pointerCount,
    @required this.pointerProperties,
    @required this.pointerCoords,
    @required this.metaState,
    @required this.buttonState,
    @required this.xPrecision,
    @required this.yPrecision,
    @required this.deviceId,
    @required this.edgeFlags,
    @required this.source,
    @required this.flags
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

  /// A bitfield indicating which edges, if any, were touched by this MotionEvent.
  ///
  /// See Android's [MotionEvent#getEdgeFlags](https://developer.android.com/reference/android/view/MotionEvent.html#getEdgeFlags()).
  final int edgeFlags;

  /// The source of this event (e.g a touchpad or stylus).
  ///
  /// See Android's [MotionEvent#getSource](https://developer.android.com/reference/android/view/MotionEvent.html#getSource()).
  final int source;

  /// See Android's [MotionEvent#getFlags](https://developer.android.com/reference/android/view/MotionEvent.html#getFlags()).
  final int flags;

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
    ];
  }

  @override
  String toString() {
    return 'AndroidPointerEvent(downTime: $downTime, eventTime: $eventTime, action: $action, pointerCount: $pointerCount, pointerProperties: $pointerProperties, pointerCoords: $pointerCoords, metaState: $metaState, buttonState: $buttonState, xPrecision: $xPrecision, yPrecision: $yPrecision, deviceId: $deviceId, edgeFlags: $edgeFlags, source: $source, flags: $flags)';
  }
}

enum _AndroidViewState {
  waitingForSize,
  creating,
  created,
  createFailed,
  disposed,
}

/// Controls an Android view.
///
/// Typically created with [PlatformViewsService.initAndroidView].
class AndroidViewController {
  AndroidViewController._(
    this.id,
    String viewType,
    dynamic creationParams,
    MessageCodec<dynamic> creationParamsCodec,
    TextDirection layoutDirection,
    PlatformViewCreatedCallback onPlatformViewCreated,
  ) : assert(id != null),
      assert(viewType != null),
      assert(layoutDirection != null),
      assert(creationParams == null || creationParamsCodec != null),
      _viewType = viewType,
      _creationParams = creationParams,
      _creationParamsCodec = creationParamsCodec,
      _layoutDirection = layoutDirection,
      _onPlatformViewCreated = onPlatformViewCreated,
      _state = _AndroidViewState.waitingForSize;

  /// Action code for when a primary pointer touched the screen.
  ///
  /// Android's [MotionEvent.ACTION_DOWN](https://developer.android.com/reference/android/view/MotionEvent#ACTION_DOWN)
  static const int kActionDown =  0;

  /// Action code for when a primary pointer stopped touching the screen.
  ///
  /// Android's [MotionEvent.ACTION_UP](https://developer.android.com/reference/android/view/MotionEvent#ACTION_UP)
  static const int kActionUp =  1;

  /// Action code for when the event only includes information about pointer movement.
  ///
  /// Android's [MotionEvent.ACTION_MOVE](https://developer.android.com/reference/android/view/MotionEvent#ACTION_MOVE)
  static const int kActionMove = 2;

  /// Action code for when a motion event has been cancelled.
  ///
  /// Android's [MotionEvent.ACTION_CANCEL](https://developer.android.com/reference/android/view/MotionEvent#ACTION_CANCEL)
  static const int kActionCancel = 3;

  /// Action code for when a secondary pointer touched the screen.
  ///
  /// Android's [MotionEvent.ACTION_POINTER_DOWN](https://developer.android.com/reference/android/view/MotionEvent#ACTION_POINTER_DOWN)
  static const int kActionPointerDown =  5;

  /// Action code for when a secondary pointer stopped touching the screen.
  ///
  /// Android's [MotionEvent.ACTION_POINTER_UP](https://developer.android.com/reference/android/view/MotionEvent#ACTION_POINTER_UP)
  static const int kActionPointerUp =  6;

  /// Android's [View.LAYOUT_DIRECTION_LTR](https://developer.android.com/reference/android/view/View.html#LAYOUT_DIRECTION_LTR) value.
  static const int kAndroidLayoutDirectionLtr = 0;

  /// Android's [View.LAYOUT_DIRECTION_RTL](https://developer.android.com/reference/android/view/View.html#LAYOUT_DIRECTION_RTL) value.
  static const int kAndroidLayoutDirectionRtl = 1;

  /// The unique identifier of the Android view controlled by this controller.
  final int id;

  final String _viewType;

  final PlatformViewCreatedCallback _onPlatformViewCreated;

  /// The texture entry id into which the Android view is rendered.
  int _textureId;

  /// Returns the texture entry id that the Android view is rendering into.
  ///
  /// Returns null if the Android view has not been successfully created, or if it has been
  /// disposed.
  int get textureId => _textureId;

  TextDirection _layoutDirection;

  _AndroidViewState _state;

  dynamic _creationParams;

  MessageCodec<dynamic> _creationParamsCodec;

  /// Disposes the Android view.
  ///
  /// The [AndroidViewController] object is unusable after calling this.
  /// The identifier of the platform view cannot be reused after the view is
  /// disposed.
  Future<void> dispose() async {
    if (_state == _AndroidViewState.creating || _state == _AndroidViewState.created)
      await SystemChannels.platform_views.invokeMethod('dispose', id);
    _state = _AndroidViewState.disposed;
  }

  /// Sizes the Android View.
  ///
  /// `size` is the view's new size in logical pixel, it must not be null and must
  /// be bigger than zero.
  ///
  /// The first time a size is set triggers the creation of the Android view.
  Future<void> setSize(Size size) async {
    assert(_state != _AndroidViewState.disposed, 'trying to size a disposed Android View. View id: $id');

    assert(size != null);
    assert(!size.isEmpty);

    if (_state == _AndroidViewState.waitingForSize)
      return _create(size);

    await SystemChannels.platform_views.invokeMethod('resize', <String, dynamic> {
      'id': id,
      'width': size.width,
      'height': size.height,
    });
  }

  /// Sets the layout direction for the Android view.
  Future<void> setLayoutDirection(TextDirection layoutDirection) async {
    assert(_state != _AndroidViewState.disposed,'trying to set a layout direction for a disposed UIView. View id: $id');

    if (layoutDirection == _layoutDirection)
      return;

    assert(layoutDirection != null);
    _layoutDirection = layoutDirection;

    // If the view was not yet created we just update _layoutDirection and return, as the new
    // direction will be used in _create.
    if (_state == _AndroidViewState.waitingForSize)
      return;

    await SystemChannels.platform_views.invokeMethod('setDirection', <String, dynamic> {
      'id': id,
      'direction': _getAndroidDirection(layoutDirection),
    });
  }

  static int _getAndroidDirection(TextDirection direction) {
    assert(direction != null);
    switch (direction) {
      case TextDirection.ltr:
        return kAndroidLayoutDirectionLtr;
      case TextDirection.rtl:
        return kAndroidLayoutDirectionRtl;
    }
    return null;
  }

  /// Sends an Android [MotionEvent](https://developer.android.com/reference/android/view/MotionEvent)
  /// to the view.
  ///
  /// The Android MotionEvent object is created with [MotionEvent.obtain](https://developer.android.com/reference/android/view/MotionEvent.html#obtain(long,%20long,%20int,%20float,%20float,%20float,%20float,%20int,%20float,%20float,%20int,%20int)).
  /// See documentation of [MotionEvent.obtain](https://developer.android.com/reference/android/view/MotionEvent.html#obtain(long,%20long,%20int,%20float,%20float,%20float,%20float,%20int,%20float,%20float,%20int,%20int))
  /// for description of the parameters.
  Future<void> sendMotionEvent(AndroidMotionEvent event) async {
    await SystemChannels.platform_views.invokeMethod(
        'touch',
        event._asList(id),
    );
  }

  /// Creates a masked Android MotionEvent action value for an indexed pointer.
  static int pointerAction(int pointerId, int action) {
    return ((pointerId << 8) & 0xff00) | (action & 0xff);
  }

  Future<void> _create(Size size) async {
    final Map<String, dynamic> args = <String, dynamic> {
      'id': id,
      'viewType': _viewType,
      'width': size.width,
      'height': size.height,
      'direction': _getAndroidDirection(_layoutDirection),
    };
    if (_creationParams != null) {
      final ByteData paramsByteData = _creationParamsCodec.encodeMessage(_creationParams);
      args['params'] = Uint8List.view(
        paramsByteData.buffer,
        0,
        paramsByteData.lengthInBytes,
      );
    }
    _textureId = await SystemChannels.platform_views.invokeMethod('create', args);
    if (_onPlatformViewCreated != null)
      _onPlatformViewCreated(id);
    _state = _AndroidViewState.created;
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
  /// This identifer is typically generated by [PlatformViewsRegistry.getNextPlatformViewId].
  final int id;

  bool _debugDisposed = false;

  TextDirection _layoutDirection;

  /// Sets the layout direction for the Android view.
  Future<void> setLayoutDirection(TextDirection layoutDirection) async {
    assert(!_debugDisposed, 'trying to set a layout direction for a disposed Android View. View id: $id');

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
    final Map<String, dynamic> args = <String, dynamic> {
      'id': id,
    };
    return SystemChannels.platform_views.invokeMethod('acceptGesture', args);
  }

  /// Disposes the view.
  ///
  /// The [UiKitViewController] object is unusable after calling this.
  /// The `id` of the platform view cannot be reused after the view is
  /// disposed.
  Future<void> dispose() async {
    _debugDisposed = true;
    await SystemChannels.platform_views.invokeMethod('dispose', id);
  }
}
