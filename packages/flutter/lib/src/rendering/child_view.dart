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
  int viewHandle = ui.takeViewHandle();
  assert(() {
    if (viewHandle == 0)
      debugPrint('Child view are supported only when running in Mojo shell.');
    return true;
  });
  return new mojom.ViewProxy.fromHandle(new core.MojoHandle(viewHandle));
}

// TODO(abarth): The view host is a unique resource. We should structure how we
// take the handle from the engine so that multiple libraries can interact with
// the view host safely. Unfortunately, the view host has a global namespace of
// view keys, which means any scheme for sharing the view host also needs to
// provide a mechanism for coordinating about view keys.
final mojom.ViewProxy _viewProxy = _initViewProxy();
final mojom.View _view = _viewProxy?.ptr;

class ChildViewConnection {
  ChildViewConnection({ this.url }) {
    mojom.ViewProviderProxy viewProvider = new mojom.ViewProviderProxy.unbound();
    shell.connectToService(url, viewProvider);
    mojom.ServiceProviderProxy incomingServices = new mojom.ServiceProviderProxy.unbound();
    mojom.ServiceProviderStub outgoingServices = new mojom.ServiceProviderStub.unbound();
    _viewOwner = new mojom.ViewOwnerProxy.unbound();
    viewProvider.ptr.createView(_viewOwner, incomingServices, outgoingServices);
    viewProvider.close();
    _connection = new ApplicationConnection(outgoingServices, incomingServices);
  }

  final String url;

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
    _view.addChild(_viewKey, _viewOwner.impl);
    _viewOwner = null;
  }

  void _removeChildFromViewHost() {
    assert(!_attached);
    assert(_viewOwner == null);
    assert(_viewKey != null);
    _viewOwner = new mojom.ViewOwnerProxy.unbound();
    _view.removeChild(_viewKey, _viewOwner);
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
    int width = (size.width * scale).round();
    int height = (size.height * scale).round();
    // TODO(abarth): Ideally we would propagate our actually constraints to be
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

  String toString() {
    return '$runtimeType(url: $url)';
  }
}

class RenderChildView extends RenderBox {
  RenderChildView({
    ChildViewConnection child,
    double scale
  }) : _child = child, _scale = scale;

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

  double get scale => _scale;
  double _scale;
  void set scale (double value) {
    if (value == _scale)
      return;
    _scale = value;
    if (_child != null)
      markNeedsLayout();
  }

  void attach() {
    super.attach();
    _child?._attach();
  }

  void detach() {
    _child?._detach();
    super.detach();
  }

  bool get alwaysNeedsCompositing => true;
  bool get sizedByParent => true;

  void performResize() {
    size = constraints.biggest;
  }

  void performLayout() {
    if (_child != null)
      _child._layout(size: size, scale: scale).then(_handleLayoutInfoChanged);
  }

  mojom.ViewLayoutInfo _layoutInfo;

  void _handleLayoutInfoChanged(mojom.ViewLayoutInfo layoutInfo) {
    _layoutInfo = layoutInfo;
    markNeedsPaint();
  }

  bool hitTestSelf(Point position) => true;

  void paint(PaintingContext context, Offset offset) {
    assert(needsCompositing);
    if (_layoutInfo != null)
      context.pushChildScene(offset, _layoutInfo);
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('child: $child');
    description.add('scale: $scale');
  }
}
