// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;
import 'package:sky/framework/layout2.dart';

const double kTwoPi = 2 * math.PI;

double deg(double radians) => radians * 180.0 / math.PI;

class SectorConstraints {
  const SectorConstraints({
    this.minDeltaRadius: 0.0,
    this.maxDeltaRadius: double.INFINITY,
    this.minDeltaTheta: 0.0,
    this.maxDeltaTheta: kTwoPi});

  const SectorConstraints.tight({ double deltaRadius: 0.0, double deltaTheta: 0.0 })
    : minDeltaRadius = deltaRadius,
      maxDeltaRadius = deltaRadius,
      minDeltaTheta = deltaTheta,
      maxDeltaTheta = deltaTheta;

  final double minDeltaRadius;
  final double maxDeltaRadius;
  final double minDeltaTheta;
  final double maxDeltaTheta;

  double constrainDeltaRadius(double deltaRadius) {
    return clamp(min: minDeltaRadius, max: maxDeltaRadius, value: deltaRadius);
  }

  double constrainDeltaTheta(double deltaTheta) {
    return clamp(min: minDeltaTheta, max: maxDeltaTheta, value: deltaTheta);
  }
}

class SectorDimensions {
  const SectorDimensions({ this.deltaRadius: 0.0, this.deltaTheta: 0.0 });

  factory SectorDimensions.withConstraints(
    SectorConstraints constraints,
    { double deltaRadius: 0.0, double deltaTheta: 0.0 }
  ) {
    return new SectorDimensions(
      deltaRadius: constraints.constrainDeltaRadius(deltaRadius),
      deltaTheta: constraints.constrainDeltaTheta(deltaTheta)
    );
  }

  final double deltaRadius;
  final double deltaTheta;
}

class SectorParentData extends ParentData {
  double radius = 0.0;
  double theta = 0.0;
}

abstract class RenderSector extends RenderNode {

  void setParentData(RenderNode child) {
    if (child.parentData is! SectorParentData)
      child.parentData = new SectorParentData();
  }

  SectorDimensions getIntrinsicDimensions(SectorConstraints constraints, double radius) {
    return new SectorDimensions.withConstraints(constraints);
  }

  void layout(SectorConstraints constraints, double radius, { RenderNode relayoutSubtreeRoot }) {
    deltaRadius = constraints.constrainDeltaRadius(0.0);
    deltaTheta = constraints.constrainDeltaTheta(0.0);
    layoutDone();
  }

  double deltaRadius;
  double deltaTheta;
}

class RenderDecoratedSector extends RenderSector {
  BoxDecoration _decoration;

  RenderDecoratedSector(BoxDecoration decoration) : _decoration = decoration;

  void setBoxDecoration(BoxDecoration decoration) {
    if (_decoration == decoration)
      return;
    _decoration = decoration;
    markNeedsPaint();
  }

  // origin must be set to the center of the circle
  void paint(RenderNodeDisplayList canvas) {
    assert(deltaRadius != null);
    assert(deltaTheta != null);
    assert(parentData is SectorParentData);

    if (_decoration == null)
      return;

    if (_decoration.backgroundColor != null) {
      sky.Paint paint = new sky.Paint()..color = _decoration.backgroundColor;
      sky.Path path = new sky.Path();
      double outerRadiusOver2 = (parentData.radius + deltaRadius) / 2.0;
      sky.Rect outerBounds = new sky.Rect()..setLTRB(-outerRadiusOver2, -outerRadiusOver2, outerRadiusOver2, outerRadiusOver2);
      path.arcTo(outerBounds, deg(parentData.theta), deg(deltaTheta), true);
      double innerRadiusOver2 = parentData.radius / 2.0;
      sky.Rect innerBounds = new sky.Rect()..setLTRB(-innerRadiusOver2, -innerRadiusOver2, innerRadiusOver2, innerRadiusOver2);
      path.arcTo(innerBounds, deg(parentData.theta + deltaTheta), deg(-deltaTheta), false);
      path.close();
      canvas.drawPath(path, paint);
    }
  }
}

class SectorChildListParentData extends SectorParentData with ContainerParentDataMixin<RenderSector> { }

class RenderSectorRing extends RenderDecoratedSector with ContainerRenderNodeMixin<RenderSector, SectorChildListParentData> {
  // lays out RenderSector children in a ring

  RenderSectorRing({
    BoxDecoration decoration,
    double deltaRadius: double.INFINITY,
    double padding: 0.0
  }) : super(decoration), _padding = padding, _desiredDeltaRadius = deltaRadius;

  double _desiredDeltaRadius;
  double get desiredDeltaRadius => _desiredDeltaRadius;
  void set desiredDeltaRadius(double value) {
    assert(value != null);
    if (_desiredDeltaRadius != value) {
      _desiredDeltaRadius = value;
      markNeedsLayout();
    }
  }

