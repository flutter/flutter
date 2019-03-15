import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'pan_and_zoom_demo_inertial_motion.dart';

// This widget allows 2D transform interaction on its child. The user can drag
// to pan, pinch to zoom and rotate, and still get back untransformed
// coordinates for targeted tap events.
@immutable
class TransformInteraction extends StatefulWidget {
  const TransformInteraction({
    // The child to perform the transformations on
    @required this.child,
    // The desired size of the area that can receive events
    @required this.size,
    // The scale will be clamped to between these values
    this.maxScale = 2.5,
    this.minScale = 0.8,
    // Transforms will be limited so that the viewport can not view beyond this
    // Rect.
    this.visibleRect,
    // Initial values for the transform can be provided
    this.initialTranslation,
    this.initialScale,
    this.initialRotation,
    // Any and all of the possible transformations can be disabled.
    this.disableTranslation = false,
    this.disableScale = false,
    this.disableRotation = false,
    // Access to event callbacks from GestureDetector. Called with untransformed
    // coordinates in an Offset.
    this.onTapDown,
    this.onTapUp,
    this.onTap,
    this.onTapCancel,
    this.onDoubleTap,
    this.onLongPress,
    this.onLongPressUp,
    this.onVerticalDragDown,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onVerticalDragCancel,
    this.onHorizontalDragDown,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onHorizontalDragCancel,
    this.onPanDown,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
  });

  final Widget child;
  final Size size;
  final Function onTapDown;
  final Function onTapUp;
  final Function onTap;
  final Function onTapCancel;
  final Function onDoubleTap;
  final Function onLongPress;
  final Function onLongPressUp;
  final Function onVerticalDragDown;
  final Function onVerticalDragStart;
  final Function onVerticalDragUpdate;
  final Function onVerticalDragEnd;
  final Function onVerticalDragCancel;
  final Function onHorizontalDragDown;
  final Function onHorizontalDragStart;
  final Function onHorizontalDragUpdate;
  final Function onHorizontalDragEnd;
  final Function onHorizontalDragCancel;
  final Function onPanDown;
  final Function onPanStart;
  final Function onPanUpdate;
  final Function onPanEnd;
  final Function onPanCancel;
  final Function onScaleStart;
  final Function onScaleUpdate;
  final Function onScaleEnd;
  final double maxScale;
  final double minScale;
  final Rect visibleRect;
  final bool disableTranslation;
  final bool disableScale;
  final bool disableRotation;
  final Offset initialTranslation;
  final double initialScale;
  final double initialRotation;

  @override TransformInteractionState createState() => TransformInteractionState();
}

enum GestureType {
  translate,
  scale,
  rotate,
}

class TransformInteractionState extends State<TransformInteraction> with SingleTickerProviderStateMixin {
  Animation<Offset> _animation;
  AnimationController _controller;
  // The translation that will be applied to the scene (not viewport).
  // A positive x offset moves the scene right, viewport left.
  // A positive y offset moves the scene down, viewport up.
  Offset _translateFromScene; // Point where a single translation began
  double _scaleStart; // Scale value at start of scaling gesture
  double _rotationStart = 0.0;
  Rect _visibleRect;
  Matrix4 _transform = Matrix4.identity();
  GestureType gestureType;

  // Perform a translation on the given matrix within constraints of the scene.
  // The _visibleRect is not rotated with the scene.
  Matrix4 matrixTranslate(Matrix4 matrix, Offset translation) {
    if (widget.disableTranslation) {
      return matrix;
    }
    final double scale = _transform.getMaxScaleOnAxis();
    final Size scaledSize = widget.size / scale;
    final Vector3 currentTranslation = matrix.getTranslation() / scale;
    final Rect boundaries = Rect.fromLTRB(
      _visibleRect.left * -1,
      _visibleRect.top * -1,
      (_visibleRect.right - scaledSize.width) * -1,
      (_visibleRect.bottom - scaledSize.height) * -1,
    );
    final Offset clampedTranslation = Offset(
      translation.dx.clamp(
        boundaries.right - currentTranslation.x,
        boundaries.left - currentTranslation.x,
      ),
      translation.dy.clamp(
        boundaries.bottom - currentTranslation.y,
        boundaries.top - currentTranslation.y,
      ),
    );
    return matrix..translate(
      clampedTranslation.dx,
      clampedTranslation.dy,
    );
  }

