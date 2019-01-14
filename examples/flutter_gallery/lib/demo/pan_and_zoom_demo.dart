import 'package:flutter/material.dart';
import 'pan_and_zoom_demo_board.dart';
import 'pan_and_zoom_demo_inertial_motion.dart';

class PanAndZoomDemo extends StatelessWidget {
  const PanAndZoomDemo({Key key}) : super(key: key);

  static const String routeName = '/pan_and_zoom';

  @override
  Widget build(BuildContext context) => PanAndZoom();
}

// TODO Create a maximum size border around the hexagon board
class PanAndZoom extends StatelessWidget {
  static const double HEXAGON_RADIUS = 32.0;
  static const int BOARD_RADIUS = 8;

  @override
  Widget build (BuildContext context) {
    final Board board = Board(
      boardRadius: BOARD_RADIUS,
      hexagonRadius: HEXAGON_RADIUS,
    );
    final BoardPainter painter = BoardPainter(
      board: board,
    );
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: MapInteraction(
        child: CustomPaint(
          size: Size.infinite,
          painter: painter,
        ),
        screenSize: screenSize,
      ),
    );
  }
}

// This StatefulWidget handles all user interaction
class MapInteraction extends StatefulWidget {
  const MapInteraction({
    @required this.child,
    @required this.screenSize,
  });

  final Widget child;
  final Size screenSize;

  @override _MapInteractionState createState() => _MapInteractionState();
}
class _MapInteractionState extends State<MapInteraction> with SingleTickerProviderStateMixin {
  Animation<Offset> _animation;
  AnimationController _controller;
  static const double MAX_SCALE = 2.5;
  static const double MIN_SCALE = 0.8;
  static const Size _PANNABLE_SIZE = Size(2000, 2000);
  // Start out looking at the center
  // A positive x offset moves the scene right, viewport left.
  // A positive y offset moves the scene down, viewport up.
  static Offset __translation = const Offset(0, 0);
  Offset _translateFrom; // Point where a single translation began
  double _scaleStart = 1.0; // Scale value at start of scaling gesture
  double _scale = 0.8;

  Offset get _translation => __translation;
  set _translation(Offset offset) {
    // Clamp _translation such that viewport can't see beyond _PANNABLE_SIZE
    final Size screenSizeScene = widget.screenSize / _scale;
    __translation = Offset(
      offset.dx.clamp(
        -_PANNABLE_SIZE.width / 2 + screenSizeScene.width,
        _PANNABLE_SIZE.width / 2,
      ),
      offset.dy.clamp(
        -_PANNABLE_SIZE.height / 2 + screenSizeScene.height,
        _PANNABLE_SIZE.height / 2,
      ),
    );
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
      onScaleEnd: onScaleEnd,
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      child: ClipRect(
        child: Transform(
          transform: getTransformationMatrix(),
          child: widget.child,
        ),
      ),
    );
  }

  Matrix4 getTransformationMatrix() {
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
  Offset _fromScreen(Offset screenPoint, Offset offset, double scale) {
    // After scaling, the center of the screen is still the same scene coords.
    // Find the distance from the center of the screen to the given screenPoint.
    final Offset fromCenterOfScreen = Offset(
      screenPoint.dx - widget.screenSize.width / 2,
      screenPoint.dy - widget.screenSize.height / 2,
    );
    final Offset fromCenterOfScreenSceneCoords = fromCenterOfScreen / scale;
    // The absolute location of screenPoint in scene coords is the sum.
    return offset + fromCenterOfScreenSceneCoords;
  }

  // Handle panning and pinch zooming events
  void onScaleStart(ScaleStartDetails details) {
    _controller.stop();
    setState(() {
      _scaleStart = _scale;
      _translateFrom = details.focalPoint;
    });
  }
  void onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (_scaleStart != null) {
        final Offset focalPointScene = _fromScreen(details.focalPoint, _translation, _scale);
        _scale = _scaleStart * details.scale;
        if (_scale > MAX_SCALE) {
          _scale = MAX_SCALE;
        }
        if (_scale < MIN_SCALE) {
          _scale = MIN_SCALE;
        }

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
  void onScaleEnd(ScaleEndDetails details) {
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

  void _onAnimate() {
    setState(() {
      _translation = _animation.value;
    });
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

  static const Size _PANNABLE_SIZE = Size(2000, 2000);
  Board board;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint hexagonFillPaint = Paint()
      ..color = Colors.grey[600]
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    void drawBoardPoint(BoardPoint boardPoint) {
      canvas.drawPath(board.getPathForBoardPoint(boardPoint), hexagonFillPaint);
    }

    board.forEach(drawBoardPoint);

    // TODO remove
    canvas.drawRect(
      Rect.fromLTWH(-_PANNABLE_SIZE.width / 2, -_PANNABLE_SIZE.height / 2, _PANNABLE_SIZE.width, _PANNABLE_SIZE.height),
      Paint()
        ..color = Colors.pink
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) => false;
}
