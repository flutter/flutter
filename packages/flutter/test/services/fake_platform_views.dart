// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'package:collection/collection.dart';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Used in internal testing.
class FakePlatformViewController extends PlatformViewController {

  FakePlatformViewController(int id) {
    _id = id;
  }

  bool disposed = false;
  bool focusCleared = false;

  /// Events that are dispatched;
  List<PointerEvent> dispatchedPointerEvents = <PointerEvent>[];

  int _id;

  @override
  int get viewId => _id;

  @override
  void dispatchPointerEvent(PointerEvent event) {
    dispatchedPointerEvents.add(event);
  }

  void clearTestingVariables() {
    dispatchedPointerEvents.clear();
    disposed = false;
    focusCleared = false;
  }

  @override
  void dispose() {
    disposed = true;
  }

  @override
  void clearFocus() {
    focusCleared = true;
  }
}

class FakeAndroidPlatformViewsController {
  FakeAndroidPlatformViewsController() {
    SystemChannels.platform_views.setMockMethodCallHandler(_onMethodCall);
  }


  Iterable<FakeAndroidPlatformView> get views => _views.values;
  final Map<int, FakeAndroidPlatformView> _views = <int, FakeAndroidPlatformView>{};

  final Map<int, List<FakeAndroidMotionEvent>> motionEvents = <int, List<FakeAndroidMotionEvent>>{};

  final Set<String> _registeredViewTypes = <String>{};

  int _textureCounter = 0;

  Completer<void> resizeCompleter;

  Completer<void> createCompleter;

  int lastClearedFocusViewId;

  void registerViewType(String viewType) {
    _registeredViewTypes.add(viewType);
  }

  void invokeViewFocused(int viewId) {
    final MethodCodec codec = SystemChannels.platform_views.codec;
    final ByteData data = codec.encodeMethodCall(MethodCall('viewFocused', viewId));
    ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(SystemChannels.platform_views.name, data, (ByteData data) {});
  }

  Future<dynamic> _onMethodCall(MethodCall call) {
    switch(call.method) {
      case 'create':
        return _create(call);
      case 'dispose':
        return _dispose(call);
      case 'resize':
        return _resize(call);
      case 'touch':
        return _touch(call);
      case 'setDirection':
        return _setDirection(call);
      case 'clearFocus':
        return _clearFocus(call);
    }
    return Future<dynamic>.sync(() => null);
  }

  Future<dynamic> _create(MethodCall call) async {
    final Map<dynamic, dynamic> args = call.arguments;
    final int id = args['id'];
    final String viewType = args['viewType'];
    final double width = args['width'];
    final double height = args['height'];
    final int layoutDirection = args['direction'];
    final Uint8List creationParams = args['params'];

    if (_views.containsKey(id))
      throw PlatformException(
        code: 'error',
        message: 'Trying to create an already created platform view, view id: $id',
      );

    if (!_registeredViewTypes.contains(viewType))
      throw PlatformException(
        code: 'error',
        message: 'Trying to create a platform view of unregistered type: $viewType',
      );

    if (createCompleter != null) {
      await createCompleter.future;
    }

    _views[id] = FakeAndroidPlatformView(id, viewType, Size(width, height), layoutDirection, creationParams);
    final int textureId = _textureCounter++;
    return Future<int>.sync(() => textureId);
  }

  Future<dynamic> _dispose(MethodCall call) {
    final int id = call.arguments;

    if (!_views.containsKey(id))
      throw PlatformException(
        code: 'error',
        message: 'Trying to dispose a platform view with unknown id: $id',
      );

    _views.remove(id);
    return Future<dynamic>.sync(() => null);
  }

  Future<dynamic> _resize(MethodCall call) async {
    final Map<dynamic, dynamic> args = call.arguments;
    final int id = args['id'];
    final double width = args['width'];
    final double height = args['height'];

    if (!_views.containsKey(id))
      throw PlatformException(
        code: 'error',
        message: 'Trying to resize a platform view with unknown id: $id',
      );

    if (resizeCompleter != null) {
      await resizeCompleter.future;
    }
    _views[id].size = Size(width, height);

    return Future<dynamic>.sync(() => null);
  }

