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
    // Panning will be limited so that the viewport can not view beyond this
    // size.
    // TODO(justinmc): also limit scaling! If I set minScale to 0.2 I can see beyond
    this.visibleSize = const Size(1600, 2400),
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
  final Size visibleSize;
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
  Offset __translation = const Offset(0, 0);
  Offset _translateFromScene; // Point where a single translation began
  double _scaleStart; // Scale value at start of scaling gesture
  double __scale = 1.0;
  double _rotationStart;
  // TODO(justinmc): rotation should be centered at the gesture's focal point.
  // But that's hard. I can do rotation around an arbitrary center using
  // matrices, but when I try to do a second rotation about a different center,
  // it doesn't work (short of keeping track of all rotation points and angles).
  // Another idea is to convert rotation about a center into a regular rotation
  // and translation. However, that would mean that my _translation would be
  // constantly changing during a rotation, and it won't quite mean what it
  // currently does anymore.
  double __rotation = 0.0;

  Offset get _translation => __translation;
  set _translation(Offset offset) {
    if (widget.disableTranslation) {
      return;
    }
    final Size sizeScene = widget.size / _scale;
    __translation = Offset(
      offset.dx.clamp(
        -widget.visibleSize.width / 2 + sizeScene.width / 2,
        widget.visibleSize.width / 2 - sizeScene.width / 2,
      ),
      offset.dy.clamp(
        -widget.visibleSize.height / 2 + sizeScene.height / 2,
        widget.visibleSize.height / 2 - sizeScene.height / 2,
      ),
    );
  }

  double get _scale => __scale;
  set _scale(double scale) {
    if (widget.disableScale) {
      return;
    }

    // Don't allow a scale that moves the viewport outside of visibleSize
    final Offset tl = fromViewport(
      Offset(0, 0),
      _translation,
      _scale,
      0.0,
      widget.size,
    );
    final Offset tr = fromViewport(
      Offset(widget.size.width, 0),
      _translation,
      _scale,
      0.0,
      widget.size,
    );
    final Offset bl = fromViewport(
      Offset(0, widget.size.height),
      _translation,
      _scale,
      0.0,
      widget.size,
    );
    final Offset br = fromViewport(
      Offset(widget.size.width, widget.size.height),
      _translation,
      _scale,
      0.0,
      widget.size,
    );
    if (!isInside(tl, widget.visibleSize)
      || !isInside(tr, widget.visibleSize)
      || !isInside(bl, widget.visibleSize)
      || !isInside(br, widget.visibleSize)) {
      return;
    }

    __scale = scale.clamp(widget.minScale, widget.maxScale);
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
    if (widget.initialTranslation != null) {
      _translation = widget.initialTranslation;
    }
    if (widget.initialScale != null) {
      _scale = widget.initialScale;
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
    // By default, the scene is drawn so that the origin is in the top left
    // corner of the viewport. Center it instead.
    final Offset translationCentered = Offset(
      _translation.dx + widget.size.width / 2 / _scale,
      _translation.dy + widget.size.height / 2 / _scale,
    );

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
          transform: TransformInteractionState.getTransformationMatrix(translationCentered, _scale, _rotation),
          child: Container(
            child: widget.child,
            height: widget.size.height,
            width: widget.size.width,
          ),
        ),
      ),
    );
  }

  // Returns true iff viewportPoint is inside sceneSize in scene coords.
  static bool isInside(Offset offset, Size size) {
    return offset.dx >= -size.width / 2
      && offset.dx <= size.width / 2
      && offset.dy >= -size.height / 2
      && offset.dy <= size.height / 2;
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
  static Offset fromViewport(Offset viewportPoint, Offset translation, double scale, double rotation, Size size, [Offset focalPoint = Offset.zero]) {
    // Find the offset from the center of the viewport to the given viewportPoint.
    final Offset fromCenterOfViewport = Offset(
      viewportPoint.dx - size.width / 2,
      viewportPoint.dy - size.height / 2,
    );

    // On this point, perform the inverse transformation of the scene to get
    // where the point would be before the transformation.
    final Matrix4 matrix = TransformInteractionState.getTransformationMatrix(
      translation,
      scale,
      rotation,
      focalPoint,
    );
    final Matrix4 inverseMatrix = Matrix4.inverted(matrix);
    final Vector3 untransformed = inverseMatrix.transform3(Vector3(
      fromCenterOfViewport.dx,
      fromCenterOfViewport.dy,
      0,
    ));
    return Offset(untransformed.x, untransformed.y);
  }

  // Handle panning and pinch zooming events
  void _onScaleStart(ScaleStartDetails details) {
    _controller.stop();
    setState(() {
      _scaleStart = _scale;
      _translateFromScene = fromViewport(
        details.focalPoint,
        _translation,
        _scale,
        0.0,
        widget.size,
      );
      _rotationStart = _rotation;
    });
  }
  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      final Offset focalPointScene = fromViewport(
        details.focalPoint,
        _translation,
        _scale,
        0.0, // rotation is 0 because translation happens before rotation
        widget.size,
      );
      if (_rotationStart != null && details.rotation != 0.0) {
        _rotation = _rotationStart - details.rotation;
      }
      if (_scaleStart != null) {
        _scale = _scaleStart * details.scale;

        if (details.scale != 1.0) {
          // While scaling, translate such that the user's fingers stay on the
          // same place in the scene. That means that the focal point of the
          // scale should be on the same place in the scene before and after the
          // scale.
          final Offset focalPointSceneNext = fromViewport(
            details.focalPoint,
            _translation,
            _scale,
            0.0,
            widget.size,
          );
          _translation = _translation + focalPointSceneNext - focalPointScene;
        }
      }
      if (_translateFromScene != null && details.scale == 1.0) {
        // Translate so that the same point in the scene is underneath the
        // focal point before and after the movement.
        _translation = _translation + (focalPointScene - _translateFromScene);
        _translateFromScene = fromViewport(
          details.focalPoint,
          _translation,
          _scale,
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

    final InertialMotion inertialMotion = InertialMotion(details.velocity, _translation);
    _animation = Tween<Offset>(begin: _translation, end: inertialMotion.finalPosition).animate(_controller);
    _controller.duration = Duration(milliseconds: inertialMotion.duration.toInt());
    _animation.addListener(_onAnimate);
    _controller.fling();
  }

  // Handle inertia drag animation
  void _onAnimate() {
    setState(() {
      _translation = _animation.value;
    });
  }

  // Handle tapping to select a tile
  void _onTapUp(TapUpDetails details) {
    widget.onTapUp(fromViewport(details.globalPosition, _translation, _scale, _rotation, widget.size));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
