// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'box.dart';
import 'layer.dart';
import 'object.dart';


enum _PlatformViewState {
  uninitialized,
  resizing,
  ready,
}

/// A render object for an Android view.
///
/// [RenderAndroidView] is responsible for sizing and displaying the Android view.
///
/// See also:
///  * [AndroidView] which is a widget that is typically used to show an Android view.
///  * [PlatformViewsService] which is a service for controlling platform views.
class RenderAndroidView extends RenderBox {

  /// Creates a render object for an Android view.
  RenderAndroidView({
    @required AndroidViewController viewController,
  }) : assert(viewController != null),
       _viewController = viewController;

  _PlatformViewState _state = _PlatformViewState.uninitialized;

  /// The Android view controller for the Android view associated with this render object.
  AndroidViewController get viewcontroller => _viewController;
  AndroidViewController _viewController;
  /// Sets a new Android view controller.
  ///
  /// `viewController` must not be null.
  set viewController(AndroidViewController viewController) {
    assert(_viewController != null);
    _viewController = viewController;
    _sizePlatformView();
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  void performResize() {
    size = constraints.biggest;
    _sizePlatformView();
  }

  Future<Null> _sizePlatformView() async {
    if (_state == _PlatformViewState.resizing) {
      return;
    }

    _state = _PlatformViewState.resizing;

    Size targetSize;
    do {
      targetSize = size;
      await _viewController.setSize(size);
      // We've resized the platform view to targetSize, but it is possible that
      // while we were resizing the render object's size was changed again.
      // In that case we will re-iterate to resize the platform view again.
    } while (size != targetSize);

    _state = _PlatformViewState.ready;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_viewController.textureId == null)
      return;

    context.addLayer(new TextureLayer(
      rect: new Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
      textureId: _viewController.textureId,
    ));
  }
}
