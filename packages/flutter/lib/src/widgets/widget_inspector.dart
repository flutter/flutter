// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:ui' as ui show window, Picture, SceneBuilder, PictureRecorder;
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'gesture_detector.dart';

/// A widget that enables inspecting the child widget's structure.
class WidgetInspector extends StatefulWidget {
  /// Creates a widget that enables inspection for the child.
  ///
  /// The [child] argument must not be null.
  const WidgetInspector({
    Key key,
    @required this.child,
  }) : assert(child != null),
       super(key: key);

  /// The widget that is being inspected.
  final Widget child;

  @override
  _WidgetInspectorState createState() => new _WidgetInspectorState();
}

class _WidgetInspectorState extends State<WidgetInspector>
    with WidgetsBindingObserver {

  Offset _lastPointerLocation;

  final _InspectorSelection _selection = new _InspectorSelection();

  /// Whether the inspector is in select mode.
  ///
  /// In select mode, pointer interactions trigger widget selection instead of
  /// normal interactions. Otherwise the previously selected widget is
  /// highlighted but the application can be interacted with normally.
  bool _isSelectMode = false;

  final GlobalKey _ignorePointerKey = new GlobalKey();

  /// Distance from the edge of of the bounding box for an element to consider
  /// as selecting the edge of the bounding box.
  static const double _kEdgeHitMargin = 2.0;

  bool _hitTestHelper(
    LinkedHashMap<RenderObject, bool> hits,
    LinkedHashSet<RenderObject> edgeHits,
    Offset position,
    RenderObject object,
    Matrix4 transform,
  ) {
    if (hits.containsKey(object))
      return hits[object];

    final Matrix4 inverse = new Matrix4.inverted(transform);
    final Offset localPosition = MatrixUtils.transformPoint(inverse, position);

    // Leverage the hitTest method on RenderBox to prioritize hits that
    // correspond to actual hit test matches. All other hits will still be shown
    // but these are the hit test matches that make the most intuitive sense to
    // users.
    if (object is RenderBox) {
      final HitTestResult hitTestResult = new HitTestResult();
      object.hitTest(hitTestResult, position: localPosition);
      if (hitTestResult.path.isNotEmpty) {
        final RenderObject target = hitTestResult.path.first.target;
        if (target != object) {
          // TODO(jacobr): be more efficient about computing childTransform.
          final Matrix4 childTransform = target.getTransformTo(null);
          _hitTestHelper(hits, edgeHits, position, target, childTransform);
        }
      }
    }

    bool hit = false;
    final List<DiagnosticsNode> children = object.debugDescribeChildren();
    for (int i = children.length - 1; i >= 0; i--) {
      final DiagnosticsNode diagnostics = children[i];
      if (diagnostics.style == DiagnosticsTreeStyle.offstage ||
          diagnostics.value is! RenderObject)
        continue;
      final RenderObject child = diagnostics.value;
      final Rect paintClip = object.describeApproximatePaintClip(child);
      if (paintClip != null && !paintClip.contains(localPosition))
        continue;

      final Matrix4 childTransform = transform.clone();
      object.applyPaintTransform(child, childTransform);
      if (_hitTestHelper(hits, edgeHits, position, child, childTransform))
        hit = true;
    }

    final Rect bounds = object.semanticBounds;
    if (bounds.contains(localPosition)) {
      hit = true;
      // Hits that occur on the edge of the bounding box of an object are
      // given priority to provide a way to select objects that would
      // otherwise be hard to select.
      if (!bounds.deflate(_kEdgeHitMargin).contains(localPosition))
        edgeHits.add(object);
    }
    hits[object] = hit;
    return hit;
  }

  /// Returns the list of render objects located at the given position ordered
  /// by priority.
  ///
  /// All render objects that are not offstage that match the location are
  /// included in the list of matches. Priority is given to matches that occur
  /// on the edge of a render object's bounding box and to matches found by
  /// [RenderBox.hitTest].
  List<RenderObject> hitTest(Offset position, RenderObject root) {
    final LinkedHashMap<RenderObject, bool> result = new LinkedHashMap<RenderObject, bool>();
    final LinkedHashSet<RenderObject> edgeHits = new LinkedHashSet<RenderObject>();

    _hitTestHelper(result, edgeHits, position, root, root.getTransformTo(null));
    final Set<RenderObject> hits = new LinkedHashSet<RenderObject>();
    hits.addAll(edgeHits);
    result.forEach((RenderObject o, bool value) {
      if (value)
        hits.add(o);
    });
    return hits.toList();
  }

  void _inspectAt(Offset position) {
    if (!_isSelectMode)
      return;

    final RenderIgnorePointer ignorePointer = _ignorePointerKey.currentContext.findRenderObject();
    final RenderObject userRender = ignorePointer.child;
    final List<RenderObject> selected = hitTest(position, userRender);

    setState(() {
      _selection.candidates = selected;
    });
  }

  void _handlePanDown(DragDownDetails event) {
    _lastPointerLocation = event.globalPosition;
    _inspectAt(event.globalPosition);
  }

  void _handlePanUpdate(DragUpdateDetails event) {
    _lastPointerLocation = event.globalPosition;
    _inspectAt(event.globalPosition);
  }

  void _handlePanEnd(DragEndDetails details) {
    // If the pan ends on the edge of the window assume that it indicates the
    // pointer is being dragged off the edge of the display not a regular touch
    // on the edge of the display. If the pointer is being dragged off the edge
    // of the display we do not want to select anything. A user can still select
    // a widget that is only at the exact screen margin by taping.
    final Rect bounds = (Offset.zero & (ui.window.physicalSize / ui.window.devicePixelRatio)).deflate(_kOffScreenMargin);
    if (!bounds.contains(_lastPointerLocation)) {
      setState(() {
        _selection.clear();
      });
    }
  }

  void _handleTap() {
    if (!_isSelectMode)
      return;
    if (_lastPointerLocation != null) {
      _inspectAt(_lastPointerLocation);

      if (_selection != null) {
        // Notify debuggers to open an inspector on the object.
        developer.inspect(_selection.current);
        print(_selection.current.toStringDeep());
      }
    }
    setState(() {
      _isSelectMode = false;
    });
  }

  void _handleEnableSelect() {
    setState(() {
      _isSelectMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    children.add(new GestureDetector(
      onTap: _handleTap,
      onPanDown: _handlePanDown,
      onPanEnd: _handlePanEnd,
      onPanUpdate: _handlePanUpdate,
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      child: new IgnorePointer(
        ignoring: _isSelectMode,
        key: _ignorePointerKey,
        ignoringSemantics: false,
        child: widget.child,
      ),
    ));
    if (!_isSelectMode) {
      children.add(new Positioned(
        left: _kInspectButtonMargin,
        bottom: _kInspectButtonMargin,
        child: new FloatingActionButton(
          child: const Icon(Icons.search),
          onPressed: _handleEnableSelect,
          mini: true,
        ),
      ));
    }
    children.add(new _InspectorOverlay(selection: _selection));
    return new Stack(children: children);
  }
}

/// Mutable selection state of the inspector.
class _InspectorSelection {
  List<RenderObject> _candidates = <RenderObject>[];

  /// Render objects that are candidates to be selected.
  ///
  /// Tools may wish to iterate through the list of candidates
  List<RenderObject> get candidates => _candidates;

  /// Index within the list of candidates that is currently selected.
  int index = 0;

  set candidates(List<RenderObject> value) {
    _candidates = value;
    index = 0;
  }

  void clear() {
    _candidates = <RenderObject>[];
    index = 0;
  }

  RenderObject get current {
    return candidates != null && index < candidates.length ? candidates[index] : null;
  }

  bool get active => current != null && current.attached;
}

class _InspectorOverlay extends LeafRenderObjectWidget {
  const _InspectorOverlay({
    Key key,
    @required this.selection,
  }) : super(key: key);

  final _InspectorSelection selection;

  @override
  _RenderInspectorOverlay createRenderObject(BuildContext context) {
    return new _RenderInspectorOverlay(selection: selection);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderInspectorOverlay renderObject) {
    renderObject.selection = selection;
  }
}

class _RenderInspectorOverlay extends RenderBox {
  /// The arguments must not be null.
  _RenderInspectorOverlay({ @required this.selection }) : assert(selection != null);

  _InspectorSelection selection;

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void performResize() {
    size = constraints.constrain(new Size(double.INFINITY, double.INFINITY));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(needsCompositing);
    context.addLayer(new InspectorOverlayLayer(
      overlayRect: new Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
      selection: selection,
    ));
  }
}

class _TransformedRect {
  _TransformedRect(RenderObject object) :
    rect = object.semanticBounds,
    transform = object.getTransformTo(null);

  final Rect rect;
  final Matrix4 transform;

  @override
  bool operator ==(dynamic other) {
    if (other is! _TransformedRect)
      return false;
    return rect == other.rect && transform == other.transform;
  }

  @override
  int get hashCode => hashValues(rect, transform);
}

/// State describing how the inspector overlay should be rendered.
///
/// The equality operator can be used to determine whether the overlay needs to
/// be rendered again.
class _InspectorOverlayRenderState {
  _InspectorOverlayRenderState({
    @required this.overlayRect,
    @required this.selected,
    @required this.candidates,
    @required this.tooltip,
  });

  final Rect overlayRect;
  final _TransformedRect selected;
  final List<_TransformedRect> candidates;
  final String tooltip;

  @override
  bool operator ==(dynamic other) {
    if (other is! _InspectorOverlayRenderState)
      return false;
    return overlayRect == other.overlayRect
        && selected == other.selected
        && listEquals<_TransformedRect>(candidates, other.candidates)
        && tooltip == other.tooltip;
  }

  @override
  int get hashCode => hashValues(overlayRect, selected, hashList(candidates), tooltip);
}

/// A layer that indicates to the compositor that it should display
/// certain performance statistics within it.
///
/// Performance overlay layers are always leaves in the layer tree.
class InspectorOverlayLayer extends Layer {
  /// Creates a layer that displays a performance overlay.
  InspectorOverlayLayer({
    @required this.overlayRect,
    @required this.selection,
  }) : assert(overlayRect != null), assert(selection != null);

  _InspectorSelection selection;

  /// The rectangle in this layer's coordinate system that the overlay should
  /// occupy.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  final Rect overlayRect;

  _InspectorOverlayRenderState _lastState;

  /// Picture generated from _lastState.
  ui.Picture _picture;

  @override
  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    if (!selection.active)
      return;

    final RenderObject selected = selection.current;
    final List<_TransformedRect> candidates = <_TransformedRect>[];
    for (RenderObject candidate in selection.candidates) {
      if (candidate == selected || !candidate.attached)
        continue;
      candidates.add(new _TransformedRect(candidate));
    }

    final _InspectorOverlayRenderState state = new _InspectorOverlayRenderState(
      overlayRect: overlayRect,
      selected: new _TransformedRect(selected),
      tooltip: selected.toString(),
      candidates: candidates,
    );

    if (state != _lastState) {
      _lastState = state;
      _picture = _buildPicture(state);
    }
    builder.addPicture(layerOffset, _picture);
  }

  static ui.Picture _buildPicture(_InspectorOverlayRenderState state) {
    final ui.PictureRecorder recorder = new ui.PictureRecorder();
    final Canvas canvas = new Canvas(recorder, state.overlayRect);
    final Size size = state.overlayRect.size;

    final Paint fillPaint = new Paint()
      ..style = PaintingStyle.fill
      ..color = _kHighlightedRenderObjectFillColor;

    final Paint borderPaint = new Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _kHighlightedRenderObjectBorderColor;

    // Highlight the selected renderObject.
    final Rect selectedPaintRect = state.selected.rect.deflate(0.5);
    canvas
      ..save()
      ..transform(state.selected.transform.storage)
      ..drawRect(selectedPaintRect, fillPaint)
      ..drawRect(selectedPaintRect, borderPaint)
      ..restore();

    // Show all other candidate possibly selected elements. This helps selecting
    // render objects by selecting the edge of the bounding box shows all
    // elements the user could toggle the selection between.
    for (_TransformedRect transformedRect in state.candidates) {
      canvas
        ..save()
        ..transform(transformedRect.transform.storage)
        ..drawRect(transformedRect.rect.deflate(0.5), borderPaint)
        ..restore();
    }

    final Rect targetRect = MatrixUtils.transformRect(
        state.selected.transform, state.selected.rect);
    final Offset target = new Offset(targetRect.left, targetRect.center.dy);
    final double offsetFromWidget = 9.0;
    final double verticalOffset = (targetRect.height) / 2 + offsetFromWidget;

    _paintDescription(
        canvas, state.tooltip, target, verticalOffset, size, targetRect);

    // TODO(jacobr): provide an option to perform a debug paint of just the
    // selected widget.
    return recorder.endRecording();
  }
}

const double _kScreenEdgeMargin = 10.0;
const double _kTooltipPadding = 5.0;
const double _kInspectButtonMargin = 10.0;

/// Interpret pointer up events within with this margin as indicating the
/// pointer is moving off the device.
const double _kOffScreenMargin = 1.0;

const TextStyle _messageStyle = const TextStyle(
  color: const Color(0xFFFFFFFF),
  fontSize: 10.0,
  height: 1.2,
);

final int _kMaxTooltipLines = 5;
final Color _kTooltipBackgroundColor = const Color.fromARGB(230, 60, 60, 60);
final Color _kHighlightedRenderObjectFillColor = const Color.fromARGB(128, 128, 128, 255);
final Color _kHighlightedRenderObjectBorderColor = const Color.fromARGB(128, 64, 64, 128);

void _paintDescription(Canvas canvas, String message, Offset target,
    double verticalOffset, Size size, Rect targetRect) {
  canvas.save();
  final TextPainter textPainter = new TextPainter()
    ..maxLines = _kMaxTooltipLines
    ..ellipsis = '...'
    ..text = new TextSpan(style: _messageStyle, text: message)
    ..layout(maxWidth: size.width - 2 * (_kScreenEdgeMargin + _kTooltipPadding));

  final Size tooltipSize = textPainter.size + const Offset(_kTooltipPadding * 2, _kTooltipPadding * 2);
  final TooltipPositionDelegate tooltipPositionDelegate = new TooltipPositionDelegate(
    target: target,
    verticalOffset: verticalOffset,
    preferBelow: false,
  );
  final Offset tipOffset = tooltipPositionDelegate.getPositionForChild(size, tooltipSize);
  final Paint tooltipBackground = new Paint()
    ..style = PaintingStyle.fill
    ..color = _kTooltipBackgroundColor;
  canvas.drawRect(
    new Rect.fromPoints(
      tipOffset,
      tipOffset.translate(tooltipSize.width, tooltipSize.height),
    ),
    tooltipBackground,
  );

  double wedgeY = tipOffset.dy;
  final bool tooltipBelow = tipOffset.dy > target.dy;
  if (!tooltipBelow)
    wedgeY += tooltipSize.height;

  final double wedgeSize = _kTooltipPadding * 2;
  double wedgeX = math.max(tipOffset.dx, target.dx) + wedgeSize * 2;
  wedgeX = math.min(wedgeX, tipOffset.dx + tooltipSize.width - wedgeSize * 2);
  final List<Offset> wedge = <Offset>[
    new Offset(wedgeX - wedgeSize, wedgeY),
    new Offset(wedgeX + wedgeSize, wedgeY),
    new Offset(wedgeX, wedgeY + (tooltipBelow ? -wedgeSize : wedgeSize)),
  ];
  canvas.drawPath(new Path()..addPolygon(wedge, true,), tooltipBackground);
  textPainter.paint(
    canvas,
    tipOffset + const Offset(_kTooltipPadding, _kTooltipPadding),
  );
  canvas.restore();
}
