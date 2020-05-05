// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class AndroidPlatformView extends StatelessWidget {
  /// Creates a platform view for Android, which is rendered as a
  /// native view.
  /// `viewType` identifies the type of Android view to create.
  const AndroidPlatformView({
    Key key,
    @required this.viewType,
  }) : assert(viewType != null),
       super(key: key);

  /// The unique identifier for the view type to be embedded by this widget.
  ///
  /// A PlatformViewFactory for this type must have been registered.
  final String viewType;

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: viewType,
      onCreatePlatformView: _onCreateAndroidView,
      surfaceFactory: (BuildContext context, PlatformViewController controller) {
        return PlatformViewSurface(
          controller: controller,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
    );
  }

  PlatformViewController _onCreateAndroidView(PlatformViewCreationParams params) {
    final _AndroidViewController controller = _AndroidViewController(params.id, viewType);
    controller._initialize().then((_) { params.onPlatformViewCreated(params.id); });
    return controller;
  }
}

// TODO(egarciad): The Android view controller should be defined in the framework.
// https://github.com/flutter/flutter/issues/55904
class _AndroidViewController extends PlatformViewController {
  _AndroidViewController(
    this.viewId,
    this.viewType,
  );

  @override
  final int viewId;

  /// The unique identifier for the Android view type to be embedded by this widget.
  ///
  /// A PlatformViewFactory for this type must have been registered.
  final String viewType;

  bool _initialized = false;

  Future<void> _initialize() async {
    // TODO(egarciad): Initialize platform view.
    _initialized = true;
  }

  @override
  void clearFocus() {
    // TODO(egarciad): Implement clear focus.
  }

  @override
  void dispatchPointerEvent(PointerEvent event) {
    // TODO(egarciad): Implement dispatchPointerEvent
  }

  @override
  void dispose() {
    if (_initialized) {
      // TODO(egarciad): Dispose the android view.
    }
  }
}
