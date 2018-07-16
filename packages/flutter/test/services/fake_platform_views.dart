// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

class FakePlatformViewsController {
  FakePlatformViewsController(this.targetPlatform) : assert(targetPlatform != null) {
    SystemChannels.platform_views.setMockMethodCallHandler(_onMethodCall);
  }

  final TargetPlatform targetPlatform;
  final Map<int, FakePlatformView> _views = <int, FakePlatformView>{};
  final Set<String> _registeredViewTypes = new Set<String>();

  int _textureCounter = 0;

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
    }
    return new Future<Null>.sync(() => null);
  }

  Future<dynamic> _create(MethodCall call) {
    final Map<dynamic, dynamic> args = call.arguments;
    final int id = args['id'];
    final String viewType = args['viewType'];
    final double width = args['width'];
    final double height = args['height'];

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

    _views[id] = new FakePlatformView(id, viewType, new Size(width, height));
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

  Future<dynamic> _resize(MethodCall call) {
    final Map<dynamic, dynamic> args = call.arguments;
    final int id = args['id'];
    final double width = args['width'];
    final double height = args['height'];

    if (!_views.containsKey(id))
      throw new PlatformException(
        code: 'error',
        message: 'Trying to resize a platform view with unknown id: $id',
      );

    _views[id].size = new Size(width, height);

    return new Future<Null>.sync(() => null);
  }

  Iterable<FakePlatformView> get views => _views.values;
}

class FakePlatformView {

  FakePlatformView(this.id, this.type, this.size);

  final int id;
  final String type;
  Size size;

  @override
  bool operator ==(dynamic other) {
    if (other is! FakePlatformView)
      return false;
    final FakePlatformView typedOther = other;
    return id == typedOther.id &&
        type == typedOther.type &&
        size == typedOther.size;
  }

  @override
  int get hashCode => hashValues(id, type, size);

  @override
  String toString() {
    return 'FakePlatformView(id: $id, type: $type, size: $size)';
  }
}
