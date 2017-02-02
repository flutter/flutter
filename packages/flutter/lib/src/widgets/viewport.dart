// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

export 'package:flutter/rendering.dart' show
  AxisDirection,
  GrowthDirection;

class Viewport2 extends MultiChildRenderObjectWidget {
  Viewport2({
    Key key,
    this.axisDirection: AxisDirection.down,
    this.anchor: 0.0,
    @required this.offset,
    this.center,
    List<Widget> slivers: const <Widget>[],
  }) : super(key: key, children: slivers) {
    assert(offset != null);
    assert(center == null || children.where((Widget child) => child.key == center).length == 1);
  }

  final AxisDirection axisDirection;
  final double anchor;
  final ViewportOffset offset;
  final Key center;

  @override
  RenderViewport2 createRenderObject(BuildContext context) {
    return new RenderViewport2(
      axisDirection: axisDirection,
      anchor: anchor,
      offset: offset,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderViewport2 renderObject) {
    renderObject.axisDirection = axisDirection;
    renderObject.anchor = anchor;
    renderObject.offset = offset;
  }

  @override
  Viewport2Element createElement() => new Viewport2Element(this);

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$axisDirection');
    description.add('anchor: $anchor');
    description.add('offset: $offset');
    if (center != null) {
      description.add('center: $center');
    } else if (children.isNotEmpty && children.first.key != null) {
      description.add('center: ${children.first.key} (implicit)');
    }
  }
}

class Viewport2Element extends MultiChildRenderObjectElement {
  /// Creates an element that uses the given widget as its configuration.
  Viewport2Element(Viewport2 widget) : super(widget);

  @override
  Viewport2 get widget => super.widget;

  @override
  RenderViewport2 get renderObject => super.renderObject;

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    updateCenter();
  }

  @override
  void update(MultiChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    updateCenter();
  }

  @protected
  void updateCenter() {
    // TODO(ianh): cache the keys to make this faster
    if (widget.center != null) {
      renderObject.center = children.singleWhere(
        (Element element) => element.widget.key == widget.center
      ).renderObject;
    } else if (children.isNotEmpty) {
      renderObject.center = children.first.renderObject;
    } else {
      renderObject.center = null;
    }
  }
}

class ShrinkWrappingViewport extends MultiChildRenderObjectWidget {
  ShrinkWrappingViewport({
    Key key,
    this.axisDirection: AxisDirection.down,
    @required this.offset,
    List<Widget> slivers: const <Widget>[],
  }) : super(key: key, children: slivers) {
    assert(offset != null);
  }

  final AxisDirection axisDirection;
  final ViewportOffset offset;

  @override
  RenderShrinkWrappingViewport createRenderObject(BuildContext context) {
    return new RenderShrinkWrappingViewport(
      axisDirection: axisDirection,
      offset: offset,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderShrinkWrappingViewport renderObject) {
    renderObject
      ..axisDirection = axisDirection
      ..offset = offset;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$axisDirection');
    description.add('offset: $offset');
  }
}
