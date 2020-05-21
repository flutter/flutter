// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' show Quad, Vector3, Matrix4;
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'layout_builder.dart';
import 'ticker_provider.dart';

/// A thin wrapper on ValueNotifier whose value is a [Matrix4] representing a
/// transformation.
///
/// The [value] defaults to the identity matrix, which corresponds to no
/// transformation.
///
/// See also:
///  * [InteractiveViewer.transformationController]
class TransformationController extends ValueNotifier<Matrix4> {
  /// Create an instance of [TransformationController].
  ///
  /// The [value] defaults to the identity matrix, which corresponds to no
  /// transformation.
  TransformationController([Matrix4 value]) : super(value ?? Matrix4.identity());

  /// Return the scene point at the given viewport point.
  ///
  /// A viewport point is relative to the parent while a scene point is relative
  /// to the child, regardless of transformation. Calling fromViewport with a
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
  ///       _childWasTappedAt = _transformationController.fromViewport(
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
  Offset fromViewport(Offset viewportPoint) {
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

/// A widget that enables pan and zoom interactions with its child.
///
/// The user can transform the child by dragging to pan or pinching to zoom.
///
/// The [child] must not be null.
///
/// [disableRotation] must be true because the rotation feature is not yet
/// available. This requirement will be removed in the future when rotation is
/// available.
///
/// {@tool dartpad --template=stateful_widget_material_ticker}
/// This example shows how to use InteractiveViewer in the simple case of
/// panning over a large widget representing a table.
///
/// ```dart
///   const _rowCount = 20;
///   const _columnCount = 3;
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         title: const Text('Pannable Table'),
///       ),
///       body: InteractiveViewer(
///         disableRotation: true,
///         disableScale: true,
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
@immutable
class InteractiveViewer extends StatefulWidget {
  /// Create an InteractiveViewer.
  ///
  /// The [child] parameter must not be null. The [minScale] paramter must be
  /// greater than zero.
  InteractiveViewer({
    Key key,
    @required this.child,
    this.boundaryMargin = EdgeInsets.zero,
    this.disableRotation = false,
    this.disableScale = false,
    this.disableTranslation = false,
    // These default scale values were eyeballed as reasonable limits for common
    // use cases.
    this.maxScale = 2.5,
    this.minScale = 0.8,
    this.onInteractionEnd,
    this.onInteractionStart,
    this.onInteractionUpdate,
    TransformationController transformationController,
  }) : assert(child != null),
       assert(minScale != null),
       assert(minScale > 0),
       assert(disableTranslation != null),
       assert(disableScale != null),
       assert(disableRotation != null),
       // TODO(justinmc): Remove this assertion when rotation is enabled.
       // https://github.com/flutter/flutter/issues/57698
       assert(disableRotation == true, 'Set disableRotation to true. This requirement will be removed later when the feature is complete.'),
       transformationController = transformationController ?? TransformationController(),
       super(key: key);

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
  /// Defaults to EdgeInsets.zero, which results in boundaries that are the
  /// exact same size and position as the constraints.
  final EdgeInsets boundaryMargin;

  /// The Widget to perform the transformations on.
  ///
  /// Cannot be null.
  final Widget child;

  /// If true, the user will be prevented from translating.
  ///
  /// Defaults to false.
  ///
  /// See also:
  ///   * [disableScale]
  ///   * [disableRotation]
  final bool disableTranslation;

  /// If true, the user will be prevented from scaling.
  ///
  /// Defaults to false.
  ///
  /// See also:
  ///   * [disableTranslation]
  ///   * [disableRotation]
  final bool disableScale;

  // TODO(justinmc): Update these docs when rotation is available.
  // https://github.com/flutter/flutter/issues/57698
  /// If true, the user will be prevented from rotating.
  ///
  /// Defaults to false.
  ///
  /// Currently, must be set to true, because rotation is not fully implemented.
  /// This requirement will be removed in the future when rotation becomes
  /// available.
  ///
  /// See also:
  ///   * [disableTranslation]
  ///   * [disableScale]
  final bool disableRotation;

  /// The maximum allowed scale.
  ///
  /// The scale will be clamped between this and [minScale].
  ///
  /// A maxScale of null has no bounds.
  ///
  /// Defaults to 2.5.
  final double maxScale;

  /// The minimum allowed scale.
  ///
  /// The scale will be clamped between this and [maxScale].
  ///
  /// A minScale of null has no bounds.
  ///
  /// Defaults to 0.8.
  final double minScale;

  /// Called when the user ends a pan or scale gesture on the widget.
  ///
  /// Will be called even if the interaction is disabled with
  /// [disableTranslation], [disableScale], or [disableRotation].
  ///
  /// Wrapping the InteractiveViewer in a [GestureDetector] can also be used to
  /// receive many gestures on the child, but [GestureDetector.onScaleStart],
  /// [GestureDetector.onScaleUpdate], and [GestureDetector.onScaleEnd] will not
  /// be called, so [onInteractionStart], [onInteractionUpdate], and [onInteractionEnd] should be used instead.
  ///
  /// The coordinates returned in the details are viewport coordinates relative
  /// to the parent. See [TransformationController.fromViewport] for how to
  /// convert the coordinates to scene coordinates relative to the child.
  ///
  /// See also:
  ///  * [onInteractionStart]
  ///  * [onInteractionEnd]
  final GestureScaleEndCallback onInteractionEnd;

  /// Called when the user begins a pan or scale gesture on the widget.
  ///
  /// Will be called even if the interaction is disabled with
  /// [disableTranslation], [disableScale], or [disableRotation].
  ///
  /// Wrapping the InteractiveViewer in a [GestureDetector] can also be used to
  /// receive many gestures on the child, but [GestureDetector.onScaleStart],
  /// [GestureDetector.onScaleUpdate], and [GestureDetector.onScaleEnd] will not
  /// be called, so [onInteractionStart], [onInteractionUpdate], and [onInteractionEnd] should be used instead.
  ///
  /// The coordinates returned in the details are viewport coordinates relative
  /// to the parent. See [TransformationController.fromViewport] for how to
  /// convert the coordinates to scene coordinates relative to the child.
  ///
  /// See also:
  ///  * [onInteractionUpdate]
  ///  * [onInteractionEnd]
  final GestureScaleStartCallback onInteractionStart;

  /// Called when the user updates a pan or scale gesture on the
  /// widget.
  ///
  /// Will be called even if the interaction is disabled with
  /// [disableTranslation], [disableScale], or [disableRotation].
  ///
  /// Wrapping the InteractiveViewer in a [GestureDetector] can also be used to
  /// receive many gestures on the child, but [GestureDetector.onScaleStart],
  /// [GestureDetector.onScaleUpdate], and [GestureDetector.onScaleEnd] will not
  /// be called, so [onInteractionStart], [onInteractionUpdate], and [onInteractionEnd] should be used instead.
  ///
  /// The coordinates returned in the details are viewport coordinates relative
  /// to the parent. See [TransformationController.fromViewport] for how to
  /// convert the coordinates to scene coordinates relative to the child.
  ///
  /// See also:
  ///  * [onInteractionStart]
  ///  * [onInteractionEnd]
  final GestureScaleUpdateCallback onInteractionUpdate;

  /// A [TransformationController] for the transformation performed on the
  /// child.
  ///
  /// Whenever the child is transformed, the [Matrix4] value is updated and all
  /// listeners are notified. The value can also be set.
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
  ///   setState(() {
  ///     _transformationController.value = _animationReset.value;
  ///   });
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
  ///   _controllerReset.duration = const Duration(milliseconds: 400);
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
  /// IconButton get resetButton {
  ///   return IconButton(
  ///     onPressed: () {
  ///       setState(() {
  ///         _animateResetInitialize();
  ///       });
  ///     },
  ///     tooltip: 'Reset',
  ///     color: Theme.of(context).colorScheme.surface,
  ///     icon: const Icon(Icons.replay),
  ///   );
  /// }
  ///
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   _controllerReset = AnimationController(
  ///     vsync: this,
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
  ///         disableRotation: true,
  ///         transformationController: _transformationController,
  ///         minScale: 0.1,
  ///         maxScale: 1.0,
  ///         onInteractionStart: _onInteractionStart,
  ///         child: Container(
  ///           color: Colors.pink,
  ///         ),
  ///       ),
  ///     ),
  ///     persistentFooterButtons: [resetButton],
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [ValueNotifier].
  ///  * [TextEditingController] for an example of another similar pattern.
  final TransformationController transformationController;

  @override _InteractiveViewerState createState() => _InteractiveViewerState();
}

class _InteractiveViewerState extends State<InteractiveViewer> with TickerProviderStateMixin {
  final GlobalKey _childKey = GlobalKey();
  Animation<Offset> _animation;
  AnimationController _controller;
  Offset _referenceFocalPoint; // Point where the current gesture began.
  double _scaleStart; // Scale value at start of scaling gesture.
  double _rotationStart = 0.0; // Rotation at start of rotation gesture.
  double _currentRotation = 0.0; // Rotation of widget.transformationController.value.
  BoxConstraints _constraints;
  _GestureType _gestureType;

  // This value was eyeballed as to give a feel similar to Google Photos.
  static const double _kDrag = 0.0000135;

  // The _boundaryRect is calculated by adding the boundaryMargin to the size of
  // the child.
  Rect _boundaryRectCached;
  Rect get _boundaryRect {
    if (_boundaryRectCached != null) {
      return _boundaryRectCached;
    }
    assert(_childKey.currentContext != null);
    assert(!widget.boundaryMargin.left.isNaN);
    assert(!widget.boundaryMargin.right.isNaN);
    assert(!widget.boundaryMargin.top.isNaN);
    assert(!widget.boundaryMargin.bottom.isNaN);

    final Size childSize = _getChildSize(
      _childKey.currentContext.findRenderObject() as RenderBox,
      _constraints,
    );
    _boundaryRectCached = Rect.fromLTRB(
      -widget.boundaryMargin.left,
      -widget.boundaryMargin.top,
      childSize.width + widget.boundaryMargin.right,
      childSize.height + widget.boundaryMargin.bottom,
    );
    // Boundaries that are partially infinite are not allowed because Matrix4's
    // rotation and translation methods don't handle infinites well.
    assert(_boundaryRectCached.isFinite ||
        (_boundaryRectCached.left.isInfinite
        && _boundaryRectCached.top.isInfinite
        && _boundaryRectCached.right.isInfinite
        && _boundaryRectCached.bottom.isInfinite));
    return _boundaryRectCached;
  }

  // The Rect representing the child's parent.
  Rect get _viewport {
    assert(_childKey.currentContext != null);
    final Size childSize = _getChildSize(
      _childKey.currentContext.findRenderObject() as RenderBox,
      _constraints,
    );
    final Size viewportSize = _constraints.constrain(childSize);
    return Rect.fromLTRB(
      0.0,
      0.0,
      viewportSize.width,
      viewportSize.height,
    );
  }

  // Return a new matrix representing the given matrix after applying the given
  // translation.
  Matrix4 _matrixTranslate(Matrix4 matrix, Offset translation) {
    if (widget.disableTranslation || translation == Offset.zero) {
      return matrix;
    }

    final Matrix4 nextMatrix = matrix.clone()..translate(
      translation.dx,
      translation.dy,
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
      return matrix;
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
    if (widget.disableScale || scale == 1) {
      return matrix;
    }
    assert(scale != 0.0);

    // Don't allow a scale that results in an overall scale beyond min/max
    // scale.
    final double currentScale = widget.transformationController.value.getMaxScaleOnAxis();
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
    if (widget.disableRotation || rotation == 0) {
      return matrix;
    }
    final Offset focalPointScene = widget.transformationController.fromViewport(
      focalPoint,
    );
    return matrix
      ..translate(focalPointScene.dx, focalPointScene.dy)
      ..rotateZ(-rotation)
      ..translate(-focalPointScene.dx, -focalPointScene.dy);
  }

  // Handle the start of a gesture of _GestureType. All of translation, scale,
  // and rotation are handled with GestureDetector's scale gesture.
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
    setState(() {
      _scaleStart = widget.transformationController.value.getMaxScaleOnAxis();
      _referenceFocalPoint = widget.transformationController.fromViewport(
        details.localFocalPoint,
      );
      _rotationStart = _currentRotation;
    });
  }

  // Handle an update to an ongoing gesture of _GestureType.
  void _onScaleUpdate(ScaleUpdateDetails details) {
    final double scale = widget.transformationController.value.getMaxScaleOnAxis();
    if (widget.onInteractionUpdate != null) {
      widget.onInteractionUpdate(ScaleUpdateDetails(
        focalPoint: widget.transformationController.fromViewport(
          details.localFocalPoint,
        ),
        scale: details.scale,
        rotation: details.rotation,
      ));
    }
    final Offset focalPointScene = widget.transformationController.fromViewport(
      details.localFocalPoint,
    );
    _gestureType ??= _getGestureType(
      widget.disableScale ? 1.0 : details.scale,
      widget.disableRotation ? 0.0 : details.rotation,
    );

    switch (_gestureType) {
      case _GestureType.scale:
        if (_scaleStart == null) {
          return;
        }
        // details.scale gives us the amount to change the scale as of the
        // start of this gesture, so calculate the amount to scale as of the
        // previous call to _onScaleUpdate.
        final double desiredScale = _scaleStart * details.scale;
        final double scaleChange = desiredScale / scale;
        setState(() {
          widget.transformationController.value = _matrixScale(
            widget.transformationController.value,
            scaleChange,
          );

          // While scaling, translate such that the user's two fingers stay on
          // the same places in the scene. That means that the focal point of
          // the scale should be on the same place in the scene before and after
          // the scale.
          final Offset focalPointSceneScaled = widget.transformationController.fromViewport(
            details.localFocalPoint,
          );
          widget.transformationController.value = _matrixTranslate(
            widget.transformationController.value,
            focalPointSceneScaled - _referenceFocalPoint,
          );

          // details.localFocalPoint should now be at the same location as the
          // original _referenceFocalPoint point. If it's not, that's because
          // the translate came in contact with a boundary. In that case, update
          // _referenceFocalPoint so subsequent updates happen in relation to
          // the new effective focal point.
          final Offset focalPointSceneCheck = widget.transformationController.fromViewport(
            details.localFocalPoint,
          );
          if (_round(_referenceFocalPoint) != _round(focalPointSceneCheck)) {
            _referenceFocalPoint = focalPointSceneCheck;
          }
        });
        return;

      case _GestureType.rotate:
        if (details.rotation == 0.0) {
          return;
        }
        final double desiredRotation = _rotationStart + details.rotation;
        setState(() {
          widget.transformationController.value = _matrixRotate(
            widget.transformationController.value,
            _currentRotation - desiredRotation,
            details.localFocalPoint,
          );
          _currentRotation = desiredRotation;
        });
        return;

      case _GestureType.translate:
        if (_referenceFocalPoint == null || details.scale != 1.0) {
          return;
        }
        // Translate so that the same point in the scene is underneath the
        // focal point before and after the movement.
        final Offset translationChange = focalPointScene - _referenceFocalPoint;
        setState(() {
          widget.transformationController.value = _matrixTranslate(
            widget.transformationController.value,
            translationChange,
          );
          _referenceFocalPoint = widget.transformationController.fromViewport(
            details.localFocalPoint,
          );
        });
        return;
    }
  }

  // Handle the end of a gesture of _GestureType.
  void _onScaleEnd(ScaleEndDetails details) {
    if (widget.onInteractionEnd != null) {
      widget.onInteractionEnd(details);
    }
    setState(() {
      _scaleStart = null;
      _rotationStart = null;
      _referenceFocalPoint = null;
    });

    _animation?.removeListener(_onAnimate);
    _controller.reset();

    // If the scale ended with enough velocity, animate inertial movement.
    if (details.velocity.pixelsPerSecond.distance < kMinFlingVelocity) {
      return;
    }

    final Vector3 translationVector = widget.transformationController.value.getTranslation();
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
    if (event is PointerScrollEvent) {
      final Size childSize = _getChildSize(
        _childKey.currentContext.findRenderObject() as RenderBox,
        _constraints,
      );
      final double scaleChange = 1.0 + event.scrollDelta.dy / childSize.height;
      if (scaleChange == 0.0) {
        return;
      }
      final Offset focalPointScene = widget.transformationController.fromViewport(
        event.localPosition,
      );
      setState(() {
        widget.transformationController.value = _matrixScale(
          widget.transformationController.value,
          scaleChange,
        );

        // After scaling, translate such that the event's position is at the
        // same scene point before and after the scale.
        final Offset focalPointSceneScaled = widget.transformationController.fromViewport(
          event.localPosition,
        );
        widget.transformationController.value = _matrixTranslate(
          widget.transformationController.value,
          focalPointSceneScaled - focalPointScene,
        );
      });
    }
  }

  // Handle inertia drag animation.
  void _onAnimate() {
    if (!_controller.isAnimating) {
      _animation?.removeListener(_onAnimate);
      _animation = null;
      _controller.reset();
      return;
    }
    // Translate such that the resulting translation is _animation.value.
    final Vector3 translationVector = widget.transformationController.value.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
    final Offset translationScene = widget.transformationController.fromViewport(
      translation,
    );
    final Offset animationScene = widget.transformationController.fromViewport(
      _animation.value,
    );
    final Offset translationChangeScene = animationScene - translationScene;
    setState(() {
      widget.transformationController.value = _matrixTranslate(
        widget.transformationController.value,
        translationChangeScene,
      );
    });
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(InteractiveViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child != oldWidget.child
      || widget.boundaryMargin != oldWidget.boundaryMargin) {
      _boundaryRectCached = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A GestureDetector allows the detection of panning and zooming gestures on
    // the child.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _constraints = constraints;
        return Listener(
          onPointerSignal: _receivedPointerSignal,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, // Necessary when translating off screen
            onScaleEnd: _onScaleEnd,
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,

            child: Transform(
              transform: widget.transformationController.value,
              child: KeyedSubtree(
                key: _childKey,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

// A classification of relevant user gestures. Each contiguous user gesture is
// represented by exactly one _GestureType.
enum _GestureType {
  translate,
  scale,
  rotate,
}

/// Returns the closest point to the given point on the given line segment.
@visibleForTesting
Vector3 getNearestPointOnLine(Vector3 point, Vector3 l1, Vector3 l2) {
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
Quad getAxisAlignedBoundingBox(Quad quad) {
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
bool pointIsInside(Vector3 point, Quad quad) {
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
Vector3 getNearestPointInside(Vector3 point, Quad quad) {
  // If the point is inside the axis aligned bounding box, then it's ok where
  // it is.
  if (pointIsInside(point, quad)) {
    return point;
  }

  // Otherwise, return the nearest point on the quad.
  final List<Vector3> closestPoints = <Vector3>[
    getNearestPointOnLine(point, quad.point0, quad.point1),
    getNearestPointOnLine(point, quad.point1, quad.point2),
    getNearestPointOnLine(point, quad.point2, quad.point3),
    getNearestPointOnLine(point, quad.point3, quad.point0),
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

// Given a velocity and drag, calculate the time at which motion will come to
// a stop, within the margin of effectivelyMotionless.
double _getFinalTime(double velocity, double drag) {
  const double effectivelyMotionless = 10.0;
  return math.log(effectivelyMotionless / velocity) / math.log(drag / 100);
}

// Decide which type of gesture this is by comparing the amount of scale
// and rotation in the gesture, if any. Scale starts at 1 and rotation
// starts at 0. Translate will have 0 scale and 0 rotation because it uses
// only one finger.
_GestureType _getGestureType(double scale, double rotation) {
  if ((scale - 1).abs() > rotation.abs()) {
    return _GestureType.scale;
  } else if (rotation != 0) {
    return _GestureType.rotate;
  } else {
    return _GestureType.translate;
  }
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

// Get the size of the child given its RenderBox and the viewport's Size.
//
// In some cases (i.e. a Table that's wider and/or taller than the device),
// renderBox.size will give the size of the device, even though the child is
// drawn beyond the viewport. The intrinsic size can then be used to set the
// boundary to the full size of the child.
//
// In other cases (i.e. an Image whose original size is larger than the
// viewport but is being fit to the viewport), renderBox.size will also give
// the size of the viewport, and the boundary should remain at the viewport. In
// that case, the intrinsic size is not used.
Size _getChildSize(RenderBox renderBox, BoxConstraints constraints) {
  double width = renderBox.size.width;
  double height = renderBox.size.height;
  final double minIntrinsicWidth = renderBox.getMinIntrinsicWidth(constraints.maxHeight);
  final double maxIntrinsicWidth = renderBox.getMaxIntrinsicWidth(constraints.maxHeight);
  final double minIntrinsicHeight = renderBox.getMinIntrinsicHeight(constraints.maxWidth);
  final double maxIntrinsicHeight = renderBox.getMaxIntrinsicHeight(constraints.maxWidth);

  if (minIntrinsicWidth == maxIntrinsicWidth) {
    width = minIntrinsicWidth;
  }
  if (minIntrinsicHeight == maxIntrinsicHeight) {
    height = minIntrinsicHeight;
  }

  return Size(width, height);
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
  return getAxisAlignedBoundingBox(boundariesRotated);
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
    final Vector3 pointInside = getNearestPointInside(point, boundary);
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
