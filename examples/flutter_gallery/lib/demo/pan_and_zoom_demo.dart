import 'dart:ui' show Vertices;
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:flutter/material.dart';
import 'pan_and_zoom_demo_board.dart';
import 'pan_and_zoom_demo_inertial_motion.dart';

class PanAndZoomDemo extends StatefulWidget {
  const PanAndZoomDemo({Key key}) : super(key: key);

  static const String routeName = '/pan_and_zoom';

  @override _PanAndZoomDemoState createState() => _PanAndZoomDemoState();
}
class _PanAndZoomDemoState extends State<PanAndZoomDemo> {
  static const double HEXAGON_RADIUS = 32.0;
  static const double HEXAGON_MARGIN = 1.0;
  static const int BOARD_RADIUS = 8;

  Board _board = Board(
    boardRadius: BOARD_RADIUS,
    hexagonRadius: HEXAGON_RADIUS,
    hexagonMargin: HEXAGON_MARGIN,
  );

  @override
  Widget build (BuildContext context) {
    final BoardPainter painter = BoardPainter(
      board: _board,
    );
    final Size screenSize = MediaQuery.of(context).size;

    // The scene is drawn by a CustomPaint, but user interaction is handled by
    // the BoardInteraction parent widget.
    return Scaffold(
      body: BoardInteraction(
        child: CustomPaint(
          size: Size.infinite,
          painter: painter,
        ),
        onTapUp: _onTapUp,
        screenSize: screenSize,
      ),
    );
  }

  void _onTapUp(Offset scenePoint) {
    final BoardPoint boardPoint = _board.pointToBoardPoint(scenePoint);
    setState(() {
      _board = _board.selectBoardPoint(boardPoint);
    });
  }
}

// This widget handles all user interaction on the CustomPaint
class BoardInteraction extends StatefulWidget {
  const BoardInteraction({
    @required this.child,
    @required this.screenSize,
    @required this.onTapUp,
  });

  final Widget child;
  final Size screenSize;
  final Function onTapUp;

  @override BoardInteractionState createState() => BoardInteractionState();
}
class BoardInteractionState extends State<BoardInteraction> with SingleTickerProviderStateMixin {
  Animation<Offset> _animation;
  AnimationController _controller;
  static const double MAX_SCALE = 2.5;
  static const double MIN_SCALE = 0.8;
  static const Size _VISIBLE_SIZE = Size(1600, 2400);
  // The translation that will be applied to the scene (not viewport).
  // A positive x offset moves the scene right, viewport left.
  // A positive y offset moves the scene down, viewport up.
  // Start out looking at the center.
  static Offset __translation = const Offset(0, 0);
  Offset _translateFrom = null; // Point where a single translation began
  double _scaleStart; // Scale value at start of scaling gesture
  double __scale = 1.0;
  double _rotationStart;
  // TODO rotation should be centered at the gesture's focal point.
  // But that's hard. I can do rotation around an arbitrary center using
  // matrices, but when I try to do a second rotation about a different center,
  // it doesn't work (short of keeping track of all rotation points and angles).
  // Another idea is to convert rotation about a center into a regular rotation
  // and translation. However, that would mean that my _translation would be
  // constantly changing during a rotation, and it won't quite mean what it
  // currently does anymore.
  double _rotation = 0.0;

  Offset get _translation => __translation;
  set _translation(Offset offset) {
    // Clamp _translation such that viewport can't see beyond _VISIBLE_SIZE
    final Size screenSizeScene = widget.screenSize / _scale;
    __translation = Offset(
      offset.dx.clamp(
        -_VISIBLE_SIZE.width / 2 + screenSizeScene.width / 2,
        _VISIBLE_SIZE.width / 2 - screenSizeScene.width / 2,
      ),
      offset.dy.clamp(
        -_VISIBLE_SIZE.height / 2 + screenSizeScene.height / 2,
        _VISIBLE_SIZE.height / 2 - screenSizeScene.height / 2,
      ),
    );
  }

  double get _scale => __scale;
  set _scale(double scale) {
    __scale = scale.clamp(MIN_SCALE, MAX_SCALE);
  }

  @override
  void initState() {
    super.initState();
    _translateFrom = Offset(widget.screenSize.width / 2, widget.screenSize.height / 2);
    //_translateFrom = Offset(widget.screenSize.width / 2 - 200, widget.screenSize.height / 2 - 200);
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
          transform: BoardInteractionState.getTransformationMatrix(translationCentered, _scale, _rotation),
          child: widget.child,
        ),
      ),
    );
  }

  // Get a matrix that will transform the origin of the scene with the given
  // translation, scale, and rotation so that it ends up centered under the
  // viewport.
  static Matrix4 getTransformationMatrix(Offset translation, double scale, double rotation, [Offset focalPoint = Offset.zero]) {
    final Matrix4 scaleMatrix = Matrix4(
      scale, 0, 0, 0,
      0, scale, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    );
    final Matrix4 translationMatrix = Matrix4(
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      translation.dx, translation.dy, 0, 1,
    );
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
    final Matrix4 matrix = BoardInteractionState.getTransformationMatrix(
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
      _translateFrom = Offset.zero;
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

// CustomPainter is what is passed to CustomPaint and actually draws the scene
// when its `paint` method is called.
class BoardPainter extends CustomPainter {
  BoardPainter({
    this.board,
  });

  Board board;

  // Draw each hexagon
  @override
  void paint(Canvas canvas, Size size) {
    final Color hexagonColor = Colors.grey[600];
    final Color hexagonColorSelected = Colors.blue[300];

    void drawBoardPoint(BoardPoint boardPoint) {
      final Color color = board.selected == boardPoint
        ? hexagonColorSelected : hexagonColor;
      final Vertices vertices = board.getVerticesForBoardPoint(boardPoint, color);
      canvas.drawVertices(vertices, BlendMode.color, Paint());
    }

    board.forEach(drawBoardPoint);
  }

  // We should repaint whenever the board changes, such as board.selected.
  @override
  bool shouldRepaint(BoardPainter oldDelegate) {
    return oldDelegate.board != board;
  }
}
