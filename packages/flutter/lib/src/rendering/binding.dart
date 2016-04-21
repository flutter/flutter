// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show window;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:mojo/core.dart' as core;
import 'package:sky_services/semantics/semantics.mojom.dart' as mojom;

import 'box.dart';
import 'debug.dart';
import 'object.dart';
import 'view.dart';
import 'semantics.dart';

export 'package:flutter/gestures.dart' show HitTestResult;

/// The glue between the render tree and the Flutter engine.
abstract class RendererBinding extends BindingBase implements SchedulerBinding, ServicesBinding, HitTestable {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    ui.window.onMetricsChanged = handleMetricsChanged;
    initRenderView();
    initSemantics();
    assert(renderView != null);
    addPersistentFrameCallback(_handlePersistentFrameCallback);
  }

  /// The current [RendererBinding], if one has been created.
  static RendererBinding get instance => _instance;
  static RendererBinding _instance;

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    assert(() {
      // this service extension only works in checked mode
      registerBoolServiceExtension(
        name: 'debugPaint',
        getter: () => debugPaintSizeEnabled,
        setter: (bool value) {
          if (debugPaintSizeEnabled == value)
            return;
          debugPaintSizeEnabled = value;
          _forceRepaint();
        }
      );
      return true;
    });

    assert(() {
      // this service extension only works in checked mode
      registerBoolServiceExtension(
        name: 'repaintRainbow',
        getter: () => debugRepaintRainbowEnabled,
        setter: (bool value) {
          bool repaint = debugRepaintRainbowEnabled && !value;
          debugRepaintRainbowEnabled = value;
          if (repaint)
            _forceRepaint();
        }
      );
      return true;
    });
  }

  /// Creates a [RenderView] object to be the root of the
  /// [RenderObject] rendering tree, and initializes it so that it
  /// will be rendered when the engine is next ready to display a
  /// frame.
  ///
  /// Called automatically when the binding is created.
  void initRenderView() {
    if (renderView == null) {
      renderView = new RenderView();
      renderView.scheduleInitialFrame();
    }
    handleMetricsChanged(); // configures renderView's metrics
  }

  /// The render tree's owner, which maintains dirty state for layout,
  /// composite, paint, and accessibility semantics
  final PipelineOwner pipelineOwner = new PipelineOwner();

  /// The render tree that's attached to the output surface.
  RenderView get renderView => _renderView;
  RenderView _renderView;
  /// Sets the given [RenderView] object (which must not be null), and its tree, to
  /// be the new render tree to display. The previous tree, if any, is detached.
  void set renderView(RenderView value) {
    assert(value != null);
    if (_renderView == value)
      return;
    if (_renderView != null)
      _renderView.detach();
    _renderView = value;
    _renderView.attach(pipelineOwner);
  }

  /// Invoked when the system metrics change.
  ///
  /// See [ui.window.onMetricsChanged].
  void handleMetricsChanged() {
    assert(renderView != null);
    renderView.configuration = new ViewConfiguration(size: ui.window.size);
  }

  /// Prepares the rendering library to handle semantics requests from the engine.
  ///
  /// Called automatically when the binding is created.
  void initSemantics() {
    SemanticsNode.onSemanticsEnabled = renderView.scheduleInitialSemantics;
    shell.provideService(mojom.SemanticsServer.serviceName, (core.MojoMessagePipeEndpoint endpoint) {
      mojom.SemanticsServerStub server = new mojom.SemanticsServerStub.fromEndpoint(endpoint);
      server.impl = new SemanticsServer();
    });
  }

  void _handlePersistentFrameCallback(Duration timeStamp) {
    beginFrame();
  }

  /// Pump the rendering pipeline to generate a frame.
  ///
  /// Called automatically by the engine when it is time to lay out and paint a frame.
  void beginFrame() {
    assert(renderView != null);
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();
    renderView.compositeFrame(); // this sends the bits to the GPU
    if (SemanticsNode.hasListeners) {
      pipelineOwner.flushSemantics();
      SemanticsNode.sendSemanticsTree();
    }
  }

  @override
  void reassembleApplication() {
    super.reassembleApplication();
    pipelineOwner.reassemble(renderView);
  }

  @override
  void hitTest(HitTestResult result, Point position) {
    assert(renderView != null);
    renderView.hitTest(result, position: position);
    super.hitTest(result, position);
  }

  void _forceRepaint() {
    RenderObjectVisitor visitor;
    visitor = (RenderObject child) {
      child.markNeedsPaint();
      child.visitChildren(visitor);
    };
    instance?.renderView?.visitChildren(visitor);
  }
}

/// Prints a textual representation of the entire render tree.
void debugDumpRenderTree() {
  debugPrint(RendererBinding.instance?.renderView?.toStringDeep());
}

/// Prints a textual representation of the entire layer tree.
void debugDumpLayerTree() {
  debugPrint(RendererBinding.instance?.renderView?.layer?.toStringDeep());
}

/// Prints a textual representation of the entire semantics tree.
/// This will only work if there is a semantics client attached.
/// Otherwise, the tree is empty and this will print "null".
void debugDumpSemanticsTree() {
  debugPrint(RendererBinding.instance?.renderView?.debugSemantics?.toStringDeep() ?? 'Semantics not collected.');
}

/// A concrete binding for applications that use the Rendering framework
/// directly. This is the glue that binds the framework to the Flutter engine.
///
/// You would only use this binding if you are writing to the
/// rendering layer directly. If you are writing to a higher-level
/// library, such as the Flutter Widgets library, then you would use
/// that layer's binding.
///
/// See also [BindingBase].
class RenderingFlutterBinding extends BindingBase with SchedulerBinding, GestureBinding, ServicesBinding, RendererBinding {
  RenderingFlutterBinding({ RenderBox root }) {
    assert(renderView != null);
    renderView.child = root;
  }
}
