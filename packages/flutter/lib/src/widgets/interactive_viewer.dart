// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:vector_math/vector_math_64.dart' show Quad, Vector3, Matrix3, Matrix4;

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'ticker_provider.dart';

/// A widget that enables pan and zoom interactions with its child.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=zrn7V3bMJvg}
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
    Key? key,
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
    this.rotateEnabled = true,
    this.scaleEnabled = true,
    this.transformationController,
    required this.child,
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
  ///
  /// See also:
  ///  * [constrained], which has an example of creating a table that uses
  ///    alignPanAxis.
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
  /// For example, for a child which is bigger than the viewport but can be
  /// panned to reveal parts that were initially offscreen, [constrained] must
  /// be set to false to allow it to size itself properly. If [constrained] is
  /// true and the child can only size itself to the viewport, then areas
  /// initially outside of the viewport will not be able to receive user
  /// interaction events. If experiencing regions of the child that are not
  /// receptive to user gestures, make sure [constrained] is false and the child
  /// is sized properly.
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
  ///     const int _rowCount = 48;
  ///     const int _columnCount = 6;
  ///
  ///     return InteractiveViewer(
  ///       alignPanAxis: true,
  ///       constrained: false,
  ///       scaleEnabled: false,
  ///       child: Table(
  ///         columnWidths: <int, TableColumnWidth>{
  ///           for (int column = 0; column < _columnCount; column += 1)
  ///             column: const FixedColumnWidth(200.0),
  ///         },
  ///         children: <TableRow>[
  ///           for (int row = 0; row < _rowCount; row += 1)
  ///             TableRow(
  ///               children: <Widget>[
  ///                 for (int column = 0; column < _columnCount; column += 1)
  ///                   Container(
  ///                     height: 26,
  ///                     color: row % 2 + column % 2 == 1
  ///                         ? Colors.white
  ///                         : Colors.grey.withOpacity(0.1),
  ///                     child: Align(
  ///                       alignment: Alignment.centerLeft,
  ///                       child: Text('$row x $column'),
  ///                     ),
  ///                   ),
  ///               ],
  ///             ),
  ///         ],
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
  ///   * [rotateEnabled], which is similar but for rotation.
  ///   * [scaleEnabled], which is similar but for scale.
  final bool panEnabled;

  /// If false, the user will be prevented from rotating.
  ///
  /// Defaults to true.
  ///
  /// See also:
  ///
  ///   * [panEnabled], which is similar but for panning.
  ///   * [scaleEnabled], which is similar but for scale.
  final bool rotateEnabled;

  /// If false, the user will be prevented from scaling.
  ///
  /// Defaults to true.
  ///
  /// See also:
  ///
  ///   * [rotateEnabled], which is similar but for rotation.
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
  /// Scale is also affected by [boundaryMargin]. If the scale would result in
  /// viewing beyond the boundary, then it will not be allowed. By default,
  /// boundaryMargin is EdgeInsets.zero, so scaling below 1.0 will not be
  /// allowed in most cases without first increasing the boundaryMargin.
  ///
  /// Defaults to 0.8.
  ///
  /// Cannot be null, and must be a finite number greater than zero and less
  /// than maxScale.
  final double minScale;

  /// Called when the user ends a pan or scale gesture on the widget.
  ///
  /// At the time this is called, the [TransformationController] will have
  /// already been updated to reflect the change caused by the interaction.
  ///
  /// {@template flutter.widgets.InteractiveViewer.onInteractionEnd}
  /// Will be called even if the interaction is disabled with
  /// [panEnabled] or [scaleEnabled].
  ///
  /// A [GestureDetector] wrapping the InteractiveViewer will not respond to
  /// [GestureDetector.onScaleStart], [GestureDetector.onScaleUpdate], and
  /// [GestureDetector.onScaleEnd]. Use [onInteractionStart],
  /// [onInteractionUpdate], and [onInteractionEnd] to respond to those
  /// gestures.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [onInteractionStart], which handles the start of the same interaction.
  ///  * [onInteractionUpdate], which handles an update to the same interaction.
  final GestureScaleEndCallback? onInteractionEnd;

  /// Called when the user begins a pan or scale gesture on the widget.
  ///
  /// At the time this is called, the [TransformationController] will not have
  /// changed due to this interaction.
  ///
  /// {@macro flutter.widgets.InteractiveViewer.onInteractionEnd}
  ///
  /// The coordinates provided in the details' `focalPoint` and
  /// `localFocalPoint` are normal Flutter event coordinates, not
  /// InteractiveViewer scene coordinates. See
  /// [TransformationController.toScene] for how to convert these coordinates to
  /// scene coordinates relative to the child.
  ///
  /// See also:
  ///
  ///  * [onInteractionUpdate], which handles an update to the same interaction.
  ///  * [onInteractionEnd], which handles the end of the same interaction.
  final GestureScaleStartCallback? onInteractionStart;

  /// Called when the user updates a pan or scale gesture on the widget.
  ///
  /// At the time this is called, the [TransformationController] will have
  /// already been updated to reflect the change caused by the interaction.
  ///
  /// {@macro flutter.widgets.InteractiveViewer.onInteractionEnd}
  ///
  /// The coordinates provided in the details' `focalPoint` and
  /// `localFocalPoint` are normal Flutter event coordinates, not
  /// InteractiveViewer scene coordinates. See
  /// [TransformationController.toScene] for how to convert these coordinates to
  /// scene coordinates relative to the child.
  ///
  /// See also:
  ///
  ///  * [onInteractionStart], which handles the start of the same interaction.
  ///  * [onInteractionEnd], which handles the end of the same interaction.
  final GestureScaleUpdateCallback? onInteractionUpdate;

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
  /// Animation<Matrix4>? _animationReset;
  /// late final AnimationController _controllerReset;
  ///
  /// void _onAnimateReset() {
  ///   _transformationController.value = _animationReset!.value;
  ///   if (!_controllerReset.isAnimating) {
  ///     _animationReset!.removeListener(_onAnimateReset);
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
  ///   _animationReset!.addListener(_onAnimateReset);
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
  final TransformationController? transformationController;

  /// Returns true iff the point is inside the rectangle given by the Quad,
  /// inclusively.
  ///
  /// Algorithm from [https://math.stackexchange.com/a/190373].
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

  @override _InteractiveViewerState createState() => _InteractiveViewerState();
}