  Future<dynamic> _touch(MethodCall call) {
    final List<dynamic> args = call.arguments;
    final int id = args[0];
    final int action = args[3];
    final List<List<dynamic>> pointerProperties = args[5].cast<List<dynamic>>();
    final List<List<dynamic>> pointerCoords = args[6].cast<List<dynamic>>();
    final List<Offset> pointerOffsets = <Offset> [];
    final List<int> pointerIds = <int> [];
    for (int i = 0; i < pointerCoords.length; i++) {
      pointerIds.add(pointerProperties[i][0]);
      final double x = pointerCoords[i][7];
      final double y = pointerCoords[i][8];
      pointerOffsets.add(Offset(x, y));
    }

    if (!motionEvents.containsKey(id))
      motionEvents[id] = <FakeAndroidMotionEvent> [];

    motionEvents[id].add(FakeAndroidMotionEvent(action, pointerIds, pointerOffsets));
    return Future<dynamic>.sync(() => null);
  }

  Future<dynamic> _setDirection(MethodCall call) async {
    final Map<dynamic, dynamic> args = call.arguments;
    final int id = args['id'];
    final int layoutDirection = args['direction'];

    if (!_views.containsKey(id))
      throw PlatformException(
        code: 'error',
        message: 'Trying to resize a platform view with unknown id: $id',
      );

    _views[id].layoutDirection = layoutDirection;

    return Future<dynamic>.sync(() => null);
  }

  Future<dynamic> _clearFocus(MethodCall call) {
    final int id = call.arguments;

    if (!_views.containsKey(id))
      throw PlatformException(
        code: 'error',
        message: 'Trying to clear the focus on a platform view with unknown id: $id',
      );

    lastClearedFocusViewId = id;
    return Future<dynamic>.sync(() => null);
  }
}

class FakeIosPlatformViewsController {
  FakeIosPlatformViewsController() {
    SystemChannels.platform_views.setMockMethodCallHandler(_onMethodCall);
  }


  Iterable<FakeUiKitView> get views => _views.values;
  final Map<int, FakeUiKitView> _views = <int, FakeUiKitView>{};

  final Set<String> _registeredViewTypes = <String>{};

  // When this completer is non null, the 'create' method channel call will be
  // delayed until it completes.
  Completer<void> creationDelay;

  // Maps a view id to the number of gestures it accepted so far.
  final Map<int, int> gesturesAccepted = <int, int>{};

  // Maps a view id to the number of gestures it rejected so far.
  final Map<int, int> gesturesRejected = <int, int>{};

  void registerViewType(String viewType) {
    _registeredViewTypes.add(viewType);
  }

  Future<dynamic> _onMethodCall(MethodCall call) {
    switch(call.method) {
      case 'create':
        return _create(call);
      case 'dispose':
        return _dispose(call);
      case 'acceptGesture':
        return _acceptGesture(call);
      case 'rejectGesture':
        return _rejectGesture(call);
    }
    return Future<dynamic>.sync(() => null);
  }

  Future<dynamic> _create(MethodCall call) async {
    if (creationDelay != null)
      await creationDelay.future;
    final Map<dynamic, dynamic> args = call.arguments;
    final int id = args['id'];
    final String viewType = args['viewType'];
    final Uint8List creationParams = args['params'];

    if (_views.containsKey(id)) {
      throw PlatformException(
        code: 'error',
        message: 'Trying to create an already created platform view, view id: $id',
      );
    }

    if (!_registeredViewTypes.contains(viewType)) {
      throw PlatformException(
        code: 'error',
        message: 'Trying to create a platform view of unregistered type: $viewType',
      );
    }

    _views[id] = FakeUiKitView(id, viewType, creationParams);
    gesturesAccepted[id] = 0;
    gesturesRejected[id] = 0;
    return Future<int>.sync(() => null);
  }

  Future<dynamic> _acceptGesture(MethodCall call) async {
    final Map<dynamic, dynamic> args = call.arguments;
    final int id = args['id'];
    gesturesAccepted[id] += 1;
    return Future<int>.sync(() => null);
  }

  Future<dynamic> _rejectGesture(MethodCall call) async {
    final Map<dynamic, dynamic> args = call.arguments;
    final int id = args['id'];
    gesturesRejected[id] += 1;
    return Future<int>.sync(() => null);
  }

  Future<dynamic> _dispose(MethodCall call) {
    final int id = call.arguments;

    if (!_views.containsKey(id)) {
      throw PlatformException(
        code: 'error',
        message: 'Trying to dispose a platform view with unknown id: $id',
      );
    }

    _views.remove(id);
    return Future<dynamic>.sync(() => null);
  }
}

class FakeHtmlPlatformViewsController {
  FakeHtmlPlatformViewsController() {
      SystemChannels.platform_views.setMockMethodCallHandler(_onMethodCall);
  }

