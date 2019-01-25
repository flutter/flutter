import 'dart:math' as math;
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
    // A callback for the onTapUp event from GestureDetector. Called with
    // untransformed coordinates in an Offset.
    this.onTapUp,
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
    // TODO(justinmc): add other GestureDetector callbacks
  });

  final Widget child;
  final Size size;
  final Function onTapUp;
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

class TransformInteractionState extends State<TransformInteraction> with SingleTickerProviderStateMixin {
  Animation<Offset> _animation;
  AnimationController _controller;
  // The translation that will be applied to the scene (not viewport).
  // A positive x offset moves the scene right, viewport left.
  // A positive y offset moves the scene down, viewport up.
  // Start out looking at the center.
  Offset _translateFromScene; // Point where a single translation began
  double _scaleStart; // Scale value at start of scaling gesture
  double _rotationStart;
  // TODO(justinmc): rotation should be centered at the gesture's focal point.
  // But that's hard. I can do rotation around an arbitrary center using
  // matrices, but when I try to do a second rotation about a different center,
  // it doesn't work (short of keeping track of all rotation points and angles).
  // Another idea is to convert rotation about a center into a regular rotation
  // and translation. However, that would mean that my _translation would be
  // constantly changing during a rotation, and it won't quite mean what it
  // currently does anymore.
  // Idea: instead of keeping track of individual translation, scale, and
  // rotation, save the current transformation matrix. Then you can apply any
  // subsequent transformation on top of that without caring about how you got
  // there.
  double __rotation = 0.0;
  Rect _visibleRect;
  Matrix4 _transform = Matrix4.identity();

