// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'package:collection/collection.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

class FakePlatformViewsController {
  FakePlatformViewsController(this.targetPlatform) : assert(targetPlatform != null) {
    SystemChannels.platform_views.setMockMethodCallHandler(_onMethodCall);
  }

  final TargetPlatform targetPlatform;

  Iterable<FakePlatformView> get views => _views.values;
  final Map<int, FakePlatformView> _views = <int, FakePlatformView>{};

  final Map<int, List<FakeMotionEvent>> motionEvents = <int, List<FakeMotionEvent>>{};

  final Set<String> _registeredViewTypes = new Set<String>();

  int _textureCounter = 0;

  Completer<void> resizeCompleter;

  void registerViewType(String viewType) {
    _registeredViewTypes.add(viewType);
  }

  Future<dynamic> _onMethodCall(MethodCall call) {
    if (targetPlatform == TargetPlatform.android)
      return _onMethodCallAndroid(call);
    return new Future<Null>.sync(() => null);
  }

  Future<dynamic> _onMethodCallAndroid(MethodCall call) {
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
    }
    return new Future<Null>.sync(() => null);
  }

  Future<dynamic> _create(MethodCall call) {
    final Map<dynamic, dynamic> args = call.arguments;
    final int id = args['id'];
    final String viewType = args['viewType'];
    final double width = args['width'];
    final double height = args['height'];
    final int layoutDirection = args['direction'];
    final Uint8List creationParams = args['params'];

    if (_views.containsKey(id))
      throw new PlatformException(
        code: 'error',
        message: 'Trying to create an already created platform view, view id: $id',
      );

    if (!_registeredViewTypes.contains(viewType))
      throw new PlatformException(
        code: 'error',
        message: 'Trying to create a platform view of unregistered type: $viewType',
      );

    _views[id] = new FakePlatformView(id, viewType, new Size(width, height), layoutDirection, creationParams);
    final int textureId = _textureCounter++;
    return new Future<int>.sync(() => textureId);
  }

  Future<dynamic> _dispose(MethodCall call) {
    final int id = call.arguments;

    if (!_views.containsKey(id))
      throw new PlatformException(
        code: 'error',
        message: 'Trying to dispose a platform view with unknown id: $id',
      );

    _views.remove(id);
    return new Future<Null>.sync(() => null);
  }

  Future<dynamic> _resize(MethodCall call) async {
    final Map<dynamic, dynamic> args = call.arguments;
    final int id = args['id'];
    final double width = args['width'];
    final double height = args['height'];

    if (!_views.containsKey(id))
      throw new PlatformException(
        code: 'error',
        message: 'Trying to resize a platform view with unknown id: $id',
      );

    if (resizeCompleter != null) {
      await resizeCompleter.future;
    }
    _views[id].size = new Size(width, height);

    return new Future<Null>.sync(() => null);
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
      pointerOffsets.add(new Offset(x, y));
    }

    if (!motionEvents.containsKey(id))
      motionEvents[id] = <FakeMotionEvent> [];

    motionEvents[id].add(new FakeMotionEvent(action, pointerIds, pointerOffsets));
    return new Future<Null>.sync(() => null);
  }

  Future<dynamic> _setDirection(MethodCall call) async {
    final Map<dynamic, dynamic> args = call.arguments;
    final int id = args['id'];
    final int layoutDirection = args['direction'];

    if (!_views.containsKey(id))
      throw new PlatformException(
        code: 'error',
        message: 'Trying to resize a platform view with unknown id: $id',
      );

    _views[id].layoutDirection = layoutDirection;

    return new Future<Null>.sync(() => null);
  }
}

class FakePlatformView {

  FakePlatformView(this.id, this.type, this.size, this.layoutDirection, [this.creationParams]);

  final int id;
  final String type;
  final Uint8List creationParams;
  Size size;
  int layoutDirection;

  @override
  bool operator ==(dynamic other) {
    if (other is! FakePlatformView)
      return false;
    final FakePlatformView typedOther = other;
    return id == typedOther.id &&
        type == typedOther.type &&
        creationParams == typedOther.creationParams &&
        size == typedOther.size;
  }

  @override
  int get hashCode => hashValues(id, type, size, layoutDirection);

  @override
  String toString() {
    return 'FakePlatformView(id: $id, type: $type, size: $size, layoutDirection: $layoutDirection, creationParams: $creationParams)';
  }
}

class FakeMotionEvent {
  const FakeMotionEvent(this.action, this.pointerIds, this.pointers);

  final int action;
  final List<Offset> pointers;
  final List<int> pointerIds;


  @override
  bool operator ==(dynamic other) {
    if (other is! FakeMotionEvent)
      return false;
    final FakeMotionEvent typedOther = other;
    const ListEquality<Offset> offsetsEq = ListEquality<Offset>();
    const ListEquality<int> pointersEq = ListEquality<int>();
    return pointersEq.equals(pointerIds, typedOther.pointerIds) &&
        action == typedOther.action &&
        offsetsEq.equals(pointers, typedOther.pointers);
  }

  @override
  int get hashCode => hashValues(action, pointers, pointerIds);

  @override
  String toString() {
    return 'FakeMotionEvent(action: $action, pointerIds: $pointerIds, pointers: $pointers)';
  }
}
