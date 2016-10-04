// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

abstract class SliverAppBarDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliverAppBarDelegate();

  Widget build(BuildContext context, double shrinkOffset);

  double get maxExtent;

  bool shouldRebuild(@checked SliverAppBarDelegate oldDelegate);
}

class SliverAppBar extends StatelessWidget {
  SliverAppBar({
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

  final SliverAppBarDelegate delegate;

  final bool pinned;

  final bool floating;

  @override
  Widget build(BuildContext context) {
    if (pinned)
      return new _SliverPinnedAppBar(delegate: delegate);
    if (floating)
      return new _SliverFloatingAppBar(delegate: delegate);
    return new _SliverScrollingAppBar(delegate: delegate);
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

class _SliverAppBarElement extends RenderObjectElement {
  _SliverAppBarElement(_SliverAppBarRenderObjectWidget widget) : super(widget);

  @override
  _SliverAppBarRenderObjectWidget get widget => super.widget;

  @override
  _RenderSliverAppBarForWidgetsMixin get renderObject => super.renderObject;

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
  void update(_SliverAppBarRenderObjectWidget newWidget) {
    final _SliverAppBarRenderObjectWidget oldWidget = widget;
    super.update(newWidget);
    final SliverAppBarDelegate newDelegate = newWidget.delegate;
    final SliverAppBarDelegate oldDelegate = oldWidget.delegate;
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

abstract class _SliverAppBarRenderObjectWidget extends RenderObjectWidget {
  _SliverAppBarRenderObjectWidget({
    Key key,
    @required this.delegate,
  }) : super(key: key) {
    assert(delegate != null);
  }

  final SliverAppBarDelegate delegate;

  @override
  _SliverAppBarElement createElement() => new _SliverAppBarElement(this);

  @override
  _RenderSliverAppBarForWidgetsMixin createRenderObject(BuildContext context);

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('delegate: $delegate');
  }
}

abstract class _RenderSliverAppBarForWidgetsMixin implements RenderSliverAppBar {
  _SliverAppBarElement _element;

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

class _SliverScrollingAppBar extends _SliverAppBarRenderObjectWidget {
  _SliverScrollingAppBar({
    Key key,
    @required SliverAppBarDelegate delegate,
  }) : super(key: key, delegate: delegate);

  @override
  _RenderSliverAppBarForWidgetsMixin createRenderObject(BuildContext context) {
    return new _RenderSliverScrollingAppBarForWidgets();
  }
}

// This class exists to work around https://github.com/dart-lang/sdk/issues/15101
abstract class _RenderSliverScrollingAppBar extends RenderSliverScrollingAppBar { }

class _RenderSliverScrollingAppBarForWidgets extends _RenderSliverScrollingAppBar
  with _RenderSliverAppBarForWidgetsMixin { }

class _SliverPinnedAppBar extends _SliverAppBarRenderObjectWidget {
  _SliverPinnedAppBar({
    Key key,
    @required SliverAppBarDelegate delegate,
  }) : super(key: key, delegate: delegate);

  @override
  _RenderSliverAppBarForWidgetsMixin createRenderObject(BuildContext context) {
    return new _RenderSliverPinnedAppBarForWidgets();
  }
}

// This class exists to work around https://github.com/dart-lang/sdk/issues/15101
abstract class _RenderSliverPinnedAppBar extends RenderSliverPinnedAppBar { }

class _RenderSliverPinnedAppBarForWidgets extends _RenderSliverPinnedAppBar with _RenderSliverAppBarForWidgetsMixin { }

class _SliverFloatingAppBar extends _SliverAppBarRenderObjectWidget {
  _SliverFloatingAppBar({
    Key key,
    @required SliverAppBarDelegate delegate,
  }) : super(key: key, delegate: delegate);

  @override
  _RenderSliverAppBarForWidgetsMixin createRenderObject(BuildContext context) {
    return new _RenderSliverFloatingAppBarForWidgets();
  }
}

// This class exists to work around https://github.com/dart-lang/sdk/issues/15101
abstract class _RenderSliverFloatingAppBar extends RenderSliverFloatingAppBar { }

class _RenderSliverFloatingAppBarForWidgets extends _RenderSliverFloatingAppBar with _RenderSliverAppBarForWidgetsMixin { }
