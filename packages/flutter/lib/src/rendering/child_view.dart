// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:mojo_services/mojo/gfx/composition/scene_token.mojom.dart' as mojom;
import 'package:mojo_services/mojo/ui/layouts.mojom.dart' as mojom;
import 'package:mojo_services/mojo/ui/view_provider.mojom.dart' as mojom;
import 'package:mojo_services/mojo/ui/views.mojom.dart' as mojom;
import 'package:mojo/application.dart';
import 'package:mojo/core.dart' as core;
import 'package:mojo/mojo/service_provider.mojom.dart' as mojom;

import 'box.dart';
import 'object.dart';

mojom.ViewProxy _initViewProxy() {
  int viewHandle = ui.MojoServices.takeView();
  if (viewHandle == core.MojoHandle.INVALID)
    return null;
  return new mojom.ViewProxy.fromHandle(new core.MojoHandle(viewHandle));
}

// TODO(abarth): The view host is a unique resource. We should structure how we
// take the handle from the engine so that multiple libraries can interact with
// the view host safely. Unfortunately, the view host has a global namespace of
// view keys, which means any scheme for sharing the view host also needs to
// provide a mechanism for coordinating about view keys.
final mojom.ViewProxy _viewProxy = _initViewProxy();
final mojom.View _view = _viewProxy?.ptr;

/// (mojo-only) A connection with a child view.
///
/// Used with the [ChildView] widget to display a child view.
class ChildViewConnection {
  /// Establishes a connection to the app at the given URL.
  ChildViewConnection({ String url }) {
    mojom.ViewProviderProxy viewProvider = new mojom.ViewProviderProxy.unbound();
    shell.connectToService(url, viewProvider);
    mojom.ServiceProviderProxy incomingServices = new mojom.ServiceProviderProxy.unbound();
    mojom.ServiceProviderStub outgoingServices = new mojom.ServiceProviderStub.unbound();
    _viewOwner = new mojom.ViewOwnerProxy.unbound();
    viewProvider.ptr.createView(_viewOwner, incomingServices, outgoingServices);
    viewProvider.close();
    _connection = new ApplicationConnection(outgoingServices, incomingServices);
  }

  /// Wraps an already-established connection to a child app.
  ChildViewConnection.fromViewOwner({
    mojom.ViewOwnerProxy viewOwner,
    ApplicationConnection connection
  }) : _connection = connection, _viewOwner = viewOwner;

  /// The underlying application connection to the child app.
  ///
  /// Useful for requesting services from the child app and for providing
  /// services to the child app.
  ApplicationConnection get connection => _connection;
  ApplicationConnection _connection;

  mojom.ViewOwnerProxy _viewOwner;

  static int _nextViewKey = 1;
  int _viewKey;

  void _addChildToViewHost() {
    assert(_attached);
    assert(_viewOwner != null);
    assert(_viewKey == null);
    _viewKey = _nextViewKey++;
    _view?.addChild(_viewKey, _viewOwner.impl);
    _viewOwner = null;
  }

  void _removeChildFromViewHost() {
    assert(!_attached);
    assert(_viewOwner == null);
    assert(_viewKey != null);
    _viewOwner = new mojom.ViewOwnerProxy.unbound();
    _view?.removeChild(_viewKey, _viewOwner);
    _viewKey = null;
  }

  // The number of render objects attached to this view. In between frames, we
  // might have more than one connected if we get added to a new render object
  // before we get removed from the old render object. By the time we get around
  // to computing our layout, we must be back to just having one render object.
  int _attachments = 0;
  bool get _attached => _attachments > 0;

  void _attach() {
    assert(_attachments >= 0);
    ++_attachments;
    if (_viewKey == null)
      _addChildToViewHost();
  }

  void _detach() {
    assert(_attached);
    --_attachments;
    scheduleMicrotask(_removeChildFromViewHostIfNeeded);
  }

  void _removeChildFromViewHostIfNeeded() {
    assert(_attachments >= 0);
    if (_attachments == 0)
      _removeChildFromViewHost();
  }

  Future<mojom.ViewLayoutInfo> _layout({ Size size, double scale }) async {
    assert(_attached);
    assert(_attachments == 1);
    assert(_viewKey != null);
    if (_view == null)
      return new Future<mojom.ViewLayoutInfo>.value(null);
    int width = (size.width * scale).round();
    int height = (size.height * scale).round();
    // TODO(abarth): Ideally we would propagate our actual constraints to be
    // able to support rich cross-app layout. For now, we give the child tight
    // constraints for simplicity.
    mojom.BoxConstraints childConstraints = new mojom.BoxConstraints()
      ..minWidth = width
      ..maxWidth = width
      ..minHeight = height
      ..maxHeight = height;
    mojom.ViewLayoutParams layoutParams = new mojom.ViewLayoutParams()
      ..constraints = childConstraints
      ..devicePixelRatio = scale;
    return (await _view.layoutChild(_viewKey, layoutParams)).info;
  }
}

/// (mojo-only) A view of a child application.
class RenderChildView extends RenderBox {
  RenderChildView({
    ChildViewConnection child,
    double scale
  }) : _child = child, _scale = scale;

  /// The child to display.
  ChildViewConnection get child => _child;
  ChildViewConnection _child;
  void set child (ChildViewConnection value) {
    if (value == _child)
      return;
    if (attached)
      _child?._detach();
    _child = value;
    _layoutInfo = null;
    if (attached)
      _child?._attach();
    if (_child == null) {
      markNeedsPaint();
    } else {
      markNeedsLayout();
    }
  }

  /// The device pixel ratio to provide the child.
  double get scale => _scale;
  double _scale;
  void set scale (double value) {
    if (value == _scale)
      return;
    _scale = value;
    if (_child != null)
      markNeedsLayout();
  }

  @override
  void attach() {
    super.attach();
    _child?._attach();
  }

  @override
  void detach() {
    _child?._detach();
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  TextPainter _debugErrorMessage;

  @override
  void performLayout() {
    if (_child != null) {
      _child._layout(size: size, scale: scale).then(_handleLayoutInfoChanged);
      assert(() {
        if (_view == null) {
          _debugErrorMessage ??= new TextPainter()
            ..text = new TextSpan(text: 'Child view are supported only when running in Mojo shell.');
          _debugErrorMessage
            ..minWidth = size.width
            ..maxWidth = size.width
            ..minHeight = size.height
            ..maxHeight = size.height
            ..layout();
        }
        return true;
      });
    }
  }

  mojom.ViewLayoutInfo _layoutInfo;

  void _handleLayoutInfoChanged(mojom.ViewLayoutInfo layoutInfo) {
    _layoutInfo = layoutInfo;
    markNeedsPaint();
  }

  @override
  bool hitTestSelf(Point position) => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(needsCompositing);
    if (_layoutInfo != null)
      context.pushChildScene(offset, scale, _layoutInfo);
    assert(() {
      if (_view == null) {
        context.canvas.drawRect(offset & size, new Paint()..color = const Color(0xFF0000FF));
        _debugErrorMessage.paint(context.canvas, offset);
      }
      return true;
    });
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('child: $child');
    description.add('scale: $scale');
  }
}
