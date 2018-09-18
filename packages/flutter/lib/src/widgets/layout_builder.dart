// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'debug.dart';
import 'framework.dart';

/// The signature of the [LayoutBuilder] builder function.
typedef LayoutWidgetBuilder = Widget Function(BuildContext context, BoxConstraints constraints);

/// Builds a widget tree that can depend on the parent widget's size.
///
/// Similar to the [Builder] widget except that the framework calls the [builder]
/// function at layout time and provides the parent widget's constraints. This
/// is useful when the parent constrains the child's size and doesn't depend on
/// the child's intrinsic size. The [LayoutBuilder]'s final size will match its
/// child's size.
///
/// If the child should be smaller than the parent, consider wrapping the child
/// in an [Align] widget. If the child might want to be bigger, consider
/// wrapping it in a [SingleChildScrollView].
///
/// See also:
///
/// * [Builder], which calls a `builder` function at build time.
/// * [StatefulBuilder], which passes its `builder` function a `setState` callback.
/// * [CustomSingleChildLayout], which positions its child during layout.
class LayoutBuilder extends RenderObjectWidget {
  /// Creates a widget that defers its building until layout.
  ///
  /// The [builder] argument must not be null.
  const LayoutBuilder({
    Key key,
    @required this.builder
  }) : assert(builder != null),
       super(key: key);

  /// Called at layout time to construct the widget tree. The builder must not
  /// return null.
  final LayoutWidgetBuilder builder;

  @override
  _LayoutBuilderElement createElement() => _LayoutBuilderElement(this);

  @override
  _RenderLayoutBuilder createRenderObject(BuildContext context) => _RenderLayoutBuilder();

  // updateRenderObject is redundant with the logic in the LayoutBuilderElement below.
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
  void forgetChild(Element child) {
    assert(child == _child);
    _child = null;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot); // Creates the renderObject.
    renderObject.callback = _layout;
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
  void performRebuild() {
    // This gets called if markNeedsBuild() is called on us.
    // That might happen if, e.g., our builder uses Inherited widgets.
    renderObject.markNeedsLayout();
    super.performRebuild(); // Calls widget.updateRenderObject (a no-op in this case).
  }

  @override
  void unmount() {
    renderObject.callback = null;
    super.unmount();
  }

  void _layout(BoxConstraints constraints) {
    owner.buildScope(this, () {
      Widget built;
      if (widget.builder != null) {
        try {
          built = widget.builder(this, constraints);
          debugWidgetBuilderValue(widget, built);
        } catch (e, stack) {
          built = ErrorWidget.builder(_debugReportException('building $widget', e, stack));
        }
      }
      try {
        _child = updateChild(_child, built, null);
        assert(_child != null);
      } catch (e, stack) {
        built = ErrorWidget.builder(_debugReportException('building $widget', e, stack));
        _child = updateChild(null, built, slot);
      }
    });
  }

  @override
  void insertChildRenderObject(RenderObject child, dynamic slot) {
    final RenderObjectWithChildMixin<RenderObject> renderObject = this.renderObject;
    assert(slot == null);
    assert(renderObject.debugValidateChild(child));
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

class _RenderLayoutBuilder extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  _RenderLayoutBuilder({
    LayoutCallback<BoxConstraints> callback,
  }) : _callback = callback;

  LayoutCallback<BoxConstraints> get callback => _callback;
  LayoutCallback<BoxConstraints> _callback;
  set callback(LayoutCallback<BoxConstraints> value) {
    if (value == _callback)
      return;
    _callback = value;
    markNeedsLayout();
  }

  bool _debugThrowIfNotCheckingIntrinsics() {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw FlutterError(
          'LayoutBuilder does not support returning intrinsic dimensions.\n'
          'Calculating the intrinsic dimensions would require running the layout '
          'callback speculatively, which might mutate the live render object tree.'
        );
      }
      return true;
    }());
    return true;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  void performLayout() {
    assert(callback != null);
    invokeLayoutCallback(callback);
    if (child != null) {
      child.layout(constraints, parentUsesSize: true);
      size = constraints.constrain(child.size);
    } else {
      size = constraints.biggest;
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, { Offset position }) {
    return child?.hitTest(result, position: position) ?? false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.paintChild(child, offset);
  }
}

FlutterErrorDetails _debugReportException(
  String context,
  dynamic exception,
  StackTrace stack,
) {
  final FlutterErrorDetails details = FlutterErrorDetails(
    exception: exception,
    stack: stack,
    library: 'widgets library',
    context: context
  );
  FlutterError.reportError(details);
  return details;
}
