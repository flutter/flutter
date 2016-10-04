// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_services/mozart/composition/scene_token.dart' as mojom;
import 'package:flutter_services/mozart/views/view_containers.dart' as mojom;
import 'package:flutter_services/mozart/views/view_provider.dart' as mojom;
import 'package:flutter_services/mozart/views/view_properties.dart' as mojom;
import 'package:flutter_services/mozart/views/view_token.dart' as mojom;
import 'package:flutter_services/mozart/views/views.dart' as mojom;
import 'package:flutter_services/mojo/geometry.dart' as mojom;
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
final mojom.View _view = _viewProxy;

mojom.ViewContainer _initViewContainer() {
  if (_view == null)
    return null;
  mojom.ViewContainerProxy viewContainerProxy = new mojom.ViewContainerProxy.unbound();
  _view.getContainer(viewContainerProxy);
  viewContainerProxy.setListener(new mojom.ViewContainerListenerStub.unbound()..impl = _ViewContainerListenerImpl.instance);
  return viewContainerProxy;
}

final mojom.ViewContainer _viewContainer = _initViewContainer();

typedef dynamic _ResponseFactory();

class _ViewContainerListenerImpl extends mojom.ViewContainerListener {
  static final _ViewContainerListenerImpl instance = new _ViewContainerListenerImpl();

  @override
  dynamic onChildAttached(int childKey, mojom.ViewInfo childViewInfo, [_ResponseFactory responseFactory = null]) {
    ChildViewConnection connection = _connections[childKey];
    connection?._onAttachedToContainer(childViewInfo);
    return responseFactory();
  }

  @override
  dynamic onChildUnavailable(int childKey, [_ResponseFactory responseFactory = null]) {
    ChildViewConnection connection = _connections[childKey];
    connection?._onUnavailable();
    return responseFactory();
  }

  final Map<int, ChildViewConnection> _connections = new HashMap<int, ChildViewConnection>();
}

