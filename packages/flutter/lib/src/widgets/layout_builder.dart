// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'debug.dart';
import 'framework.dart';

import 'package:flutter/rendering.dart';

/// The signature of the [LayoutBuilder] builder function.
typedef Widget LayoutWidgetBuilder(BuildContext context, Size size);

/// Builds a widget tree that can depend on the parent widget's size.
///
/// Similar to the [Builder] widget except that the framework calls the [builder]
/// function at layout time and provides the parent widget's size. This is useful
/// when the parent constrains the child's size and doesn't depend on the child's
/// intrinsic size.
class LayoutBuilder extends RenderObjectWidget {
  LayoutBuilder({ Key key, this.builder }) : super(key: key);

  /// Called at layout time to construct the widget tree. The builder must not
  /// return null.
  final LayoutWidgetBuilder builder;

  @override
  _LayoutBuilderElement createElement() => new _LayoutBuilderElement(this);

  @override
  _RenderLayoutBuilder createRenderObject(BuildContext context) => new _RenderLayoutBuilder();
}

class _RenderLayoutBuilder extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  _RenderLayoutBuilder({ LayoutCallback callback }) : _callback = callback;

  LayoutCallback get callback => _callback;
  LayoutCallback _callback;
  void set callback(LayoutCallback value) {
    if (value == _callback)
      return;
    _callback = value;
    markNeedsLayout();
  }

  double getIntrinsicWidth(BoxConstraints constraints) => constraints.constrainWidth();

  double getIntrinsicHeight(BoxConstraints constraints) => constraints.constrainHeight();

  @override
  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    return getIntrinsicWidth(constraints);
  }

  @override
  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    return getIntrinsicWidth(constraints);
  }

  @override
  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    return getIntrinsicHeight(constraints);
  }

  @override
  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    return getIntrinsicHeight(constraints);
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void performLayout() {
    if (callback != null)
      invokeLayoutCallback(callback);
    if (child != null)
      child.layout(constraints.loosen(), parentUsesSize: false);
  }

  @override
  bool hitTestChildren(HitTestResult result, { Point position }) {
    return child?.hitTest(result, position: position) ?? false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.paintChild(child, offset);
  }
}

class _LayoutBuilderElement extends RenderObjectElement {
  _LayoutBuilderElement(LayoutBuilder widget) : super(widget);

  @override
  LayoutBuilder get widget => super.widget;

  @override
  _RenderLayoutBuilder get renderObject => super.renderObject;

  Element _child;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);    // Creates the renderObject.
    renderObject.callback = _layout; // The _child will be built during layout.
  }

  @override
  void update(LayoutBuilder newWidget) {
    assert(widget != newWidget);
    super.update(newWidget);
    assert(widget == newWidget);
    renderObject.callback = _layout;
    renderObject.markNeedsLayout();
  }

  @override
  void unmount() {
    renderObject.callback = null;
    super.unmount();
  }

  void _layout(BoxConstraints constraints) {
    if (widget.builder == null)
      return;
    owner.lockState(() {
      Widget built;
      try {
        built = widget.builder(this, constraints.biggest);
        debugWidgetBuilderValue(widget, built);
      } catch (e, stack) {
        _debugReportException('building $widget', e, stack);
        built = new ErrorWidget(e);
      }

      try {
        _child = updateChild(_child, built, null);
        assert(_child != null);
      } catch (e, stack) {
        _debugReportException('building $widget', e, stack);
        built = new ErrorWidget(e);
        _child = updateChild(null, built, slot);
      }
    }, building: true);
  }

  @override
  void insertChildRenderObject(RenderObject child, dynamic slot) {
    final RenderObjectWithChildMixin<RenderObject> renderObject = this.renderObject;
    assert(slot == null);
    renderObject.child = child;
    assert(renderObject == this.renderObject);
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    final _RenderLayoutBuilder renderObject = this.renderObject;
    assert(renderObject.child == child);
    renderObject.child = null;
    assert(renderObject == this.renderObject);
  }
}

void _debugReportException(String context, dynamic exception, StackTrace stack) {
  FlutterError.reportError(new FlutterErrorDetails(
    exception: exception,
    stack: stack,
    library: 'widgets library',
    context: context
  ));
}
