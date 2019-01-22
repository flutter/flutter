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
    // TODO(justinmc): get this internally?
    @required this.screenSize,
    // A callback for the onTapUp event from GestureDetector. Called with
    // untransformed coordinates in an Offset.
    this.onTapUp,
    // The scale will be clamped to between these values
    this.maxScale = 2.5,
    this.minScale = 0.8,
    // Panning will be limited so that the screen can not view beyond this size.
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
  final Size screenSize;
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
  Offset _translateFrom; // Point where a single translation began
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
    // Clamp _translation such that viewport can't see beyond widget.visibleSize
    final Size screenSizeScene = widget.screenSize / _scale;
    __translation = Offset(
      offset.dx.clamp(
        -widget.visibleSize.width / 2 + screenSizeScene.width / 2,
        widget.visibleSize.width / 2 - screenSizeScene.width / 2,
      ),
      offset.dy.clamp(
        -widget.visibleSize.height / 2 + screenSizeScene.height / 2,
        widget.visibleSize.height / 2 - screenSizeScene.height / 2,
      ),
    );
  }

  double get _scale => __scale;
  set _scale(double scale) {
    if (widget.disableScale) {
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
      _translation.dx + widget.screenSize.width / 2 / _scale,
      _translation.dy + widget.screenSize.height / 2 / _scale,
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
        // The scene is actually panned and zoomed using this Transform widget.
        child: Transform(
          transform: TransformInteractionState.getTransformationMatrix(translationCentered, _scale, _rotation),
          child: widget.child,
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
  static Offset fromScreen(Offset screenPoint, Offset translation, double scale, double rotation, Size screenSize, [Offset focalPoint = Offset.zero]) {
    // Find the offset from the center of the screen to the given screenPoint.
    final Offset fromCenterOfScreen = Offset(
      screenPoint.dx - screenSize.width / 2,
      screenPoint.dy - screenSize.height / 2,
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
      fromCenterOfScreen.dx,
      fromCenterOfScreen.dy,
      0,
    ));
    return Offset(untransformed.x, untransformed.y);
  }

  // Handle panning and pinch zooming events
  void _onScaleStart(ScaleStartDetails details) {
    _controller.stop();
    setState(() {
      _scaleStart = _scale;
      _translateFrom = details.focalPoint;
      _rotationStart = _rotation;
    });
  }
  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (_scaleStart != null) {
        final Offset focalPointScene = fromScreen(details.focalPoint, _translation, _scale, _rotation, widget.screenSize);
        _scale = _scaleStart * details.scale;

        if (details.scale != 1.0) {
          // While scaling, translate such that the user's fingers stay on the
          // same place in the scene. That means that the focal point of the
          // scale should be on the same place in the scene before and after the
          // scale.
          final Offset focalPointSceneNext = fromScreen(details.focalPoint, _translation, _scale, _rotation, widget.screenSize);
          _translation = _translation + focalPointSceneNext - focalPointScene;
        }
      }
      if (_translateFrom != null && details.scale == 1.0) {
        // The coordinates given by details.focalPoint are screen coordinates
        // that are not affected by _scale. So, dividing by scale here properly
        // gives us more distance when zoomed out and less when zoomed in so
        // that the point under the user's finger stays constant during a drag.
        _translation = _translation + (details.focalPoint - _translateFrom) / _scale;
        _translateFrom = details.focalPoint;
      }
      if (_rotationStart != null && details.rotation != 0.0) {
        _rotation = _rotationStart - details.rotation;
      }
    });
  }
  void _onScaleEnd(ScaleEndDetails details) {
    setState(() {
      _scaleStart = null;
      _rotationStart = null;
      _translateFrom = null;
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
    widget.onTapUp(fromScreen(details.globalPosition, _translation, _scale, _rotation, widget.screenSize));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