  // Perform a translation on the given matrix within constraints of the scene.
  Matrix4 matrixTranslate(Matrix4 matrix, Offset translation) {
    if (widget.disableTranslation) {
      return matrix;
    }
    final double scale = _transform.getMaxScaleOnAxis();
    final Size scaledSize = widget.size / scale;
    final Offset clampedTranslation = Offset(
      translation.dx.clamp(
        scaledSize.width - _visibleRect.right,
        -_visibleRect.left,
      ),
      translation.dy.clamp(
         scaledSize.height - _visibleRect.bottom,
        -_visibleRect.top,
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
    // TODO this might mess you up because transform includes rotation, but we
    // were previously setting rotation to 0.0
    final Vector3 translationVector = _transform.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
    final Offset tl = fromViewport(
      const Offset(0, 0),
      _transform,
      translation,
      scale,
      0.0,
      widget.size,
    );
    final Offset tr = fromViewport(
      Offset(widget.size.width, 0),
      _transform,
      translation,
      scale,
      0.0,
      widget.size,
    );
    final Offset bl = fromViewport(
      Offset(0, widget.size.height),
      _transform,
      translation,
      scale,
      0.0,
      widget.size,
    );
    final Offset br = fromViewport(
      Offset(widget.size.width, widget.size.height),
      _transform,
      translation,
      scale,
      0.0,
      widget.size,
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

  double get _rotation => __rotation;
  set _rotation(double rotation) {
    if (widget.disableRotation) {
      return;
    }
    __rotation = rotation;
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
      _rotation = widget.initialRotation;
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
      onScaleEnd: _onScaleEnd,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onTapUp: _onTapUp,
      child: ClipRect(
        // The scene is panned/zoomed/rotated using this Transform widget.
        child: Transform(
          transform: _transform,
            /*
          transform: TransformInteractionState.getTransformationMatrix(
            _translation,
            _scale,
            _rotation,
          ),
          */
          child: Container(
            child: widget.child,
            height: widget.size.height,
            width: widget.size.width,
          ),
        ),
      ),
    );
  }

  // Get a matrix that will transform the origin of the scene with the given
  // translation, scale, and rotation so that it ends up centered under the
  // viewport.
  static Matrix4 getTransformationMatrix(Offset translation, double scale, double rotation, [Offset focalPoint = Offset.zero]) {
    final Matrix4 scaleMatrix = Matrix4.identity()..scale(scale);
    final Matrix4 translationMatrix = Matrix4.identity()
      ..translate(translation.dx, translation.dy);
    final Matrix4 rotationMatrix = Matrix4.identity()
      ..translate(focalPoint.dx, focalPoint.dy)
      ..rotateZ(-rotation)
      ..translate(-focalPoint.dx, -focalPoint.dy);
    return scaleMatrix * translationMatrix * rotationMatrix;
  }

  // Return the scene point underneath the viewport point given.
  static Offset fromViewport(Offset viewportPoint, Matrix4 transform, Offset translation, double scale, double rotation, Size size, [Offset focalPoint = Offset.zero]) {
    // On viewportPoint, perform the inverse transformation of the scene to get
    // where the point would be in the scene before the transformation.
    /*
    final Matrix4 matrix = TransformInteractionState.getTransformationMatrix(
      translation,
      scale,
      rotation,
      focalPoint,
    );
    */
    final Matrix4 matrix = transform;
    final Matrix4 inverseMatrix = Matrix4.inverted(matrix);
    final Vector3 untransformed = inverseMatrix.transform3(Vector3(
      viewportPoint.dx,
      viewportPoint.dy,
      0,
    ));
    return Offset(untransformed.x, untransformed.y);
  }

  // Handle panning and pinch zooming events
  void _onScaleStart(ScaleStartDetails details) {
    _controller.stop();
    final Vector3 translationVector = _transform.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
    setState(() {
      _scaleStart = _transform.getMaxScaleOnAxis();
      _translateFromScene = fromViewport(
        details.focalPoint,
        _transform,
        translation,
        _scaleStart,
        0.0,
        widget.size,
      );
      _rotationStart = _rotation;
    });
  }
  void _onScaleUpdate(ScaleUpdateDetails details) {
    final Vector3 translationVector = _transform.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
    setState(() {
      double scale = _transform.getMaxScaleOnAxis();
      final Offset focalPointScene = fromViewport(
        details.focalPoint,
        _transform,
        translation,
        scale,
        0.0, // rotation is 0 because translation happens before rotation
        widget.size,
      );
      if (_rotationStart != null && details.rotation != 0.0) {
        _rotation = _rotationStart - details.rotation;
      }
      if (_scaleStart != null) {
        if (details.scale != 1.0) {
          // details.scale gives us the amount to change the scale as of the
          // start of this gesture, so calculate the amount to scale as of the
          // previous call to _onScaleUpdate.
          final double desiredScale = _scaleStart * details.scale;
          final double scaleChange = desiredScale / scale;
          _transform = matrixScale(_transform, scaleChange);
          scale = _transform.getMaxScaleOnAxis();

          // While scaling, translate such that the user's fingers stay on the
          // same place in the scene. That means that the focal point of the
          // scale should be on the same place in the scene before and after the
          // scale.
          final Offset focalPointSceneNext = fromViewport(
            details.focalPoint,
            _transform,
            translation,
            scale,
            0.0,
            widget.size,
          );
          _transform = matrixTranslate(_transform, focalPointSceneNext - focalPointScene);
        }
      }
      if (_translateFromScene != null && details.scale == 1.0) {
        // Translate so that the same point in the scene is underneath the
        // focal point before and after the movement.
        final Offset translationChange = focalPointScene - _translateFromScene;
        _transform = matrixTranslate(_transform, translationChange);
        final Vector3 translationVectorNext = _transform.getTranslation();
        final Offset translationNext = Offset(translationVectorNext.x, translationVectorNext.y);
        _translateFromScene = fromViewport(
          details.focalPoint,
          _transform,
          translationNext,
          scale,
          0.0,
          widget.size,
        );
      }
    });
  }
  void _onScaleEnd(ScaleEndDetails details) {
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

    Vector3 translationVector = _transform.getTranslation();
    Offset translation = Offset(translationVector.x, translationVector.y);
    final InertialMotion inertialMotion = InertialMotion(details.velocity, translation);
    _animation = Tween<Offset>(begin: translation, end: inertialMotion.finalPosition).animate(_controller);
    _controller.duration = Duration(milliseconds: inertialMotion.duration.toInt());
    _animation.addListener(_onAnimate);
    _controller.fling();
  }

  // Handle inertia drag animation
  void _onAnimate() {
    setState(() {
      // TODO can I get the change without doing this subtraction?
      final Vector3 translationVector = _transform.getTranslation();
      final Offset translation = Offset(translationVector.x, translationVector.y);
      _transform = matrixTranslate(_transform, _animation.value - translation);
    });
  }

  // Handle tapping to select a tile
  void _onTapUp(TapUpDetails details) {
    double scale = _transform.getMaxScaleOnAxis();
    Vector3 translationVector = _transform.getTranslation();
    Offset translation = Offset(translationVector.x, translationVector.y);
    widget.onTapUp(fromViewport(
      details.globalPosition,
      _transform,
      translation,
      scale,
      _rotation,
      widget.size,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