  double _padding;
  double get padding => _padding;
  void set padding(double value) {
    assert(value != null);
    if (_padding != value) {
      _padding = value;
      markNeedsLayout();
    }
  }

  void setParentData(RenderNode child) {
    if (child.parentData is! SectorChildListParentData)
      child.parentData = new SectorChildListParentData();
  }

  SectorDimensions getIntrinsicDimensions(SectorConstraints constraints, double radius) {
    double outerDeltaRadius = constraints.constrainDeltaRadius(desiredDeltaRadius);
    double innerDeltaRadius = outerDeltaRadius - padding * 2.0;
    double childRadius = radius + padding;
    double paddingTheta = math.atan(padding / (radius + outerDeltaRadius));
    double innerTheta = paddingTheta; // increments with each child
    double remainingTheta = constraints.maxDeltaTheta - (innerTheta + paddingTheta);
    RenderSector child = firstChild;
    while (child != null) {
      SectorConstraints innerConstraints = new SectorConstraints(
        maxDeltaRadius: innerDeltaRadius,
        maxDeltaTheta: remainingTheta
      );
      SectorDimensions childDimensions = child.getIntrinsicDimensions(innerConstraints, childRadius);
      innerTheta += childDimensions.deltaTheta;
      remainingTheta -= childDimensions.deltaTheta;
      assert(child.parentData is SectorChildListParentData);
      child = child.parentData.nextSibling;
      if (child != null) {
        innerTheta += paddingTheta;
        remainingTheta -= paddingTheta;
      }
    }
    return new SectorDimensions.withConstraints(constraints,
                                                deltaRadius: outerDeltaRadius,
                                                deltaTheta: innerTheta);
  }

  SectorConstraints _constraints;
  void layout(SectorConstraints constraints, double radius, { RenderNode relayoutSubtreeRoot }) {
    if (relayoutSubtreeRoot != null)
      saveRelayoutSubtreeRoot(relayoutSubtreeRoot);
    relayoutSubtreeRoot = relayoutSubtreeRoot == null ? this : relayoutSubtreeRoot;
    deltaRadius = constraints.constrainDeltaRadius(desiredDeltaRadius);
    assert(deltaRadius < double.INFINITY);
    _constraints = constraints;
    internalLayout(radius, relayoutSubtreeRoot);
  }

  void relayout() {
    assert(parentData is SectorParentData);
    internalLayout(parentData.radius, this);
  }

  void internalLayout(double radius, RenderNode relayoutSubtreeRoot) {
    double innerDeltaRadius = deltaRadius - padding * 2.0;
    double childRadius = radius + padding;
    double paddingTheta = math.atan(padding / (radius + deltaRadius));
    double innerTheta = paddingTheta; // increments with each child
    double remainingTheta = _constraints.maxDeltaTheta - (innerTheta + paddingTheta);
    RenderSector child = firstChild;
    while (child != null) {
      SectorConstraints innerConstraints = new SectorConstraints(
        maxDeltaRadius: innerDeltaRadius,
        maxDeltaTheta: remainingTheta
      );
      child.layout(innerConstraints, childRadius, relayoutSubtreeRoot: relayoutSubtreeRoot);
      assert(child.parentData is SectorParentData);
      child.parentData.theta = innerTheta;
      child.parentData.radius = childRadius;
      innerTheta += child.deltaTheta;
      remainingTheta -= child.deltaTheta;
      assert(child.parentData is SectorChildListParentData);
      child = child.parentData.nextSibling;
      if (child != null) {
        innerTheta += paddingTheta;
        remainingTheta -= paddingTheta;
      }
    }
    deltaTheta = innerTheta;
  }

  // TODO(ianh): hit testing et al is pending on adam's patch

  // paint origin is 0,0 of our circle
  // each sector then knows how to paint itself at its location
  void paint(RenderNodeDisplayList canvas) {
    super.paint(canvas);
    RenderSector child = firstChild;
    while (child != null) {
      assert(child.parentData is SectorChildListParentData);
      canvas.paintChild(child, 0.0, 0.0);
      child = child.parentData.nextSibling;
    }
  }

}

class RenderBoxToRenderSectorAdapter extends RenderBox {

  RenderBoxToRenderSectorAdapter({ double innerRadius: 0.0, RenderSector child }) :
    _innerRadius = innerRadius {
    _child = child;
    adoptChild(_child);
  }

  double _innerRadius;
  double get innerRadius => _innerRadius;
  void set innerRadius(double value) {
    _innerRadius = value;
    markNeedsLayout();
  }

  RenderSector _child;
  RenderSector get child => _child;
  void set child(RenderSector value) {
    if (_child != null)
      dropChild(_child);
    _child = value;
    adoptChild(_child);
    markNeedsLayout();
  }

  void setParentData(RenderNode child) {
    if (child.parentData is! SectorParentData)
      child.parentData = new SectorParentData();
  }

