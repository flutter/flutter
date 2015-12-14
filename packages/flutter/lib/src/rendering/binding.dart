// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'box.dart';
import 'debug.dart';
import 'object.dart';
import 'view.dart';

export 'package:flutter/gestures.dart' show HitTestResult;

/// The glue between the render tree and the Flutter engine.
abstract class Renderer extends Scheduler
  implements HitTestable {

  void initInstances() {
    super.initInstances();
    _instance = this;
    ui.window.onMetricsChanged = handleMetricsChanged;
    initRenderView();
    addPersistentFrameCallback(_handlePersistentFrameCallback);
  }

  static Renderer _instance;
  static Renderer get instance => _instance;

  void initRenderView() {
    if (renderView == null) {
      renderView = new RenderView();
      renderView.scheduleInitialFrame();
    }
    handleMetricsChanged(); // configures _renderView's metrics
  }

  /// The render tree that's attached to the output surface.
  RenderView get renderView => _renderView;
  RenderView _renderView;
  void set renderView(RenderView value) {
    if (_renderView == value)
      return;
    if (_renderView != null)
      _renderView.detach();
    _renderView = value;
    if (_renderView != null)
      _renderView.attach();
  }

  void handleMetricsChanged() {
    _renderView.rootConstraints = new ViewConstraints(size: ui.window.size);
  }

  void _handlePersistentFrameCallback(Duration timeStamp) {
    beginFrame();
  }

  /// Pump the rendering pipeline to generate a frame.
  void beginFrame() {
    RenderObject.flushLayout();
    _renderView.updateCompositingBits();
    RenderObject.flushPaint();
    _renderView.compositeFrame();
  }

  void hitTest(HitTestResult result, Point position) {
    _renderView.hitTest(result, position: position);
    super.hitTest(result, position);
  }
}

/// Prints a textual representation of the entire render tree.
void debugDumpRenderTree() {
  debugPrint(Renderer.instance.renderView.toStringDeep());
}

/// Prints a textual representation of the entire layer tree.
void debugDumpLayerTree() {
  debugPrint(Renderer.instance.renderView.layer.toStringDeep());
}

/// A concrete binding for applications that use the Rendering framework
/// directly. This is the glue that binds the framework to the Flutter engine.
class RenderingFlutterBinding extends BindingBase with Scheduler, Renderer, Gesturer {
  RenderingFlutterBinding({ RenderBox root }) {
    renderView.child = root;
  }
}