  Matrix4 matrixScale(Matrix4 matrix, double scale) {
    if (widget.disableScale) {
      return matrix;
    }

    // Don't allow a scale that moves the viewport outside of _visibleRect
    final Offset tl = fromViewport(const Offset(0, 0), _transform);
    final Offset tr = fromViewport(Offset(widget.size.width, 0), _transform);
    final Offset bl = fromViewport(Offset(0, widget.size.height), _transform);
    final Offset br = fromViewport(
      Offset(widget.size.width, widget.size.height),
      _transform,
    );
    if (!_visibleRect.contains(tl)
      || !_visibleRect.contains(tr)
      || !_visibleRect.contains(bl)
      || !_visibleRect.contains(br)) {
      return matrix;
    }

    // Don't allow a scale that results in an overall scale beyond min/max scale
    final double currentScale = _transform.getMaxScaleOnAxis();
    final double totalScale = currentScale * scale;
    final double clampedTotalScale = totalScale.clamp(
      widget.minScale,
      widget.maxScale,
    );
    final double clampedScale = clampedTotalScale / currentScale;
    return matrix..scale(clampedScale);
  }

  Matrix4 matrixRotate(Matrix4 matrix, double rotation, Offset focalPoint) {
    if (widget.disableRotation) {
      return matrix;
    }
    final Offset focalPointScene = fromViewport(focalPoint, matrix);
    return matrix
      ..translate(focalPointScene.dx, focalPointScene.dy)
      ..rotateZ(-rotation)
      ..translate(-focalPointScene.dx, -focalPointScene.dy);
  }

  @override
  void initState() {
    super.initState();
    _visibleRect = widget.visibleRect != null
      ? widget.visibleRect
      : Rect.fromLTWH(0, 0, widget.size.width, widget.size.height);
    if (widget.initialTranslation != null) {
      _transform = matrixTranslate(_transform, widget.initialTranslation);
    }
    if (widget.initialScale != null) {
      _transform = matrixScale(_transform, widget.initialScale);
    }
    if (widget.initialRotation != null) {
      _transform = matrixRotate(_transform, widget.initialRotation, Offset.zero);
    }
    _controller = AnimationController(
      vsync: this,
    );
  }

