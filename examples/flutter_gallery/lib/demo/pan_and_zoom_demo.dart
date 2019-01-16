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
  static const int BOARD_RADIUS = 8;

  Board _board = Board(
    boardRadius: BOARD_RADIUS,
    hexagonRadius: HEXAGON_RADIUS,
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

  @override _BoardInteractionState createState() => _BoardInteractionState();
}
class _BoardInteractionState extends State<BoardInteraction> with SingleTickerProviderStateMixin {
  Animation<Offset> _animation;
  AnimationController _controller;
  static const double MAX_SCALE = 2.5;
  static const double MIN_SCALE = 0.8;
  static const Size _VISIBLE_SIZE = Size(1200, 1200);
  // The translation that will be applied to the scene (not viewport).
  // A positive x offset moves the scene right, viewport left.
  // A positive y offset moves the scene down, viewport up.
  // Start out looking at the center.
  static Offset __translation = const Offset(0, 0);
  Offset _translateFrom; // Point where a single translation began
  double _scaleStart = 1.0; // Scale value at start of scaling gesture
  double __scale = 1.0;

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
    _controller = AnimationController(
      vsync: this,
    );
  }

  @override
  Widget build (BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Necessary when translating off screen
      onScaleEnd: _onScaleEnd,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onTapUp: _onTapUp,
      child: ClipRect(
        child: Transform(
          transform: _getTransformationMatrix(),
          child: widget.child,
        ),
      ),
    );
  }

  Matrix4 _getTransformationMatrix() {
    // Scaling happens first in matrix multiplication, centered on the origin,
    // while our canvas is at its original position with zero translation.
    final Matrix4 scale = Matrix4(
      _scale, 0, 0, 0,
      0, _scale, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    );

    // Translate the scene to put _translation under the center of the viewport
    final Offset originalCenterOfScreen = Offset(
      widget.screenSize.width / 2,
      widget.screenSize.height / 2,
    );
    final Offset scaledCenterOfScreen = originalCenterOfScreen * (1 / _scale);
    final Offset offsetUnderCenter = _translation + scaledCenterOfScreen;
    final Matrix4 translate = Matrix4(
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      offsetUnderCenter.dx, offsetUnderCenter.dy, 0, 1,
    );

    return scale * translate;
  }

  // Given a point in screen coordinates, return the point in the scene.
  // Scene coordinates are independent of scale, just like _translation.
  Offset _fromScreen(Offset screenPoint, Offset translation, double scale) {
    // After scaling, the center of the screen is still the same scene coords.
    // Find the distance from the center of the screen to the given screenPoint.
    final Offset fromCenterOfScreen = Offset(
      screenPoint.dx - widget.screenSize.width / 2,
      screenPoint.dy - widget.screenSize.height / 2,
    );
    final Offset fromCenterOfScreenSceneCoords = fromCenterOfScreen / scale;
    // The absolute location of screenPoint in scene coords is the difference,
    // because translation is the inverse of the center of the screen.
    return fromCenterOfScreenSceneCoords - translation;
  }

  // Handle panning and pinch zooming events
  void _onScaleStart(ScaleStartDetails details) {
    _controller.stop();
    setState(() {
      _scaleStart = _scale;
      _translateFrom = details.focalPoint;
    });
  }
  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (_scaleStart != null) {
        final Offset focalPointScene = _fromScreen(details.focalPoint, _translation, _scale);
        _scale = _scaleStart * details.scale;

        if (details.scale != 1.0) {
          // While scaling, translate such that the user's fingers stay on the
          // same place in the scene. That means that the focal point of the
          // scale should be on the same place in the scene before and after the
          // scale.
          final Offset focalPointSceneNext = _fromScreen(details.focalPoint, _translation, _scale);
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
    });
  }
  void _onScaleEnd(ScaleEndDetails details) {
    setState(() {
      _scaleStart = null;
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
    widget.onTapUp(_fromScreen(details.globalPosition, _translation, _scale));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class BoardPainter extends CustomPainter {
  BoardPainter({
    this.board,
  });

  Board board;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint hexagonFillPaint = Paint()
      ..color = Colors.grey[600]
      ..style = PaintingStyle.fill;
    final Paint hexagonFillPaintSelected = Paint()
      ..color = Colors.blue[300]
      ..style = PaintingStyle.fill;

    void drawBoardPoint(BoardPoint boardPoint) {
      final Paint paint = board.selected == boardPoint
        ? hexagonFillPaintSelected : hexagonFillPaint;
      canvas.drawPath(board.getPathForBoardPoint(boardPoint), paint);
    }

    board.forEach(drawBoardPoint);
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) {
    return oldDelegate.board != board;
  }
}