class _InteractiveViewerState extends State<InteractiveViewer> with TickerProviderStateMixin {
  TransformationController? _transformationController;

  final GlobalKey _childKey = GlobalKey();
  final GlobalKey _parentKey = GlobalKey();
  Animation<Offset>? _animation;
  late AnimationController _controller;
  Axis? _panAxis; // Used with alignPanAxis.
  Offset? _referenceFocalPoint; // Point where the current gesture began.
  double? _scaleStart; // Scale value at start of scaling gesture.
  double? _rotationStart = 0.0; // Rotation at start of rotation gesture.
  _GestureType? _gestureType;

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

    final RenderBox childRenderBox = _childKey.currentContext!.findRenderObject()! as RenderBox;
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
    final RenderBox parentRenderBox = _parentKey.currentContext!.findRenderObject()! as RenderBox;
    return Offset.zero & parentRenderBox.size;
  }

  // Return a new matrix representing the given matrix after applying the given
  // translation.
  Matrix4 _matrixTranslate(Matrix4 matrix, Offset translation) {
    if (translation == Offset.zero) {
      return matrix.clone();
    }

    final Offset alignedTranslation = widget.alignPanAxis && _panAxis != null
      ? _alignAxis(translation, _panAxis!)
      : translation;

    final Matrix4 nextMatrix = matrix.clone()..translate(
      alignedTranslation.dx,
      alignedTranslation.dy,
    );

    return _validateMatrix(nextMatrix, matrix);
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
    final double currentScale = _transformationController!.value.getMaxScaleOnAxis();
    final double totalScale = math.max(
      currentScale * scale,
      // Ensure that the scale cannot make the child so big that it can't fit
      // inside the boundaries (in either direction).
      math.max(
        _viewport.width / _boundaryRect.width,
        _viewport.height / _boundaryRect.height,
      ),
    );
    final double clampedTotalScale = totalScale.clamp(
      widget.minScale,
      widget.maxScale,
    );
    final double clampedScale = clampedTotalScale / currentScale;
    return matrix.clone()..scale(clampedScale);
  }

  // Return a new matrix representing the given matrix after applying the given
  // rotation.
  Matrix4 _matrixRotate(Matrix4 matrix, double rotation, Offset focalPoint) {
    if (rotation == 0) {
      return matrix.clone();
    }
    final Offset focalPointScene = _transformationController!.toScene(
      focalPoint,
    );
    return matrix
      .clone()
      ..translate(focalPointScene.dx, focalPointScene.dy)
      ..rotateZ(-rotation)
      ..translate(-focalPointScene.dx, -focalPointScene.dy);
  }

  // If the given matrix is valid, return it. If it is invalid, return the
  // closest translated matrix that is valid. If none is possible, then return
  // the given defaultMatrix.
  //
  // A valid matrix is defined as a matrix where all sides of the viewport
  // intersect the boundary. This allows the viewport to partially see beyond
  // the boundary after rotation, but keeps the entire boundary visible.
  Matrix4 _validateMatrix(Matrix4 matrix, Matrix4 defaultMatrix) {
    // If the boundaries are infinite, then no need to check if the translation
    // fits within them.
    if (_boundaryRect.isInfinite) {
      return matrix;
    }

    // Transform the viewport to determine where its four corners will be after
    // the child has been transformed.
    final Quad nextViewport = _transformViewport(matrix, _viewport);

    // Any side of the viewport that does not intersect the interior of the
    // boundary is invalid. If all sides are valid, then the matrix is valid.
    final LineSegment viewportSide01 = LineSegment.vector(
      nextViewport.point0,
      nextViewport.point1,
    );
    final LineSegment viewportSide12 = LineSegment.vector(
      nextViewport.point1,
      nextViewport.point2,
    );
    final LineSegment viewportSide23 = LineSegment.vector(
      nextViewport.point2,
      nextViewport.point3,
    );
    final LineSegment viewportSide30 = LineSegment.vector(
      nextViewport.point3,
      nextViewport.point0,
    );
    final List<LineSegment> invalidSides = <LineSegment>[
      viewportSide01,
      viewportSide12,
      viewportSide23,
      viewportSide30,
    ].where((LineSegment side) => !side.intersectsRect(_boundaryRect)).toList();
    if (invalidSides.isEmpty) {
      return matrix;
    }

    // If there are multiple invalid sides, but they are all invalid in non-
    // conflicting directions (e.g. correcting one isn't going to make another
    // worse), then they should be able to be corrected by taking the greatest
    // magnitude in each direction.
    bool magnitudesAligned = true;
    late Offset correction;
    if (invalidSides.length > 1) {
      correction = invalidSides.fold(Offset.zero, (Offset value, LineSegment invalidSide) {
        final ClosestPoints closestPoints = invalidSide.findClosestPointsRect(_boundaryRect);
        final Offset difference = closestPoints.a - closestPoints.b;
        if (magnitudesAligned) {
          final bool xMisaligned = difference.dx != 0.0 && value.dx != 0.0
              && (difference.dx > 0.0 != value.dx > 0.0);
          final bool yMisaligned = difference.dy != 0.0 && value.dy != 0.0
              && (difference.dy > 0.0 != value.dy > 0.0);
          if (xMisaligned || yMisaligned) {
            magnitudesAligned = false;
          }
        }
        return Offset(
          difference.dx.abs() > value.dx.abs() ? difference.dx : value.dx,
          difference.dy.abs() > value.dy.abs() ? difference.dy : value.dy,
        );
      });
    }

    // If there is only one invalid side, or if there are multiple but they are
    // invalid in different directions, then just try to correct the single most
    // invalid side.
    if (!magnitudesAligned || invalidSides.length == 1) {
      // Find the side that is farthest from being in a valid position.
      final LineSegment invalidSide = (invalidSides
        ..sort((LineSegment a, LineSegment b) {
          final ClosestPoints closestPointsA = a.findClosestPointsRect(_boundaryRect);
          final double distanceA = _distanceBetweenPoints(
            closestPointsA.a,
            closestPointsA.b,
          ).abs();
          final ClosestPoints closestPointsB = b.findClosestPointsRect(_boundaryRect);
          final double distanceB = _distanceBetweenPoints(
            closestPointsB.a,
            closestPointsB.b,
          ).abs();
          return distanceB.compareTo(distanceA);
        })).first;

      // Find the nearest points on boundaryRect and the viewportSide that doesn't
      // intersect to each other, and move the points on top of each other.
      final ClosestPoints closestPoints = invalidSide.findClosestPointsRect(_boundaryRect);
      correction = closestPoints.a - closestPoints.b;
    }

    final Matrix4 correctedMatrix = matrix.clone()
        ..translate(correction.dx, correction.dy);
    final Quad correctedNextViewport = _transformViewport(correctedMatrix, _viewport);

    final LineSegment correctedViewportSide01 = LineSegment.vector(
      correctedNextViewport.point0,
      correctedNextViewport.point1,
    );
    final LineSegment correctedViewportSide12 = LineSegment.vector(
      correctedNextViewport.point1,
      correctedNextViewport.point2,
    );
    final LineSegment correctedViewportSide23 = LineSegment.vector(
      correctedNextViewport.point2,
      correctedNextViewport.point3,
    );
    final LineSegment correctedViewportSide30 = LineSegment.vector(
      correctedNextViewport.point3,
      correctedNextViewport.point0,
    );

    // If this matrix is invalid and uncorrectable, then return defaultMatrix.
    if (!correctedViewportSide01.intersectsRect(_boundaryRect)
        || !correctedViewportSide12.intersectsRect(_boundaryRect)
        || !correctedViewportSide23.intersectsRect(_boundaryRect)
        || !correctedViewportSide30.intersectsRect(_boundaryRect)) {
      return defaultMatrix;
    }

    return correctedMatrix;
  }

  // Returns true iff the given _GestureType is enabled.
  bool _gestureIsSupported(_GestureType? gestureType) {
    switch (gestureType) {
      case _GestureType.rotate:
        return widget.rotateEnabled;

      case _GestureType.scale:
        return widget.scaleEnabled;

      case _GestureType.pan:
      case null:
        return widget.panEnabled;
    }
  }

  // Decide which type of gesture this is by comparing the amount of scale
  // and rotation in the gesture, if any. Scale starts at 1 and rotation
  // starts at 0. Pan will have no scale and no rotation because it uses only one
  // finger.
  _GestureType _getGestureType(ScaleUpdateDetails details) {
    final double scale = !widget.scaleEnabled ? 1.0 : details.scale;
    final double rotation = !widget.rotateEnabled ? 0.0 : details.rotation;
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
    widget.onInteractionStart?.call(details);

    if (_controller.isAnimating) {
      _controller.stop();
      _controller.reset();
      _animation?.removeListener(_onAnimate);
      _animation = null;
    }

    _gestureType = null;
    _panAxis = null;
    _scaleStart = _transformationController!.value.getMaxScaleOnAxis();
    _referenceFocalPoint = _transformationController!.toScene(
      details.localFocalPoint,
    );
    _rotationStart = _getMatrixRotation(_transformationController!.value);
  }

  // Handle an update to an ongoing gesture. All of pan, scale, and rotate are
  // handled with GestureDetector's scale gesture.
  void _onScaleUpdate(ScaleUpdateDetails details) {
    final double scale = _transformationController!.value.getMaxScaleOnAxis();
    final Offset focalPointScene = _transformationController!.toScene(
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

    switch (_gestureType!) {
      case _GestureType.scale:
        assert(_scaleStart != null);
        // details.scale gives us the amount to change the scale as of the
        // start of this gesture, so calculate the amount to scale as of the
        // previous call to _onScaleUpdate.
        final double desiredScale = _scaleStart! * details.scale;
        final double scaleChange = desiredScale / scale;
        _transformationController!.value = _matrixScale(
          _transformationController!.value,
          scaleChange,
        );

        // While scaling, translate such that the user's two fingers stay on
        // the same places in the scene. That means that the focal point of
        // the scale should be on the same place in the scene before and after
        // the scale.
        final Offset focalPointSceneScaled = _transformationController!.toScene(
          details.localFocalPoint,
        );
        _transformationController!.value = _matrixTranslate(
          _transformationController!.value,
          focalPointSceneScaled - _referenceFocalPoint!,
        );

        // details.localFocalPoint should now be at the same location as the
        // original _referenceFocalPoint point. If it's not, that's because
        // the translate came in contact with a boundary. In that case, update
        // _referenceFocalPoint so subsequent updates happen in relation to
        // the new effective focal point.
        final Offset focalPointSceneCheck = _transformationController!.toScene(
          details.localFocalPoint,
        );
        if (_roundOffset(_referenceFocalPoint!) != _roundOffset(focalPointSceneCheck)) {
          _referenceFocalPoint = focalPointSceneCheck;
        }
        break;

      case _GestureType.rotate:
        if (details.rotation == 0.0) {
          return;
        }
        final double desiredRotation = _rotationStart! + details.rotation;
        _transformationController!.value = _matrixRotate(
          _transformationController!.value,
          _getMatrixRotation(_transformationController!.value) - desiredRotation,
          details.localFocalPoint,
        );

        // While rotating, translate such that the user's two fingers stay on
        // the same places in the scene. That means that the focal point of
        // the scale should be on the same place in the scene before and after
        // the scale.
        final Offset focalPointSceneRotated = _transformationController!.toScene(
          details.localFocalPoint,
        );
        _transformationController!.value = _matrixTranslate(
          _transformationController!.value,
          focalPointSceneRotated - _referenceFocalPoint!,
        );
        break;

      case _GestureType.pan:
        assert(_referenceFocalPoint != null);
        // details may have a change in scale here when scaleEnabled is false.
        // In an effort to keep the behavior similar whether or not scaleEnabled
        // is true, these gestures are thrown away.
        if (details.scale != 1.0) {
          return;
        }
        _panAxis ??= _getPanAxis(_referenceFocalPoint!, focalPointScene);
        // Translate so that the same point in the scene is underneath the
        // focal point before and after the movement.
        final Offset translationChange = focalPointScene - _referenceFocalPoint!;
        _transformationController!.value = _matrixTranslate(
          _transformationController!.value,
          translationChange,
        );
        _referenceFocalPoint = _transformationController!.toScene(
          details.localFocalPoint,
        );
        break;
    }
    widget.onInteractionUpdate?.call(ScaleUpdateDetails(
      focalPoint: details.focalPoint,
      localFocalPoint: details.localFocalPoint,
      scale: details.scale,
      rotation: details.rotation,
    ));
  }

  // Handle the end of a gesture of _GestureType. All of pan, scale, and rotate
  // are handled with GestureDetector's scale gesture.
  void _onScaleEnd(ScaleEndDetails details) {
    widget.onInteractionEnd?.call(details);
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

    final Vector3 translationVector = _transformationController!.value.getTranslation();
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
    _animation!.addListener(_onAnimate);
    _controller.forward();
  }

  // Handle mousewheel scroll events.
  void _receivedPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      widget.onInteractionStart?.call(
        ScaleStartDetails(
          focalPoint: event.position,
          localFocalPoint: event.localPosition,
        ),
      );
      if (!_gestureIsSupported(_GestureType.scale)) {
        widget.onInteractionEnd?.call(ScaleEndDetails());
        return;
      }

      // Ignore left and right scroll.
      if (event.scrollDelta.dy == 0.0) {
        return;
      }

      // In the Flutter engine, the mousewheel scrollDelta is hardcoded to 20 per scroll, while a trackpad scroll can be any amount.
      // The calculation for scaleChange here was arbitrarily chosen to feel natural for both trackpads and mousewheels on all platforms.
      final double scaleChange = math.exp(-event.scrollDelta.dy / 200);
      final Offset focalPointScene = _transformationController!.toScene(
        event.localPosition,
      );

      _transformationController!.value = _matrixScale(
        _transformationController!.value,
        scaleChange,
      );

      // After scaling, translate such that the event's position is at the
      // same scene point before and after the scale.
      final Offset focalPointSceneScaled = _transformationController!.toScene(
        event.localPosition,
      );
      _transformationController!.value = _matrixTranslate(
        _transformationController!.value,
        focalPointSceneScaled - focalPointScene,
      );

      widget.onInteractionUpdate?.call(ScaleUpdateDetails(
        focalPoint: event.position,
        localFocalPoint: event.localPosition,
        rotation: 0.0,
        scale: scaleChange,
        horizontalScale: 1.0,
        verticalScale: 1.0,
      ));
      widget.onInteractionEnd?.call(ScaleEndDetails());
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
    final Vector3 translationVector = _transformationController!.value.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
    final Offset translationScene = _transformationController!.toScene(
      translation,
    );
    final Offset animationScene = _transformationController!.toScene(
      _animation!.value,
    );
    final Offset translationChangeScene = animationScene - translationScene;
    _transformationController!.value = _matrixTranslate(
      _transformationController!.value,
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
    _transformationController!.addListener(_onTransformationControllerChange);
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
        _transformationController!.removeListener(_onTransformationControllerChange);
        _transformationController!.dispose();
        _transformationController = widget.transformationController;
        _transformationController!.addListener(_onTransformationControllerChange);
      }
    } else {
      if (widget.transformationController == null) {
        _transformationController!.removeListener(_onTransformationControllerChange);
        _transformationController = TransformationController();
        _transformationController!.addListener(_onTransformationControllerChange);
      } else if (widget.transformationController != oldWidget.transformationController) {
        _transformationController!.removeListener(_onTransformationControllerChange);
        _transformationController = widget.transformationController;
        _transformationController!.addListener(_onTransformationControllerChange);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _transformationController!.removeListener(_onTransformationControllerChange);
    if (widget.transformationController == null) {
      _transformationController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Transform(
      transform: _transformationController!.value,
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
        dragStartBehavior: DragStartBehavior.start,
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
  TransformationController([Matrix4? value]) : super(value ?? Matrix4.identity());

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

// Returns the rotation about the z axis in radians of the given Matrix4.
double _getMatrixRotation(Matrix4 matrix) {
  final Matrix3 rotationMatrix = matrix.getRotation();
  return math.atan2(rotationMatrix.row1.x, rotationMatrix.row0.x);
}

// Transform the four corners of the viewport by the inverse of the given
// matrix. This gives the viewport after the child has been transformed by the
// given matrix. The viewport transforms as the inverse of the child (i.e.
// moving the child left is equivalent to moving the viewport right).
Quad _transformViewport(Matrix4 matrix, Rect viewport) {
  final Matrix4 inverseMatrix = Matrix4.inverted(matrix);
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


const double _kTolerance = 100000000000.0;

// Round the output values. This works around a precision problem where
// values that should have been zero were given as within 10^-10 of zero.
Offset _roundOffset(Offset offset) {
  final int digitsOfPrecision = _kTolerance.toString().length;
  return Offset(
    double.parse(offset.dx.toStringAsFixed(digitsOfPrecision)),
    double.parse(offset.dy.toStringAsFixed(digitsOfPrecision)),
  );
}

// Align the given offset to the given axis by allowing movement only in the
// axis direction.
Offset _alignAxis(Offset offset, Axis axis) {
  switch (axis) {
    case Axis.horizontal:
      return Offset(offset.dx, 0.0);
    case Axis.vertical:
      return Offset(0.0, offset.dy);
  }
}

// Given two points, return the axis where the distance between the points is
// greatest. If they are equal, return null.
Axis? _getPanAxis(Offset point1, Offset point2) {
  if (point1 == point2) {
    return null;
  }
  final double x = point2.dx - point1.dx;
  final double y = point2.dy - point1.dy;
  return x.abs() > y.abs() ? Axis.horizontal : Axis.vertical;
}

// Simple 2D distance formula.
double _distanceBetweenPoints(Offset a, Offset b) {
  return math.sqrt(math.pow(b.dx - a.dx, 2) + math.pow(b.dy - a.dy, 2));
}

/// Represents a line segment between the two given points.
@visibleForTesting
class LineSegment {
  /// Create a line segments from Offsets.
  const LineSegment(
    this.p0,
    this.p1,
  );

  /// Create a line segments from Vector3s.
  LineSegment.vector(
    Vector3 v0,
    Vector3 v1,
  ) : p0 = Offset(v0.x, v0.y),
      p1 = Offset(v1.x, v1.y);

  /// The first endpoint of the line segment.
  final Offset p0;

  /// The second endpoint of the line segment.
  final Offset p1;

  /// The slope of the line segment defined by change in y over change in x.
  double get slope {
    return (p1.dy - p0.dy) / (p1.dx - p0.dx);
  }

  /// The y-intercept, if this line segment were a line that continued
  /// indefinitely.
  double get lineYIntercept => p0.dy - slope * p0.dx;

  // True iff the Rect contains the Offset inclusively for all of its sides with
  // some tolerance for error. Rect.contains only considers the top and left
  // sides inclusively.
  static bool _rectContainsInclusive(Rect rect, Offset offset) {
    final Rect rRect = Rect.fromLTRB(
      (rect.top * _kTolerance).round() / _kTolerance,
      (rect.left * _kTolerance).round() / _kTolerance,
      (rect.right * _kTolerance).round() / _kTolerance,
      (rect.bottom * _kTolerance).round() / _kTolerance,
    );
    final Offset rOffset = Offset(
      (offset.dx * _kTolerance).round() / _kTolerance,
      (offset.dy * _kTolerance).round() / _kTolerance,
    );
    return rOffset.dx >= rRect.left && rOffset.dx <= rRect.right
        && rOffset.dy >= rRect.top && rOffset.dy <= rRect.bottom;
  }

  /// A special case of the linesIntersectAt method.
  static Offset _isVerticalAndInterceptsNonVerticalLineAt(LineSegment vertical, LineSegment nonVertical) {
    // Assert vertical is indeed vertical and nonVertical is not vertical.
    assert(vertical.p0.dx == vertical.p1.dx);
    assert(nonVertical.p0.dx != nonVertical.p1.dx);

    final double x = vertical.p0.dx;
    final double intersectionY = nonVertical.slope * x + nonVertical.lineYIntercept;
    assert(x.isFinite);
    assert(intersectionY.isFinite);
    return Offset(
      (x * _kTolerance).round() / _kTolerance,
      (intersectionY * _kTolerance).round() / _kTolerance,
    );
  }

  // A special case of the intercepts method.
  static bool _isVerticalAndInterceptsNonVertical(LineSegment vertical, LineSegment nonVertical) {
    final Offset intersection = _isVerticalAndInterceptsNonVerticalLineAt(vertical, nonVertical);
    return vertical.contains(intersection) && nonVertical.contains(intersection);
  }

  /// True iff the line containing this line segment also contains the given
  /// offset.
  bool _lineContains(Offset offset) {
    // Special case vertical line because of infinite slope.
    if (p0.dx == p1.dx) {
      return (offset.dx - p0.dx).abs() <= 1 / _kTolerance;
    }
    // Use the line formula with a tolerance.
    return (offset.dy - (slope * offset.dx + lineYIntercept)).abs() <= 1 / _kTolerance;
  }

  /// True iff the offset lies on the line segment, inclusively.
  @visibleForTesting
  bool contains(Offset offset) {
    final double xMin = math.min(p0.dx, p1.dx);
    final double xMax = math.max(p0.dx, p1.dx);
    final double yMin = math.min(p0.dy, p1.dy);
    final double yMax = math.max(p0.dy, p1.dy);
    return _lineContains(offset)
        && offset.dx >= xMin && offset.dx <= xMax
        && offset.dy >= yMin && offset.dy <= yMax;
  }

  /// For the infintely long lines represented by these line segments, return
  /// the point at which they intersect, or null if parallel.
  @visibleForTesting
  Offset? linesIntersectAt(LineSegment lineSegment) {
    // Return null if the lines are parallel, even if they overlap.
    if (lineSegment.slope == slope || (lineSegment.slope.isInfinite && slope.isInfinite)) {
      return null;
    }

    // Handle if the slopes are different but one line segment is vertical
    // (infinite slope).
    if (!slope.isFinite) {
      return _isVerticalAndInterceptsNonVerticalLineAt(this, lineSegment);
    }
    if (!lineSegment.slope.isFinite) {
      return _isVerticalAndInterceptsNonVerticalLineAt(lineSegment, this);
    }

    // If the slopes are different and not vertical, the corresponding lines
    // must intersect.
    // x = (b1 - b) / (m - m1)
    final double intersectionX = (lineSegment.lineYIntercept - lineYIntercept)
        / (slope - lineSegment.slope);
    assert(intersectionX.isFinite);

    // y = m * intersectionX + b
    final double intersectionY = slope * intersectionX + lineYIntercept;
    assert(intersectionY.isFinite);
    return Offset(intersectionX, intersectionY);
  }

  /// True iff the given line segment intersects this one, inclusively.
  bool intersects(LineSegment lineSegment) {
    // If the slopes are the same, they intersect if they overlap.
    if (lineSegment.slope == slope || (lineSegment.slope.isInfinite && slope.isInfinite)) {
      return contains(lineSegment.p0) || contains(lineSegment.p1);
    }

    // Handle if the slopes are different but one line segment is vertical
    // (infinite slope).
    if (!slope.isFinite) {
      return _isVerticalAndInterceptsNonVertical(this, lineSegment);
    }
    if (!lineSegment.slope.isFinite) {
      return _isVerticalAndInterceptsNonVertical(lineSegment, this);
    }

    // If the slopes are different and not vertical, the corresponding lines
    // (not segments) must overlap. If that point happens between the endpoints
    // of both line segments, then the line segmens intersect.
    // x = (b1 - b) / (m - m1)
    final double intersectionX = (lineSegment.lineYIntercept - lineYIntercept)
        / (slope - lineSegment.slope);
    assert(intersectionX.isFinite);

    // y = m * intersectionX + b
    final double intersectionY = slope * intersectionX + lineYIntercept;
    assert(intersectionY.isFinite);
    final Offset intersection = Offset(intersectionX, intersectionY);

    return contains(intersection) && lineSegment.contains(intersection);
  }

  /// Returns true iff this line segment intersects the given rect, inclusively.
  bool intersectsRect(Rect rect) {
    // Intersects if either point, or both, is inside of the rectangle,
    // inclusively.
    if (_rectContainsInclusive(rect, p0) || _rectContainsInclusive(rect, p1)) {
      return true;
    }

    // Otherwise, intersects the rect if it intersects any of the four sides.
    final LineSegment top = LineSegment(rect.topLeft, rect.topRight);
    final LineSegment right = LineSegment(rect.topRight, rect.bottomRight);
    final LineSegment bottom = LineSegment(rect.bottomRight, rect.bottomLeft);
    final LineSegment left = LineSegment(rect.bottomLeft, rect.topLeft);
    return intersects(top) || intersects(right)
        || intersects(bottom) || intersects(left);
  }

  /// Assuming that the given point is on the extended line of this line segment,
  /// returns the closest point on the line segment to it.
  @visibleForTesting
  Offset findClosestOffsetOnLineSegmentToOffsetOnLine(Offset pointOnLine) {
    assert(_lineContains(pointOnLine));
    if (contains(pointOnLine)) {
      return pointOnLine;
    }
    final double d0 = _distanceBetweenPoints(pointOnLine, p0);
    final double d1 = _distanceBetweenPoints(pointOnLine, p1);
    return d0 <= d1 ? p0 : p1;
  }

  /// Returns the closest point on each [LineSegment] to the other
  /// [LineSegment].
  ///
  /// In the returned [ClosestPoints], [ClosestPoints.a] represents the point on
  /// this [LineSegment], and [ClosestPoints.b] represents the point on the
  /// given [LineSegment].
  @visibleForTesting
  ClosestPoints findClosestPointsLineSegment(LineSegment lineSegment) {
    final Offset? lineIntersection = linesIntersectAt(lineSegment);

    // If the lines don't intersect (the line segments are parallel), then there
    // are many closest points. This will return p0 and the closest point to p0.
    if (lineIntersection == null) {
      final Offset closestToP0 = lineSegment.findClosestToOffset(p0);
      return ClosestPoints(
        a: p0,
        b: closestToP0,
      );
    }

    // Otherwise, find the closest points on each line segment to the
    // intersection.
    final Offset closestToIntersection =
        findClosestOffsetOnLineSegmentToOffsetOnLine(lineIntersection);
    final Offset closestToIntersectionLineSegment =
        lineSegment.findClosestOffsetOnLineSegmentToOffsetOnLine(lineIntersection);

    // The answer is the closest points on the opposite line segment to these
    // points.
    return ClosestPoints(
      a: findClosestToOffset(closestToIntersectionLineSegment),
      b: lineSegment.findClosestToOffset(closestToIntersection),
    );
  }

  /// Returns the points on the [LineSegment] and [Rect] closest to each other.
  ///
  /// Assumes that they do not intersect.
  ///
  /// In the returned [ClosestPoints], [ClosestPoints.a] represents the point on
  /// this [LineSegment] and [ClosestPoints.b] represents the point on the given
  /// [Rect].
  @visibleForTesting
  ClosestPoints findClosestPointsRect(Rect rect) {
    assert(!intersectsRect(rect));

    final LineSegment top = LineSegment(rect.topLeft, rect.topRight);
    final ClosestPoints toTop = findClosestPointsLineSegment(top);
    final LineSegment right = LineSegment(rect.topRight, rect.bottomRight);
    final ClosestPoints toRight = findClosestPointsLineSegment(right);
    final LineSegment bottom = LineSegment(rect.bottomLeft, rect.bottomRight);
    final ClosestPoints toBottom = findClosestPointsLineSegment(bottom);
    final LineSegment left = LineSegment(rect.topLeft, rect.bottomLeft);
    final ClosestPoints toLeft = findClosestPointsLineSegment(left);

    return (<ClosestPoints>[toTop, toRight, toBottom, toLeft]
        ..sort((ClosestPoints first, ClosestPoints second) {
          final double firstDistance = _distanceBetweenPoints(first.a, first.b);
          final double secondDistance = _distanceBetweenPoints(second.a, second.b);
          return firstDistance.compareTo(secondDistance);
        })).first;
  }

  /// Returns the closest [Offset] on this [LineSegment] to the given Offset.
  @visibleForTesting
  Offset findClosestToOffset(Offset offset) {
    // If the line segment is just a point, then that's the only option for the
    // closest point.
    if (p0 == p1) {
      return p0;
    }

    final double lengthSquared = math.pow(p1.dx - p0.dx, 2.0).toDouble()
        + math.pow(p1.dy - p0.dy, 2.0).toDouble();

    // Calculate how far down the line segment the closest point is and return
    // the point.
    final Offset p0O = offset - p0;
    final Offset p0P1 = p1 - p0;
    final double dotProduct = p0O.dx * p0P1.dx + p0O.dy * p0P1.dy;
    final double fraction = (dotProduct / lengthSquared).clamp(0.0, 1.0).toDouble();
    return p0 + p0P1 * fraction;
  }

  @override
  String toString() {
    return '$p0, $p1';
  }
}

/// A pair of Offsets representing the closest points on two bodies to each
/// other.
@visibleForTesting
class ClosestPoints {
  /// Create a set of closest points.
  const ClosestPoints ({
    required this.a,
    required this.b,
  });

  /// The first Offset;
  final Offset a;
  /// The second Offset;
  final Offset b;

  @override
  String toString() {
    return '$a, $b';
  }
}