  @override
  Widget build (BuildContext context) {
    // A GestureDetector allows the detection of panning and zooming gestures on
    // its child, which is the CustomPaint.
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Necessary when translating off screen
      onTapDown: widget.onTapDown == null ? null : (TapDownDetails details) => widget.onTapDown(fromViewport(details.globalPosition, _transform)),
      onTapUp: widget.onTapUp == null ? null : (TapUpDetails details) => widget.onTapUp(fromViewport(details.globalPosition, _transform)),
      onTap: widget.onTap,
      onTapCancel: widget.onTapCancel,
      onDoubleTap: widget.onDoubleTap,
      onLongPress: widget.onLongPress,
      onLongPressUp: widget.onLongPressUp,
      onVerticalDragDown: widget.onVerticalDragDown == null ? null : (DragDownDetails details) => widget.onVerticalDragDown(fromViewport(details.globalPosition, _transform)),
      onVerticalDragStart: widget.onVerticalDragStart == null ? null : (DragStartDetails details) => widget.onVerticalDragStart(fromViewport(details.globalPosition, _transform)),
      onVerticalDragUpdate: widget.onVerticalDragUpdate == null ? null : (DragUpdateDetails details) => widget.onVerticalDragUpdate(fromViewport(details.globalPosition, _transform)),
      onVerticalDragEnd: widget.onVerticalDragEnd == null ? null : (DragEndDetails details) => widget.onVerticalDragEnd(),
      onVerticalDragCancel: widget.onVerticalDragCancel,
      onHorizontalDragDown: widget.onHorizontalDragDown == null ? null : (DragDownDetails details) => widget.onHorizontalDragDown(fromViewport(details.globalPosition, _transform)),
      onHorizontalDragStart: widget.onHorizontalDragStart == null ? null : (DragStartDetails details) => widget.onHorizontalDragStart(fromViewport(details.globalPosition, _transform)),
      onHorizontalDragUpdate: widget.onHorizontalDragUpdate == null ? null : (DragUpdateDetails details) => widget.onHorizontalDragUpdate(fromViewport(details.globalPosition, _transform)),
      onHorizontalDragEnd: widget.onHorizontalDragEnd,
      onHorizontalDragCancel: widget.onHorizontalDragCancel,
      onPanDown: widget.onPanDown == null ? null : (DragDownDetails details) => widget.onPanDown(fromViewport(details.globalPosition, _transform)),
      onPanStart: widget.onPanStart == null ? null : (DragStartDetails details) => widget.onPanStart(fromViewport(details.globalPosition, _transform)),
      onPanUpdate: widget.onPanUpdate == null ? null : (DragUpdateDetails details) => widget.onPanUpdate(fromViewport(details.globalPosition, _transform)),
      onPanEnd: widget.onPanEnd == null ? null : (DragEndDetails details) => widget.onPanEnd(),
      onPanCancel: widget.onPanCancel,
      onScaleEnd: _onScaleEnd,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      child: ClipRect(
        // The scene is panned/zoomed/rotated using this Transform widget.
        child: Transform(
          transform: _transform,
          child: Container(
            child: widget.child,
            height: widget.size.height,
            width: widget.size.width,
          ),
        ),
      ),
    );
  }

  // Return the scene point underneath the viewport point given.
  static Offset fromViewport(Offset viewportPoint, Matrix4 transform) {
    // On viewportPoint, perform the inverse transformation of the scene to get
    // where the point would be in the scene before the transformation.
    final Matrix4 inverseMatrix = Matrix4.inverted(transform);
    final Vector3 untransformed = inverseMatrix.transform3(Vector3(
      viewportPoint.dx,
      viewportPoint.dy,
      0,
    ));
    return Offset(untransformed.x, untransformed.y);
  }

  // Handle panning and pinch zooming events
  double _currentRotation = 0.0;
  void _onScaleStart(ScaleStartDetails details) {
    widget.onScaleStart?.call();
    _controller.stop();
    gestureType = null;
    setState(() {
      _scaleStart = _transform.getMaxScaleOnAxis();
      _translateFromScene = fromViewport(details.focalPoint, _transform);
      _rotationStart = _currentRotation;
    });
  }
  void _onScaleUpdate(ScaleUpdateDetails details) {
    widget.onScaleUpdate?.call(fromViewport(details.focalPoint, _transform));
    double scale = _transform.getMaxScaleOnAxis();
    final Offset focalPointScene = fromViewport(
      details.focalPoint,
      _transform,
    );
    if (gestureType == null) {
      if ((details.scale - 1).abs() > details.rotation.abs()) {
        gestureType = GestureType.scale;
      } else if (details.rotation != 0) {
        gestureType = GestureType.rotate;
      } else {
        gestureType = GestureType.translate;
      }
    }
    setState(() {
      if (gestureType == GestureType.scale && _scaleStart != null) {
        // details.scale gives us the amount to change the scale as of the
        // start of this gesture, so calculate the amount to scale as of the
        // previous call to _onScaleUpdate.
        final double desiredScale = _scaleStart * details.scale;
        final double scaleChange = desiredScale / scale;
        _transform = matrixScale(_transform, scaleChange);
        scale = _transform.getMaxScaleOnAxis();

        // While scaling, translate such that the user's two fingers stay on the
        // same places in the scene. That means that the focal point of the
        // scale should be on the same place in the scene before and after the
        // scale.
        final Offset focalPointSceneNext = fromViewport(
          details.focalPoint,
          _transform,
        );
        _transform = matrixTranslate(_transform, focalPointSceneNext - focalPointScene);
      } else if (gestureType == GestureType.rotate && details.rotation != 0.0) {
        final double desiredRotation = _rotationStart + details.rotation;
        _transform = matrixRotate(_transform, _currentRotation - desiredRotation, details.focalPoint);
        _currentRotation = desiredRotation;
      } else if (_translateFromScene != null && details.scale == 1.0) {
        // Translate so that the same point in the scene is underneath the
        // focal point before and after the movement.
        final Offset translationChange = focalPointScene - _translateFromScene;
        _transform = matrixTranslate(_transform, translationChange);
        _translateFromScene = fromViewport(details.focalPoint, _transform);
      }
    });
  }
  void _onScaleEnd(ScaleEndDetails details) {
    widget.onScaleStart?.call();
    setState(() {
      _scaleStart = null;
      _rotationStart = null;
      _translateFromScene = null;
    });

    _animation?.removeListener(_onAnimate);
    _controller.reset();

    // If the scale ended with velocity, animate inertial movement
    final double velocityTotal = details.velocity.pixelsPerSecond.dx.abs()
      + details.velocity.pixelsPerSecond.dy.abs();
    if (velocityTotal == 0) {
      return;
    }

    final Vector3 translationVector = _transform.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
    final InertialMotion inertialMotion = InertialMotion(details.velocity, translation);
    _animation = Tween<Offset>(
      begin: translation,
      end: inertialMotion.finalPosition,
    ).animate(_controller);
    _controller.duration = Duration(milliseconds: inertialMotion.duration.toInt());
    _animation.addListener(_onAnimate);
    _controller.fling();
  }

  // Handle inertia drag animation
  void _onAnimate() {
    setState(() {
      // Translate _transform such that the resulting translation is
      // _animation.value.
      final Vector3 translationVector = _transform.getTranslation();
      final Offset translation = Offset(translationVector.x, translationVector.y);
      final Offset translationScene = fromViewport(translation, _transform);
      final Offset animationScene = fromViewport(_animation.value, _transform);
      final Offset translationChangeScene = animationScene - translationScene;
      _transform = matrixTranslate(_transform, translationChangeScene);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