  BoxDimensions getIntrinsicDimensions(BoxConstraints constraints) {
    if (child == null)
      return new BoxDimensions.withConstraints(constraints, width: 0.0, height: 0.0);
    assert(child is RenderSector);
    assert(child.parentData is SectorParentData);
    assert(!constraints.isInfinite);
    double maxChildDeltaRadius = math.max(constraints.maxWidth, constraints.maxHeight) / 2.0 - innerRadius;
    SectorDimensions childDimensions = child.getIntrinsicDimensions(new SectorConstraints(maxDeltaRadius: maxChildDeltaRadius), innerRadius);
    double dimension = (innerRadius + childDimensions.deltaRadius) * 2.0;
    return new BoxDimensions.withConstraints(constraints, width: dimension, height: dimension);
  }

  void layout(BoxConstraints constraints, { RenderNode relayoutSubtreeRoot }) {
    if (relayoutSubtreeRoot != null)
      saveRelayoutSubtreeRoot(relayoutSubtreeRoot);
    relayoutSubtreeRoot = relayoutSubtreeRoot == null ? this : relayoutSubtreeRoot;
    BoxDimensions ourDimensions;
    if (child == null) {
      ourDimensions = new BoxDimensions.withConstraints(constraints, width: 0.0, height: 0.0);
    } else {
      assert(child is RenderSector);
      assert(child.parentData is SectorParentData);
      assert(!constraints.isInfinite);
      double maxChildDeltaRadius = math.min(constraints.maxWidth, constraints.maxHeight) / 2.0 - innerRadius;
      child.layout(new SectorConstraints(maxDeltaRadius: maxChildDeltaRadius), innerRadius, relayoutSubtreeRoot: relayoutSubtreeRoot);
      double dimension = (innerRadius + child.deltaRadius) * 2.0;
      ourDimensions = new BoxDimensions.withConstraints(constraints, width: dimension, height: dimension);
    }
    width = ourDimensions.width;
    height = ourDimensions.height;
    print("adapter is: ${width}x${height}");
    layoutDone();
  }

  double width;
  double height;

  // TODO(ianh): hit testing et al is pending on adam's patch

  // paint origin is 0,0 of our circle
  void paint(RenderNodeDisplayList canvas) {
    super.paint(canvas);
    if (child != null) {
      print("painting child at ${width/2.0},${height/2.0}");
      sky.Paint paint;
      paint = new sky.Paint()..color = 0xFF474700;
      canvas.drawRect(new sky.Rect()..setLTRB(0.0, 0.0, width, height), paint);
      paint = new sky.Paint()..color = 0xFFF7F700;
      canvas.drawRect(new sky.Rect()..setLTRB(10.0, 10.0, width-10.0, height-10.0), paint);
      paint = new sky.Paint()..color = 0xFFFFFFFF;
      canvas.drawRect(new sky.Rect()..setLTRB(width/2.0-5.0, height/2.0-5.0, width/2.0+5.0, height/2.0+5.0), paint);
      canvas.paintChild(child, width/2.0, height/2.0);
    }
  }
  
}

class RenderSolidColor extends RenderDecoratedSector {
  final int backgroundColor;

  RenderSolidColor(int backgroundColor)
      : super(new BoxDecoration(backgroundColor: backgroundColor)),
        backgroundColor = backgroundColor;

  SectorDimensions getIntrinsicDimensions(SectorConstraints constraints, double radius) {
    return new SectorDimensions.withConstraints(constraints, deltaTheta: 1.0); // 1.0 radians
  }

  void layout(SectorConstraints constraints, double radius, { RenderNode relayoutSubtreeRoot }) {
    deltaRadius = constraints.constrainDeltaRadius(constraints.maxDeltaRadius);
    deltaTheta = constraints.constrainDeltaTheta(1.0); // 1.0 radians
    layoutDone();
  }
}

RenderView renderView;

void beginFrame(double timeStamp) {
  RenderNode.flushLayout();

  renderView.paintFrame();
}

bool handleEvent(sky.Event event) {
  if (event is! sky.PointerEvent)
    return false;
  return renderView.handlePointer(event, x: event.x, y: event.y);
}

void main() {
  print("test...");
  sky.view.setEventCallback(handleEvent);
  sky.view.setBeginFrameCallback(beginFrame);

  var rootCircle = new RenderSectorRing(padding: 10.0);
  rootCircle.add(new RenderSolidColor(0xFF00FF00));
  rootCircle.add(new RenderSolidColor(0xFF0000FF));

  var root = new RenderBoxToRenderSectorAdapter(innerRadius: 50.0, child: rootCircle);
  renderView = new RenderView(root: root);
  renderView.layout(newWidth: sky.view.width, newHeight: sky.view.height);

  sky.view.scheduleFrame();
  print("window is ${sky.view.width}x${sky.view.height}");
}
