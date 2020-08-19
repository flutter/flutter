// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:vector_math/vector_math_64.dart' show Quad, Vector3, Matrix4;

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'ticker_provider.dart';

/// A widget that enables pan and zoom interactions with its child.
///
/// The user can transform the child by dragging to pan or pinching to zoom.
///
/// By default, InteractiveViewer may draw outside of its original area of the
/// screen, such as when a child is zoomed in and increases in size. However, it
/// will not receive gestures outside of its original area. To prevent
/// InteractiveViewer from drawing outside of its original size, wrap it in a
/// [ClipRect]. Or, to prevent dead areas where InteractiveViewer does not
/// receive gestures, be sure that the InteractiveViewer widget is the size of
/// the area that should be interactive. See
/// [flutter-go](https://github.com/justinmc/flutter-go) for an example of
/// robust positioning of an InteractiveViewer child that works for all screen
/// sizes and child sizes.
///
/// The [child] must not be null.
///
/// See also:
///   * The [Flutter Gallery's transformations demo](https://github.com/flutter/gallery/blob/master/lib/demos/reference/transformations_demo.dart),
///     which includes the use of InteractiveViewer.
///
/// {@tool dartpad --template=stateless_widget_scaffold}
/// This example shows a simple Container that can be panned and zoomed.
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Center(
///     child: InteractiveViewer(
///       boundaryMargin: EdgeInsets.all(20.0),
///       minScale: 0.1,
///       maxScale: 1.6,
///       child: Container(
///         decoration: BoxDecoration(
///           gradient: LinearGradient(
///             begin: Alignment.topCenter,
///             end: Alignment.bottomCenter,
///             colors: <Color>[Colors.orange, Colors.red],
///             stops: <double>[0.0, 1.0],
///           ),
///         ),
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
@immutable
class InteractiveViewer extends StatefulWidget {
  /// Create an InteractiveViewer.
  ///
  /// The [child] parameter must not be null.
  InteractiveViewer({
    Key key,
    this.alignPanAxis = false,
    this.boundaryMargin = EdgeInsets.zero,
    this.constrained = true,
    // These default scale values were eyeballed as reasonable limits for common
    // use cases.
    this.maxScale = 2.5,
    this.minScale = 0.8,
    this.onInteractionEnd,
    this.onInteractionStart,
    this.onInteractionUpdate,
    this.panEnabled = true,
    this.scaleEnabled = true,
    this.transformationController,
    @required this.child,
  }) : assert(alignPanAxis != null),
       assert(child != null),
       assert(constrained != null),
       assert(minScale != null),
       assert(minScale > 0),
       assert(minScale.isFinite),
       assert(maxScale != null),
       assert(maxScale > 0),
       assert(!maxScale.isNaN),
       assert(maxScale >= minScale),
       assert(panEnabled != null),
       assert(scaleEnabled != null),
       // boundaryMargin must be either fully infinite or fully finite, but not
       // a mix of both.
       assert((boundaryMargin.horizontal.isInfinite
           && boundaryMargin.vertical.isInfinite) || (boundaryMargin.top.isFinite
           && boundaryMargin.right.isFinite && boundaryMargin.bottom.isFinite
           && boundaryMargin.left.isFinite)),
       super(key: key);

  /// If true, panning is only allowed in the direction of the horizontal axis
  /// or the vertical axis.
  ///
  /// In other words, when this is true, diagonal panning is not allowed. A
  /// single gesture begun along one axis cannot also cause panning along the
  /// other axis without stopping and beginning a new gesture. This is a common
  /// pattern in tables where data is displayed in columns and rows.
  final bool alignPanAxis;

  /// A margin for the visible boundaries of the child.
  ///
  /// Any transformation that results in the viewport being able to view outside
  /// of the boundaries will be stopped at the boundary. The boundaries do not
  /// rotate with the rest of the scene, so they are always aligned with the
  /// viewport.
  ///
  /// To produce no boundaries at all, pass infinite [EdgeInsets], such as
  /// `EdgeInsets.all(double.infinity)`.
  ///
  /// No edge can be NaN.
  ///
  /// Defaults to [EdgeInsets.zero], which results in boundaries that are the
  /// exact same size and position as the [child].
  final EdgeInsets boundaryMargin;

  /// The Widget to perform the transformations on.
  ///
  /// Cannot be null.
  final Widget child;

  /// Whether the normal size constraints at this point in the widget tree are
  /// applied to the child.
  ///
  /// If set to false, then the child will be given infinite constraints. This
  /// is often useful when a child should be bigger than the InteractiveViewer.
  ///
  /// Defaults to true.
  ///
  /// {@tool dartpad --template=stateless_widget_scaffold}
  /// This example shows how to create a pannable table. Because the table is
  /// larger than the entire screen, setting `constrained` to false is necessary
  /// to allow it to be drawn to its full size. The parts of the table that
  /// exceed the screen size can then be panned into view.
  ///
  /// ```dart
  ///   Widget build(BuildContext context) {
  ///     const int _rowCount = 20;
  ///     const int _columnCount = 3;
  ///
  ///     return Scaffold(
  ///       appBar: AppBar(
  ///         title: const Text('Pannable Table'),
  ///       ),
  ///       body: InteractiveViewer(
  ///         constrained: false,
  ///         scaleEnabled: false,
  ///         child: Table(
  ///           columnWidths: <int, TableColumnWidth>{
  ///             for (int column = 0; column < _columnCount; column += 1)
  ///               column: const FixedColumnWidth(300.0),
  ///           },
  ///           children: <TableRow>[
  ///             for (int row = 0; row < _rowCount; row += 1)
  ///               TableRow(
  ///                 children: <Widget>[
  ///                   for (int column = 0; column < _columnCount; column += 1)
  ///                     Container(
  ///                       height: 100,
  ///                       color: row % 2 + column % 2 == 1 ? Colors.red : Colors.green,
  ///                     ),
  ///                 ],
  ///               ),
  ///           ],
  ///         ),
  ///       ),
  ///     );
  ///   }
  /// ```
  /// {@end-tool}
  final bool constrained;

  /// If false, the user will be prevented from panning.
  ///
  /// Defaults to true.
  ///
  /// See also:
  ///
  ///   * [scaleEnabled], which is similar but for scale.
  final bool panEnabled;

  /// If false, the user will be prevented from scaling.
  ///
  /// Defaults to true.
  ///
  /// See also:
  ///
  ///   * [panEnabled], which is similar but for panning.
  final bool scaleEnabled;

  /// The maximum allowed scale.
  ///
  /// The scale will be clamped between this and [minScale] inclusively.
  ///
  /// Defaults to 2.5.
  ///
  /// Cannot be null, and must be greater than zero and greater than minScale.
  final double maxScale;

  /// The minimum allowed scale.
  ///
  /// The scale will be clamped between this and [maxScale] inclusively.
  ///
  /// Defaults to 0.8.
  ///
  /// Cannot be null, and must be a finite number greater than zero and less
  /// than maxScale.
  final double minScale;

  /// Called when the user ends a pan or scale gesture on the widget.
  ///
  /// {@template flutter.widgets.interactiveViewer.onInteraction}
  /// Will be called even if the interaction is disabled with
  /// [panEnabled] or [scaleEnabled].
  ///
  /// A [GestureDetector] wrapping the InteractiveViewer will not respond to
  /// [GestureDetector.onScaleStart], [GestureDetector.onScaleUpdate], and
  /// [GestureDetector.onScaleEnd]. Use [onInteractionStart],
  /// [onInteractionUpdate], and [onInteractionEnd] to respond to those
  /// gestures.
  ///
  /// The coordinates returned in the details are viewport coordinates relative
  /// to the parent. See [TransformationController.toScene] for how to
  /// convert the coordinates to scene coordinates relative to the child.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [onInteractionStart], which handles the start of the same interaction.
  ///  * [onInteractionUpdate], which handles an update to the same interaction.
  final GestureScaleEndCallback onInteractionEnd;

  /// Called when the user begins a pan or scale gesture on the widget.
  ///
  /// {@macro flutter.widgets.interactiveViewer.onInteraction}
  ///
  /// See also:
  ///
  ///  * [onInteractionUpdate], which handles an update to the same interaction.
  ///  * [onInteractionEnd], which handles the end of the same interaction.
  final GestureScaleStartCallback onInteractionStart;

  /// Called when the user updates a pan or scale gesture on the widget.
  ///
  /// {@macro flutter.widgets.interactiveViewer.onInteraction}
  ///
  /// See also:
  ///
  ///  * [onInteractionStart], which handles the start of the same interaction.
  ///  * [onInteractionEnd], which handles the end of the same interaction.
  final GestureScaleUpdateCallback onInteractionUpdate;

  /// A [TransformationController] for the transformation performed on the
  /// child.
  ///
  /// Whenever the child is transformed, the [Matrix4] value is updated and all
  /// listeners are notified. If the value is set, InteractiveViewer will update
  /// to respect the new value.
  ///
  /// {@tool dartpad --template=stateful_widget_material_ticker}
  /// This example shows how transformationController can be used to animate the
  /// transformation back to its starting position.
  ///
  /// ```dart
  /// final TransformationController _transformationController = TransformationController();
  /// Animation<Matrix4> _animationReset;
  /// AnimationController _controllerReset;
  ///
  /// void _onAnimateReset() {
  ///   _transformationController.value = _animationReset.value;
  ///   if (!_controllerReset.isAnimating) {
  ///     _animationReset?.removeListener(_onAnimateReset);
  ///     _animationReset = null;
  ///     _controllerReset.reset();
  ///   }
  /// }
  ///
  /// void _animateResetInitialize() {
  ///   _controllerReset.reset();
  ///   _animationReset = Matrix4Tween(
  ///     begin: _transformationController.value,
  ///     end: Matrix4.identity(),
  ///   ).animate(_controllerReset);
  ///   _animationReset.addListener(_onAnimateReset);
  ///   _controllerReset.forward();
  /// }
  ///
  /// // Stop a running reset to home transform animation.
  /// void _animateResetStop() {
  ///   _controllerReset.stop();
  ///   _animationReset?.removeListener(_onAnimateReset);
  ///   _animationReset = null;
  ///   _controllerReset.reset();
  /// }
  ///
  /// void _onInteractionStart(ScaleStartDetails details) {
  ///   // If the user tries to cause a transformation while the reset animation is
  ///   // running, cancel the reset animation.
  ///   if (_controllerReset.status == AnimationStatus.forward) {
  ///     _animateResetStop();
  ///   }
  /// }
  ///
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   _controllerReset = AnimationController(
  ///     vsync: this,
  ///     duration: const Duration(milliseconds: 400),
  ///   );
  /// }
  ///
  /// @override
  /// void dispose() {
  ///   _controllerReset.dispose();
  ///   super.dispose();
  /// }
  ///
  /// @override
  /// Widget build(BuildContext context) {
  ///   return Scaffold(
  ///     backgroundColor: Theme.of(context).colorScheme.primary,
  ///     appBar: AppBar(
  ///       automaticallyImplyLeading: false,
  ///       title: const Text('Controller demo'),
  ///     ),
  ///     body: Center(
  ///       child: InteractiveViewer(
  ///         boundaryMargin: EdgeInsets.all(double.infinity),
  ///         transformationController: _transformationController,
  ///         minScale: 0.1,
  ///         maxScale: 1.0,
  ///         onInteractionStart: _onInteractionStart,
  ///         child: Container(
  ///           decoration: BoxDecoration(
  ///             gradient: LinearGradient(
  ///               begin: Alignment.topCenter,
  ///               end: Alignment.bottomCenter,
  ///               colors: <Color>[Colors.orange, Colors.red],
  ///               stops: <double>[0.0, 1.0],
  ///             ),
  ///           ),
  ///         ),
  ///       ),
  ///     ),
  ///     persistentFooterButtons: [
  ///       IconButton(
  ///         onPressed: _animateResetInitialize,
  ///         tooltip: 'Reset',
  ///         color: Theme.of(context).colorScheme.surface,
  ///         icon: const Icon(Icons.replay),
  ///       ),
  ///     ],
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [ValueNotifier], the parent class of TransformationController.
  ///  * [TextEditingController] for an example of another similar pattern.
  final TransformationController transformationController;

  /// Returns the closest point to the given point on the given line segment.
  @visibleForTesting
  static Vector3 getNearestPointOnLine(Vector3 point, Vector3 l1, Vector3 l2) {
    final double lengthSquared = math.pow(l2.x - l1.x, 2.0).toDouble()
        + math.pow(l2.y - l1.y, 2.0).toDouble();

    // In this case, l1 == l2.
    if (lengthSquared == 0) {
      return l1;
    }

    // Calculate how far down the line segment the closest point is and return
    // the point.
    final Vector3 l1P = point - l1;
    final Vector3 l1L2 = l2 - l1;
    final double fraction = (l1P.dot(l1L2) / lengthSquared).clamp(0.0, 1.0).toDouble();
    return l1 + l1L2 * fraction;
  }

  /// Given a quad, return its axis aligned bounding box.
  @visibleForTesting
  static Quad getAxisAlignedBoundingBox(Quad quad) {
    final double minX = math.min(
      quad.point0.x,
      math.min(
        quad.point1.x,
        math.min(
          quad.point2.x,
          quad.point3.x,
        ),
      ),
    );
    final double minY = math.min(
      quad.point0.y,
      math.min(
        quad.point1.y,
        math.min(
          quad.point2.y,
          quad.point3.y,
        ),
      ),
    );
    final double maxX = math.max(
      quad.point0.x,
      math.max(
        quad.point1.x,
        math.max(
          quad.point2.x,
          quad.point3.x,
        ),
      ),
    );
    final double maxY = math.max(
      quad.point0.y,
      math.max(
        quad.point1.y,
        math.max(
          quad.point2.y,
          quad.point3.y,
        ),
      ),
    );
    return Quad.points(
      Vector3(minX, minY, 0),
      Vector3(maxX, minY, 0),
      Vector3(maxX, maxY, 0),
      Vector3(minX, maxY, 0),
    );
  }

  /// Returns true iff the point is inside the rectangle given by the Quad,
  /// inclusively.
  /// Algorithm from https://math.stackexchange.com/a/190373.
  @visibleForTesting
  static bool pointIsInside(Vector3 point, Quad quad) {
    final Vector3 aM = point - quad.point0;
    final Vector3 aB = quad.point1 - quad.point0;
    final Vector3 aD = quad.point3 - quad.point0;

    final double aMAB = aM.dot(aB);
    final double aBAB = aB.dot(aB);
    final double aMAD = aM.dot(aD);
    final double aDAD = aD.dot(aD);

    return 0 <= aMAB && aMAB <= aBAB && 0 <= aMAD && aMAD <= aDAD;
  }

  /// Get the point inside (inclusively) the given Quad that is nearest to the
  /// given Vector3.
  @visibleForTesting
  static Vector3 getNearestPointInside(Vector3 point, Quad quad) {
    // If the point is inside the axis aligned bounding box, then it's ok where
    // it is.
    if (pointIsInside(point, quad)) {
      return point;
    }

    // Otherwise, return the nearest point on the quad.
    final List<Vector3> closestPoints = <Vector3>[
      InteractiveViewer.getNearestPointOnLine(point, quad.point0, quad.point1),
      InteractiveViewer.getNearestPointOnLine(point, quad.point1, quad.point2),
      InteractiveViewer.getNearestPointOnLine(point, quad.point2, quad.point3),
      InteractiveViewer.getNearestPointOnLine(point, quad.point3, quad.point0),
    ];
    double minDistance = double.infinity;
    Vector3 closestOverall;
    for (final Vector3 closePoint in closestPoints) {
      final double distance = math.sqrt(
        math.pow(point.x - closePoint.x, 2) + math.pow(point.y - closePoint.y, 2),
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestOverall = closePoint;
      }
    }
    return closestOverall;
  }

  @override _InteractiveViewerState createState() => _InteractiveViewerState();
}

class _InteractiveViewerState extends State<InteractiveViewer> with TickerProviderStateMixin {
  TransformationController _transformationController;

  final GlobalKey _childKey = GlobalKey();
  final GlobalKey _parentKey = GlobalKey();
  Animation<Offset> _animation;
  AnimationController _controller;
  Axis _panAxis; // Used with alignPanAxis.
  Offset _referenceFocalPoint; // Point where the current gesture began.
  double _scaleStart; // Scale value at start of scaling gesture.
  double _rotationStart = 0.0; // Rotation at start of rotation gesture.
  double _currentRotation = 0.0; // Rotation of _transformationController.value.
  _GestureType _gestureType;

  // TODO(justinmc): Add rotateEnabled parameter to the widget and remove this
  // hardcoded value when the rotation feature is implemented.
  // https://github.com/flutter/flutter/issues/57698
  final bool _rotateEnabled = false;

  // Used as the coefficient of friction in the inertial translation animation.
  // This value was eyeballed to give a feel similar to Google Photos.
  static const double _kDrag = 0.0000135;

  // The _boundaryRect is calculated by adding the boundaryMargin to the size of
  // the child.
  Rect get _boundaryRect {
    assert(_childKey.currentContext != null);
    assert(!widget.boundaryMargin.left.isNaN);
    assert(!widget.boundaryMargin.right.isNaN);
    assert(!widget.boundaryMargin.top.isNaN);
    assert(!widget.boundaryMargin.bottom.isNaN);

    final RenderBox childRenderBox = _childKey.currentContext.findRenderObject() as RenderBox;
    final Size childSize = childRenderBox.size;
    final Rect boundaryRect = widget.boundaryMargin.inflateRect(Offset.zero & childSize);
    // Boundaries that are partially infinite are not allowed because Matrix4's
    // rotation and translation methods don't handle infinites well.
    assert(boundaryRect.isFinite ||
        (boundaryRect.left.isInfinite
        && boundaryRect.top.isInfinite
        && boundaryRect.right.isInfinite
        && boundaryRect.bottom.isInfinite), 'boundaryRect must either be infinite in all directions or finite in all directions.');
    return boundaryRect;
  }

  // The Rect representing the child's parent.
  Rect get _viewport {
    assert(_parentKey.currentContext != null);
    final RenderBox parentRenderBox = _parentKey.currentContext.findRenderObject() as RenderBox;
    return Offset.zero & parentRenderBox.size;
  }

  // Return a new matrix representing the given matrix after applying the given
  // translation.
  Matrix4 _matrixTranslate(Matrix4 matrix, Offset translation) {
    if (translation == Offset.zero) {
      return matrix.clone();
    }

    final Offset alignedTranslation = widget.alignPanAxis && _panAxis != null
      ? _alignAxis(translation, _panAxis)
      : translation;

    final Matrix4 nextMatrix = matrix.clone()..translate(
      alignedTranslation.dx,
      alignedTranslation.dy,
    );

    // Transform the viewport to determine where its four corners will be after
    // the child has been transformed.
    final Quad nextViewport = _transformViewport(nextMatrix, _viewport);

    // If the boundaries are infinite, then no need to check if the translation
    // fits within them.
    if (_boundaryRect.isInfinite) {
      return nextMatrix;
    }

    // Expand the boundaries with rotation. This prevents the problem where a
    // mismatch in orientation between the viewport and boundaries effectively
    // limits translation. With this approach, all points that are visible with
    // no rotation are visible after rotation.
    final Quad boundariesAabbQuad = _getAxisAlignedBoundingBoxWithRotation(
      _boundaryRect,
      _currentRotation,
    );

    // If the given translation fits completely within the boundaries, allow it.
    final Offset offendingDistance = _exceedsBy(boundariesAabbQuad, nextViewport);
    if (offendingDistance == Offset.zero) {
      return nextMatrix;
    }

    // Desired translation goes out of bounds, so translate to the nearest
    // in-bounds point instead.
    final Offset nextTotalTranslation = _getMatrixTranslation(nextMatrix);
    final double currentScale = matrix.getMaxScaleOnAxis();
    final Offset correctedTotalTranslation = Offset(
      nextTotalTranslation.dx - offendingDistance.dx * currentScale,
      nextTotalTranslation.dy - offendingDistance.dy * currentScale,
    );
    // TODO(justinmc): This needs some work to handle rotation properly. The
    // idea is that the boundaries are axis aligned (boundariesAabbQuad), but
    // calculating the translation to put the viewport inside that Quad is more
    // complicated than this when rotated.
     // https://github.com/flutter/flutter/issues/57698
    final Matrix4 correctedMatrix = matrix.clone()..setTranslation(Vector3(
      correctedTotalTranslation.dx,
      correctedTotalTranslation.dy,
      0.0,
    ));

    // Double check that the corrected translation fits.
    final Quad correctedViewport = _transformViewport(correctedMatrix, _viewport);
    final Offset offendingCorrectedDistance = _exceedsBy(boundariesAabbQuad, correctedViewport);
    if (offendingCorrectedDistance == Offset.zero) {
      return correctedMatrix;
    }

    // If the corrected translation doesn't fit in either direction, don't allow
    // any translation at all. This happens when the viewport is larger than the
    // entire boundary.
    if (offendingCorrectedDistance.dx != 0.0 && offendingCorrectedDistance.dy != 0.0) {
      return matrix.clone();
    }

    // Otherwise, allow translation in only the direction that fits. This
    // happens when the viewport is larger than the boundary in one direction.
    final Offset unidirectionalCorrectedTotalTranslation = Offset(
      offendingCorrectedDistance.dx == 0.0 ? correctedTotalTranslation.dx : 0.0,
      offendingCorrectedDistance.dy == 0.0 ? correctedTotalTranslation.dy : 0.0,
    );
    return matrix.clone()..setTranslation(Vector3(
      unidirectionalCorrectedTotalTranslation.dx,
      unidirectionalCorrectedTotalTranslation.dy,
      0.0,
    ));
  }

  // Return a new matrix representing the given matrix after applying the given
  // scale.
  Matrix4 _matrixScale(Matrix4 matrix, double scale) {
    if (scale == 1.0) {
      return matrix.clone();
    }
    assert(scale != 0.0);

    // Don't allow a scale that results in an overall scale beyond min/max
    // scale.
    final double currentScale = _transformationController.value.getMaxScaleOnAxis();
    final double totalScale = currentScale * scale;
    final double clampedTotalScale = totalScale.clamp(
      widget.minScale,
      widget.maxScale,
    ) as double;
    final double clampedScale = clampedTotalScale / currentScale;
    final Matrix4 nextMatrix = matrix.clone()..scale(clampedScale);

    // Ensure that the scale cannot make the child so big that it can't fit
    // inside the boundaries (in either direction).
    final double minScale = math.max(
      _viewport.width / _boundaryRect.width,
      _viewport.height / _boundaryRect.height,
    );
    if (clampedTotalScale < minScale) {
      final double minCurrentScale = minScale / currentScale;
      return matrix.clone()..scale(minCurrentScale);
    }

    return nextMatrix;
  }

  // Return a new matrix representing the given matrix after applying the given
  // rotation.
  Matrix4 _matrixRotate(Matrix4 matrix, double rotation, Offset focalPoint) {
    if (rotation == 0) {
      return matrix.clone();
    }
    final Offset focalPointScene = _transformationController.toScene(
      focalPoint,
    );
    return matrix
      .clone()
      ..translate(focalPointScene.dx, focalPointScene.dy)
      ..rotateZ(-rotation)
      ..translate(-focalPointScene.dx, -focalPointScene.dy);
  }

  // Returns true iff the given _GestureType is enabled.
  bool _gestureIsSupported(_GestureType gestureType) {
    switch (gestureType) {
      case _GestureType.rotate:
        return _rotateEnabled;

      case _GestureType.scale:
        return widget.scaleEnabled;

      case _GestureType.pan:
      default:
        return widget.panEnabled;
    }
  }

  // Decide which type of gesture this is by comparing the amount of scale
  // and rotation in the gesture, if any. Scale starts at 1 and rotation
  // starts at 0. Pan will have no scale and no rotation because it uses only one
  // finger.
  _GestureType _getGestureType(ScaleUpdateDetails details) {
    final double scale = !widget.scaleEnabled ? 1.0 : details.scale;
    final double rotation = !_rotateEnabled ? 0.0 : details.rotation;
    if ((scale - 1).abs() > rotation.abs()) {
      return _GestureType.scale;
    } else if (rotation != 0.0) {
      return _GestureType.rotate;
    } else {
      return _GestureType.pan;
    }
  }

  // Handle the start of a gesture. All of pan, scale, and rotate are handled
  // with GestureDetector's scale gesture.
  void _onScaleStart(ScaleStartDetails details) {
    if (widget.onInteractionStart != null) {
      widget.onInteractionStart(details);
    }

    if (_controller.isAnimating) {
      _controller.stop();
      _controller.reset();
      _animation?.removeListener(_onAnimate);
      _animation = null;
    }

    _gestureType = null;
    _panAxis = null;
    _scaleStart = _transformationController.value.getMaxScaleOnAxis();
    _referenceFocalPoint = _transformationController.toScene(
      details.localFocalPoint,
    );
    _rotationStart = _currentRotation;
  }

  // Handle an update to an ongoing gesture. All of pan, scale, and rotate are
  // handled with GestureDetector's scale gesture.
  void _onScaleUpdate(ScaleUpdateDetails details) {
    final double scale = _transformationController.value.getMaxScaleOnAxis();
    if (widget.onInteractionUpdate != null) {
      widget.onInteractionUpdate(ScaleUpdateDetails(
        focalPoint: _transformationController.toScene(
          details.localFocalPoint,
        ),
        scale: details.scale,
        rotation: details.rotation,
      ));
    }
    final Offset focalPointScene = _transformationController.toScene(
      details.localFocalPoint,
    );

    if (_gestureType == _GestureType.pan) {
      // When a gesture first starts, it sometimes has no change in scale and
      // rotation despite being a two-finger gesture. Here the gesture is
      // allowed to be reinterpreted as its correct type after originally
      // being marked as a pan.
      _gestureType = _getGestureType(details);
    } else {
      _gestureType ??= _getGestureType(details);
    }
    if (!_gestureIsSupported(_gestureType)) {
      return;
    }

    switch (_gestureType) {
      case _GestureType.scale:
        assert(_scaleStart != null);
        // details.scale gives us the amount to change the scale as of the
        // start of this gesture, so calculate the amount to scale as of the
        // previous call to _onScaleUpdate.
        final double desiredScale = _scaleStart * details.scale;
        final double scaleChange = desiredScale / scale;
        _transformationController.value = _matrixScale(
          _transformationController.value,
          scaleChange,
        );

        // While scaling, translate such that the user's two fingers stay on
        // the same places in the scene. That means that the focal point of
        // the scale should be on the same place in the scene before and after
        // the scale.
        final Offset focalPointSceneScaled = _transformationController.toScene(
          details.localFocalPoint,
        );
        _transformationController.value = _matrixTranslate(
          _transformationController.value,
          focalPointSceneScaled - _referenceFocalPoint,
        );

        // details.localFocalPoint should now be at the same location as the
        // original _referenceFocalPoint point. If it's not, that's because
        // the translate came in contact with a boundary. In that case, update
        // _referenceFocalPoint so subsequent updates happen in relation to
        // the new effective focal point.
        final Offset focalPointSceneCheck = _transformationController.toScene(
          details.localFocalPoint,
        );
        if (_round(_referenceFocalPoint) != _round(focalPointSceneCheck)) {
          _referenceFocalPoint = focalPointSceneCheck;
        }
        return;

      case _GestureType.rotate:
        if (details.rotation == 0.0) {
          return;
        }
        final double desiredRotation = _rotationStart + details.rotation;
        _transformationController.value = _matrixRotate(
          _transformationController.value,
          _currentRotation - desiredRotation,
          details.localFocalPoint,
        );
        _currentRotation = desiredRotation;
        return;

      case _GestureType.pan:
        assert(_referenceFocalPoint != null);
        // details may have a change in scale here when scaleEnabled is false.
        // In an effort to keep the behavior similar whether or not scaleEnabled
        // is true, these gestures are thrown away.
        if (details.scale != 1.0) {
          return;
        }
        _panAxis ??= _getPanAxis(_referenceFocalPoint, focalPointScene);
        // Translate so that the same point in the scene is underneath the
        // focal point before and after the movement.
        final Offset translationChange = focalPointScene - _referenceFocalPoint;
        _transformationController.value = _matrixTranslate(
          _transformationController.value,
          translationChange,
        );
        _referenceFocalPoint = _transformationController.toScene(
          details.localFocalPoint,
        );
        return;
    }
  }

  // Handle the end of a gesture of _GestureType. All of pan, scale, and rotate
  // are handled with GestureDetector's scale gesture.
  void _onScaleEnd(ScaleEndDetails details) {
    if (widget.onInteractionEnd != null) {
      widget.onInteractionEnd(details);
    }
    _scaleStart = null;
    _rotationStart = null;
    _referenceFocalPoint = null;

    _animation?.removeListener(_onAnimate);
    _controller.reset();

    if (!_gestureIsSupported(_gestureType)) {
      _panAxis = null;
      return;
    }

    // If the scale ended with enough velocity, animate inertial movement.
    if (_gestureType != _GestureType.pan || details.velocity.pixelsPerSecond.distance < kMinFlingVelocity) {
      _panAxis = null;
      return;
    }

    final Vector3 translationVector = _transformationController.value.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
    final FrictionSimulation frictionSimulationX = FrictionSimulation(
      _kDrag,
      translation.dx,
      details.velocity.pixelsPerSecond.dx,
    );
    final FrictionSimulation frictionSimulationY = FrictionSimulation(
      _kDrag,
      translation.dy,
      details.velocity.pixelsPerSecond.dy,
    );
    final double tFinal = _getFinalTime(
      details.velocity.pixelsPerSecond.distance,
      _kDrag,
    );
    _animation = Tween<Offset>(
      begin: translation,
      end: Offset(frictionSimulationX.finalX, frictionSimulationY.finalX),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    ));
    _controller.duration = Duration(milliseconds: (tFinal * 1000).round());
    _animation.addListener(_onAnimate);
    _controller.forward();
  }

  // Handle mousewheel scroll events.
  void _receivedPointerSignal(PointerSignalEvent event) {
    if (!_gestureIsSupported(_GestureType.scale)) {
      return;
    }
    if (event is PointerScrollEvent) {
      final RenderBox childRenderBox = _childKey.currentContext.findRenderObject() as RenderBox;
      final Size childSize = childRenderBox.size;
      final double scaleChange = 1.0 - event.scrollDelta.dy / childSize.height;
      if (scaleChange == 0.0) {
        return;
      }
      final Offset focalPointScene = _transformationController.toScene(
        event.localPosition,
      );
      _transformationController.value = _matrixScale(
        _transformationController.value,
        scaleChange,
      );

      // After scaling, translate such that the event's position is at the
      // same scene point before and after the scale.
      final Offset focalPointSceneScaled = _transformationController.toScene(
        event.localPosition,
      );
      _transformationController.value = _matrixTranslate(
        _transformationController.value,
        focalPointSceneScaled - focalPointScene,
      );
    }
  }

  // Handle inertia drag animation.
  void _onAnimate() {
    if (!_controller.isAnimating) {
      _panAxis = null;
      _animation?.removeListener(_onAnimate);
      _animation = null;
      _controller.reset();
      return;
    }
    // Translate such that the resulting translation is _animation.value.
    final Vector3 translationVector = _transformationController.value.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
    final Offset translationScene = _transformationController.toScene(
      translation,
    );
    final Offset animationScene = _transformationController.toScene(
      _animation.value,
    );
    final Offset translationChangeScene = animationScene - translationScene;
    _transformationController.value = _matrixTranslate(
      _transformationController.value,
      translationChangeScene,
    );
  }

  void _onTransformationControllerChange() {
    // A change to the TransformationController's value is a change to the
    // state.
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _transformationController = widget.transformationController
        ?? TransformationController();
    _transformationController.addListener(_onTransformationControllerChange);
    _controller = AnimationController(
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(InteractiveViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle all cases of needing to dispose and initialize
    // transformationControllers.
    if (oldWidget.transformationController == null) {
      if (widget.transformationController != null) {
        _transformationController.removeListener(_onTransformationControllerChange);
        _transformationController.dispose();
        _transformationController = widget.transformationController;
        _transformationController.addListener(_onTransformationControllerChange);
      }
    } else {
      if (widget.transformationController == null) {
        _transformationController.removeListener(_onTransformationControllerChange);
        _transformationController = TransformationController();
        _transformationController.addListener(_onTransformationControllerChange);
      } else if (widget.transformationController != oldWidget.transformationController) {
        _transformationController.removeListener(_onTransformationControllerChange);
        _transformationController = widget.transformationController;
        _transformationController.addListener(_onTransformationControllerChange);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _transformationController.removeListener(_onTransformationControllerChange);
    if (widget.transformationController == null) {
      _transformationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Transform(
      transform: _transformationController.value,
      child: KeyedSubtree(
        key: _childKey,
        child: widget.child,
      ),
    );

    if (!widget.constrained) {
      child = ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0.0,
          minHeight: 0.0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: child,
        ),
      );
    }

    // A GestureDetector allows the detection of panning and zooming gestures on
    // the child.
    return Listener(
      key: _parentKey,
      onPointerSignal: _receivedPointerSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // Necessary when panning off screen.
        onScaleEnd: _onScaleEnd,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        child: child,
      ),
    );
  }
}

/// A thin wrapper on [ValueNotifier] whose value is a [Matrix4] representing a
/// transformation.
///
/// The [value] defaults to the identity matrix, which corresponds to no
/// transformation.
///
/// See also:
///
///  * [InteractiveViewer.transformationController] for detailed documentation
///    on how to use TransformationController with [InteractiveViewer].
class TransformationController extends ValueNotifier<Matrix4> {
  /// Create an instance of [TransformationController].
  ///
  /// The [value] defaults to the identity matrix, which corresponds to no
  /// transformation.
  TransformationController([Matrix4 value]) : super(value ?? Matrix4.identity());

  /// Return the scene point at the given viewport point.
  ///
  /// A viewport point is relative to the parent while a scene point is relative
  /// to the child, regardless of transformation. Calling toScene with a
  /// viewport point essentially returns the scene coordinate that lies
  /// underneath the viewport point given the transform.
  ///
  /// The viewport transforms as the inverse of the child (i.e. moving the child
  /// left is equivalent to moving the viewport right).
  ///
  /// This method is often useful when determining where an event on the parent
  /// occurs on the child. This example shows how to determine where a tap on
  /// the parent occurred on the child.
  ///
  /// ```dart
  /// @override
  /// void build(BuildContext context) {
  ///   return GestureDetector(
  ///     onTapUp: (TapUpDetails details) {
  ///       _childWasTappedAt = _transformationController.toScene(
  ///         details.localPosition,
  ///       );
  ///     },
  ///     child: InteractiveViewer(
  ///       transformationController: _transformationController,
  ///       child: child,
  ///     ),
  ///   );
  /// }
  /// ```
  Offset toScene(Offset viewportPoint) {
    // On viewportPoint, perform the inverse transformation of the scene to get
    // where the point would be in the scene before the transformation.
    final Matrix4 inverseMatrix = Matrix4.inverted(value);
    final Vector3 untransformed = inverseMatrix.transform3(Vector3(
      viewportPoint.dx,
      viewportPoint.dy,
      0,
    ));
    return Offset(untransformed.x, untransformed.y);
  }
}

// A classification of relevant user gestures. Each contiguous user gesture is
// represented by exactly one _GestureType.
enum _GestureType {
  pan,
  scale,
  rotate,
}

// Given a velocity and drag, calculate the time at which motion will come to
// a stop, within the margin of effectivelyMotionless.
double _getFinalTime(double velocity, double drag) {
  const double effectivelyMotionless = 10.0;
  return math.log(effectivelyMotionless / velocity) / math.log(drag / 100);
}

// Return the translation from the given Matrix4 as an Offset.
Offset _getMatrixTranslation(Matrix4 matrix) {
  final Vector3 nextTranslation = matrix.getTranslation();
  return Offset(nextTranslation.x, nextTranslation.y);
}

// Transform the four corners of the viewport by the inverse of the given
// matrix. This gives the viewport after the child has been transformed by the
// given matrix. The viewport transforms as the inverse of the child (i.e.
// moving the child left is equivalent to moving the viewport right).
Quad _transformViewport(Matrix4 matrix, Rect viewport) {
  final Matrix4 inverseMatrix = matrix.clone()..invert();
  return Quad.points(
    inverseMatrix.transform3(Vector3(
      viewport.topLeft.dx,
      viewport.topLeft.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.topRight.dx,
      viewport.topRight.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.bottomRight.dx,
      viewport.bottomRight.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.bottomLeft.dx,
      viewport.bottomLeft.dy,
      0.0,
    )),
  );
}

// Find the axis aligned bounding box for the rect rotated about its center by
// the given amount.
Quad _getAxisAlignedBoundingBoxWithRotation(Rect rect, double rotation) {
  final Matrix4 rotationMatrix = Matrix4.identity()
      ..translate(rect.size.width / 2, rect.size.height / 2)
      ..rotateZ(rotation)
      ..translate(-rect.size.width / 2, -rect.size.height / 2);
  final Quad boundariesRotated = Quad.points(
    rotationMatrix.transform3(Vector3(rect.left, rect.top, 0.0)),
    rotationMatrix.transform3(Vector3(rect.right, rect.top, 0.0)),
    rotationMatrix.transform3(Vector3(rect.right, rect.bottom, 0.0)),
    rotationMatrix.transform3(Vector3(rect.left, rect.bottom, 0.0)),
  );
  return InteractiveViewer.getAxisAlignedBoundingBox(boundariesRotated);
}

// Return the amount that viewport lies outside of boundary. If the viewport
// is completely contained within the boundary (inclusively), then returns
// Offset.zero.
Offset _exceedsBy(Quad boundary, Quad viewport) {
  final List<Vector3> viewportPoints = <Vector3>[
    viewport.point0, viewport.point1, viewport.point2, viewport.point3,
  ];
  Offset largestExcess = Offset.zero;
  for (final Vector3 point in viewportPoints) {
    final Vector3 pointInside = InteractiveViewer.getNearestPointInside(point, boundary);
    final Offset excess = Offset(
      pointInside.x - point.x,
      pointInside.y - point.y,
    );
    if (excess.dx.abs() > largestExcess.dx.abs()) {
      largestExcess = Offset(excess.dx, largestExcess.dy);
    }
    if (excess.dy.abs() > largestExcess.dy.abs()) {
      largestExcess = Offset(largestExcess.dx, excess.dy);
    }
  }

  return _round(largestExcess);
}

// Round the output values. This works around a precision problem where
// values that should have been zero were given as within 10^-10 of zero.
Offset _round(Offset offset) {
  return Offset(
    double.parse(offset.dx.toStringAsFixed(9)),
    double.parse(offset.dy.toStringAsFixed(9)),
  );
}

// Align the given offset to the given axis by allowing movement only in the
// axis direction.
Offset _alignAxis(Offset offset, Axis axis) {
  switch (axis) {
    case Axis.horizontal:
      return Offset(offset.dx, 0.0);
    case Axis.vertical:
    default:
      return Offset(0.0, offset.dy);
  }
}

// Given two points, return the axis where the distance between the points is
// greatest. If they are equal, return null.
Axis _getPanAxis(Offset point1, Offset point2) {
  if (point1 == point2) {
    return null;
  }
  final double x = point2.dx - point1.dx;
  final double y = point2.dy - point1.dy;
  return x.abs() > y.abs() ? Axis.horizontal : Axis.vertical;
}