  Iterable<FakeHtmlPlatformView> get views => _views.values;
  final Map<int, FakeHtmlPlatformView> _views = <int, FakeHtmlPlatformView>{};

  final Set<String> _registeredViewTypes = <String>{};

  Completer<void> resizeCompleter;

  Completer<void> createCompleter;

  void registerViewType(String viewType) {
    _registeredViewTypes.add(viewType);
  }

  Future<dynamic> _onMethodCall(MethodCall call) {
    switch(call.method) {
      case 'create':
        return _create(call);
      case 'dispose':
        return _dispose(call);
    }
    return Future<dynamic>.sync(() => null);
  }

  Future<dynamic> _create(MethodCall call) async {
    final Map<dynamic, dynamic> args = call.arguments;
    final int id = args['id'];
    final String viewType = args['viewType'];

    if (_views.containsKey(id))
      throw PlatformException(
        code: 'error',
        message: 'Trying to create an already created platform view, view id: $id',
      );

    if (!_registeredViewTypes.contains(viewType))
      throw PlatformException(
        code: 'error',
        message: 'Trying to create a platform view of unregistered type: $viewType',
      );

    if (createCompleter != null) {
      await createCompleter.future;
    }

    _views[id] = FakeHtmlPlatformView(id, viewType);
    return Future<int>.sync(() => null);
  }

  Future<dynamic> _dispose(MethodCall call) {
    final int id = call.arguments;

    if (!_views.containsKey(id))
      throw PlatformException(
        code: 'error',
        message: 'Trying to dispose a platform view with unknown id: $id',
      );

    _views.remove(id);
    return Future<dynamic>.sync(() => null);
  }
}

class FakeAndroidPlatformView {
  FakeAndroidPlatformView(this.id, this.type, this.size, this.layoutDirection, [this.creationParams]);

  final int id;
  final String type;
  final Uint8List creationParams;
  Size size;
  int layoutDirection;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != FakeAndroidPlatformView)
      return false;
    final FakeAndroidPlatformView typedOther = other;
    return id == typedOther.id &&
           type == typedOther.type &&
           creationParams == typedOther.creationParams &&
           size == typedOther.size;
  }

  @override
  int get hashCode => hashValues(id, type, size, layoutDirection);

  @override
  String toString() {
    return 'FakeAndroidPlatformView(id: $id, type: $type, size: $size, layoutDirection: $layoutDirection, creationParams: $creationParams)';
  }
}

class FakeAndroidMotionEvent {
  const FakeAndroidMotionEvent(this.action, this.pointerIds, this.pointers);

  final int action;
  final List<Offset> pointers;
  final List<int> pointerIds;


  @override
  bool operator ==(dynamic other) {
    if (other is! FakeAndroidMotionEvent)
      return false;
    final FakeAndroidMotionEvent typedOther = other;
    const ListEquality<Offset> offsetsEq = ListEquality<Offset>();
    const ListEquality<int> pointersEq = ListEquality<int>();
    return pointersEq.equals(pointerIds, typedOther.pointerIds) &&
        action == typedOther.action &&
        offsetsEq.equals(pointers, typedOther.pointers);
  }

  @override
  int get hashCode => hashValues(action, hashList(pointers), hashList(pointerIds));

  @override
  String toString() {
    return 'FakeAndroidMotionEvent(action: $action, pointerIds: $pointerIds, pointers: $pointers)';
  }
}

class FakeUiKitView {
  FakeUiKitView(this.id, this.type, [this.creationParams]);

  final int id;
  final String type;
  final Uint8List creationParams;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != FakeUiKitView)
      return false;
    final FakeUiKitView typedOther = other;
    return id == typedOther.id &&
           type == typedOther.type &&
           creationParams == typedOther.creationParams;
  }

  @override
  int get hashCode => hashValues(id, type);

  @override
  String toString() {
    return 'FakeUiKitView(id: $id, type: $type, creationParams: $creationParams)';
  }
}

class FakeHtmlPlatformView {
  FakeHtmlPlatformView(this.id, this.type);

  final int id;
  final String type;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != FakeHtmlPlatformView)
      return false;
    final FakeHtmlPlatformView typedOther = other;
    return id == typedOther.id &&
           type == typedOther.type;
  }

  @override
  int get hashCode => hashValues(id, type);

  @override
  String toString() {
    return 'FakeHtmlPlatformView(id: $id, type: $type)';
  }
}
