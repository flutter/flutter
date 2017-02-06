// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

abstract class SliverPersistentHeaderDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliverPersistentHeaderDelegate();

  Widget build(BuildContext context, double shrinkOffset);

  double get maxExtent;

  bool shouldRebuild(@checked SliverPersistentHeaderDelegate oldDelegate);
}

class SliverPersistentHeader extends StatelessWidget {
  SliverPersistentHeader({
    Key key,
    @required this.delegate,
    this.pinned: false,
    this.floating: false,
  }) : super(key: key) {
    assert(delegate != null);
    assert(pinned != null);
    assert(floating != null);
    assert(!pinned || !floating);
  }

  final SliverPersistentHeaderDelegate delegate;

  final bool pinned;

  final bool floating;

  @override
  Widget build(BuildContext context) {
    if (pinned)
      return new _SliverPinnedPersistentHeader(delegate: delegate);
    if (floating)
      return new _SliverFloatingPersistentHeader(delegate: delegate);
    return new _SliverScrollingPersistentHeader(delegate: delegate);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('delegate: $delegate');
    List<String> flags = <String>[];
    if (pinned)
      flags.add('pinned');
    if (floating)
      flags.add('floating');
    if (flags.isEmpty)
      flags.add('normal');
    description.add('mode: ${flags.join(", ")}');
  }
}

class _SliverPersistentHeaderElement extends RenderObjectElement {
  _SliverPersistentHeaderElement(_SliverPersistentHeaderRenderObjectWidget widget) : super(widget);

  @override
  _SliverPersistentHeaderRenderObjectWidget get widget => super.widget;

  @override
  _RenderSliverPersistentHeaderForWidgetsMixin get renderObject => super.renderObject;

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    renderObject._element = this;
  }

  @override
  void unmount() {
    super.unmount();
    renderObject._element = null;
  }

  @override
  void update(_SliverPersistentHeaderRenderObjectWidget newWidget) {
    final _SliverPersistentHeaderRenderObjectWidget oldWidget = widget;
    super.update(newWidget);
    final SliverPersistentHeaderDelegate newDelegate = newWidget.delegate;
    final SliverPersistentHeaderDelegate oldDelegate = oldWidget.delegate;
    if (newDelegate != oldDelegate &&
        (newDelegate.runtimeType != oldDelegate.runtimeType || newDelegate.shouldRebuild(oldDelegate)))
      renderObject.triggerRebuild();
  }

  @override
  void performRebuild() {
    renderObject.triggerRebuild();
  }

  Element child;

  void _build(double shrinkOffset) {
    owner.buildScope(this, () {
      child = updateChild(child, widget.delegate.build(this, shrinkOffset), null);
    });
  }

  @override
  void forgetChild(Element child) {
    assert(child == this.child);
    this.child = null;
  }

  @override
  void insertChildRenderObject(@checked RenderObject child, Null slot) {
    renderObject.child = child;
  }

  @override
  void moveChildRenderObject(@checked RenderObject child, Null slot) {
    assert(false);
  }

  @override
  void removeChildRenderObject(@checked RenderObject child) {
    renderObject.child = null;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    visitor(child);
  }
}

abstract class _SliverPersistentHeaderRenderObjectWidget extends RenderObjectWidget {
  _SliverPersistentHeaderRenderObjectWidget({
    Key key,
    @required this.delegate,
  }) : super(key: key) {
    assert(delegate != null);
  }

  final SliverPersistentHeaderDelegate delegate;

  @override
  _SliverPersistentHeaderElement createElement() => new _SliverPersistentHeaderElement(this);

  @override
  _RenderSliverPersistentHeaderForWidgetsMixin createRenderObject(BuildContext context);

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('delegate: $delegate');
  }
}

abstract class _RenderSliverPersistentHeaderForWidgetsMixin implements RenderSliverPersistentHeader {
  _SliverPersistentHeaderElement _element;

  @override
  double get maxExtent => _element.widget.delegate.maxExtent;

  @override
  void updateChild(double shrinkOffset) {
    assert(_element != null);
    _element._build(shrinkOffset);
  }

  @protected
  void triggerRebuild() {
    markNeedsUpdate();
  }
}

class _SliverScrollingPersistentHeader extends _SliverPersistentHeaderRenderObjectWidget {
  _SliverScrollingPersistentHeader({
    Key key,
    @required SliverPersistentHeaderDelegate delegate,
  }) : super(key: key, delegate: delegate);

  @override
  _RenderSliverPersistentHeaderForWidgetsMixin createRenderObject(BuildContext context) {
    return new _RenderSliverScrollingPersistentHeaderForWidgets();
  }
}

// This class exists to work around https://github.com/dart-lang/sdk/issues/15101
abstract class _RenderSliverScrollingPersistentHeader extends RenderSliverScrollingPersistentHeader { }

class _RenderSliverScrollingPersistentHeaderForWidgets extends _RenderSliverScrollingPersistentHeader
  with _RenderSliverPersistentHeaderForWidgetsMixin { }

class _SliverPinnedPersistentHeader extends _SliverPersistentHeaderRenderObjectWidget {
  _SliverPinnedPersistentHeader({
    Key key,
    @required SliverPersistentHeaderDelegate delegate,
  }) : super(key: key, delegate: delegate);

  @override
  _RenderSliverPersistentHeaderForWidgetsMixin createRenderObject(BuildContext context) {
    return new _RenderSliverPinnedPersistentHeaderForWidgets();
  }
}

// This class exists to work around https://github.com/dart-lang/sdk/issues/15101
abstract class _RenderSliverPinnedPersistentHeader extends RenderSliverPinnedPersistentHeader { }

class _RenderSliverPinnedPersistentHeaderForWidgets extends _RenderSliverPinnedPersistentHeader with _RenderSliverPersistentHeaderForWidgetsMixin { }

class _SliverFloatingPersistentHeader extends _SliverPersistentHeaderRenderObjectWidget {
  _SliverFloatingPersistentHeader({
    Key key,
    @required SliverPersistentHeaderDelegate delegate,
  }) : super(key: key, delegate: delegate);

  @override
  _RenderSliverPersistentHeaderForWidgetsMixin createRenderObject(BuildContext context) {
    return new _RenderSliverFloatingPersistentHeaderForWidgets();
  }
}

// This class exists to work around https://github.com/dart-lang/sdk/issues/15101
abstract class _RenderSliverFloatingPersistentHeader extends RenderSliverFloatingPersistentHeader { }

class _RenderSliverFloatingPersistentHeaderForWidgets extends _RenderSliverFloatingPersistentHeader with _RenderSliverPersistentHeaderForWidgetsMixin { }