/// (mojo-only) A connection with a child view.
///
/// Used with the [ChildView] widget to display a child view.
class ChildViewConnection {
  /// Establishes a connection to the app at the given URL.
  ChildViewConnection({ String url }) {
    mojom.ViewProviderProxy viewProvider = shell.connectToApplicationService(
      url, mojom.ViewProvider.connectToService
    );
    mojom.ServiceProviderProxy incomingServices = new mojom.ServiceProviderProxy.unbound();
    _viewOwner = new mojom.ViewOwnerProxy.unbound();
    viewProvider.createView(_viewOwner, incomingServices);
    viewProvider.close();
    _connection = new ApplicationConnection(null, incomingServices);
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

  int _sceneVersion = 1;
  mojom.ViewProperties _currentViewProperties;

  VoidCallback _onViewInfoAvailable;
  mojom.ViewInfo _viewInfo;

  void _onAttachedToContainer(mojom.ViewInfo viewInfo) {
    assert(_viewInfo == null);
    _viewInfo = viewInfo;
    if (_onViewInfoAvailable != null)
      _onViewInfoAvailable();
  }

  void _onUnavailable() {
    _viewInfo = null;
  }

  void _addChildToViewHost() {
    assert(_attached);
    assert(_viewOwner != null);
    assert(_viewKey == null);
    assert(_viewInfo == null);
    _viewKey = _nextViewKey++;
    _viewContainer?.addChild(_viewKey, _viewOwner);
    _viewOwner = null;
    assert(!_ViewContainerListenerImpl.instance._connections.containsKey(_viewKey));
    _ViewContainerListenerImpl.instance._connections[_viewKey] = this;
  }

  void _removeChildFromViewHost() {
    assert(!_attached);
    assert(_viewOwner == null);
    assert(_viewKey != null);
    assert(_ViewContainerListenerImpl.instance._connections[_viewKey] == this);
    _ViewContainerListenerImpl.instance._connections.remove(_viewKey);
    _viewOwner = new mojom.ViewOwnerProxy.unbound();
    _viewContainer?.removeChild(_viewKey, _viewOwner);
    _viewKey = null;
    _viewInfo = null;
    _currentViewProperties = null;
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

  mojom.ViewProperties _createViewProperties(int physicalWidth,
                                             int physicalHeight,
                                             double devicePixelRatio) {
    if (_currentViewProperties != null &&
        _currentViewProperties.displayMetrics.devicePixelRatio == devicePixelRatio &&
        _currentViewProperties.viewLayout.size.width == physicalWidth &&
        _currentViewProperties.viewLayout.size.height == physicalHeight)
      return null;

    mojom.DisplayMetrics displayMetrics = new mojom.DisplayMetrics()
      ..devicePixelRatio = devicePixelRatio;
    mojom.Size size = new mojom.Size()
      ..width = physicalWidth
      ..height = physicalHeight;
    mojom.ViewLayout viewLayout = new mojom.ViewLayout()
      ..size = size;
    _currentViewProperties = new mojom.ViewProperties()
      ..displayMetrics = displayMetrics
      ..viewLayout = viewLayout;
    return _currentViewProperties;
  }

  void _setChildProperties(int physicalWidth, int physicalHeight, double devicePixelRatio) {
    assert(_attached);
    assert(_attachments == 1);
    assert(_viewKey != null);
    if (_view == null)
      return;
    mojom.ViewProperties viewProperties = _createViewProperties(physicalWidth, physicalHeight, devicePixelRatio);
    if (viewProperties == null)
      return;
    _viewContainer.setChildProperties(_viewKey, _sceneVersion++, viewProperties);
  }
}

/// (mojo-only) A view of a child application.
class RenderChildView extends RenderBox {
  /// Creates a child view render object.
  ///
  /// The [scale] argument must not be null.
  RenderChildView({
    ChildViewConnection child,
    double scale
  }) : _scale = scale {
    assert(scale != null);
    this.child = child;
  }

  /// The child to display.
  ChildViewConnection get child => _child;
  ChildViewConnection _child;
  set child (ChildViewConnection value) {
    if (value == _child)
      return;
    if (attached && _child != null) {
      _child._detach();
      assert(_child._onViewInfoAvailable != null);
      _child._onViewInfoAvailable = null;
    }
    _child = value;
    if (attached && _child != null) {
      _child._attach();
      assert(_child._onViewInfoAvailable == null);
      _child._onViewInfoAvailable = markNeedsPaint;
    }
    if (_child == null) {
      markNeedsPaint();
    } else {
      markNeedsLayout();
    }
  }

  /// The device pixel ratio to provide the child.
  double get scale => _scale;
  double _scale;
  set scale (double value) {
    assert(value != null);
    if (value == _scale)
      return;
    _scale = value;
    if (_child != null)
      markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (_child != null) {
      _child._attach();
      assert(_child._onViewInfoAvailable == null);
      _child._onViewInfoAvailable = markNeedsPaint;
    }
  }

  @override
  void detach() {
    if (_child != null) {
      _child._detach();
      assert(_child._onViewInfoAvailable != null);
      _child._onViewInfoAvailable = null;
    }
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  TextPainter _debugErrorMessage;

  int _physicalWidth;
  int _physicalHeight;

  @override
  void performLayout() {
    size = constraints.biggest;
    if (_child != null) {
      _physicalWidth = (size.width * scale).round();
      _physicalHeight = (size.height * scale).round();
      _child._setChildProperties(_physicalWidth, _physicalHeight, scale);
      assert(() {
        if (_view == null) {
          _debugErrorMessage ??= new TextPainter(
            text: new TextSpan(text: 'Child views are supported only when running in Mojo shell.')
          );
          _debugErrorMessage.layout(minWidth: size.width, maxWidth: size.width);
        }
        return true;
      });
    }
  }

  @override
  bool hitTestSelf(Point position) => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(needsCompositing);
    if (_child?._viewInfo != null)
      context.pushChildScene(offset, scale, _physicalWidth, _physicalHeight, _child._viewInfo.sceneToken);
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
