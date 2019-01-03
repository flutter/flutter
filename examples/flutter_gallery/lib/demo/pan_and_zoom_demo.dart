import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart' hide Gradient;
import 'package:vector_math/vector_math.dart' show Vector2;
import 'pan_and_zoom_demo_board.dart';

class PanAndZoomDemo extends StatelessWidget {
  const PanAndZoomDemo({Key key}) : super(key: key);

  static const String routeName = '/pan_and_zoom';

  @override
  Widget build(BuildContext context) => PanAndZoom();
}

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
  Animation<double> _animation;
  AnimationController _controller;
  static const double MAX_SCALE = 2.5;
  static const double MIN_SCALE = 0.25;
  Point<double> _offset;
  Point<double> _translateFrom; // Point where a single translation began
  // TODO scale at point where user's fingers are?
  double _scaleStart = 1.0; // Scale value at start of scaling gesture
  double _scale = 1.0;
  Function animationListener;

  @override
  void initState() {
    super.initState();

    // Start out looking at the center
    // A positive x offset moves the scene right, viewport left.
    // A positive y offset moves the scene down, viewport up.
    _offset = Point<double>(
      widget.screenSize.width / 2,
      widget.screenSize.height / 2,
    );

    _controller = AnimationController(
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
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

    // Original center of the screen with no transformations applied.
    final Point<double> originalCenterOfScreen = Point<double>(
      widget.screenSize.width / 2,
      widget.screenSize.height / 2,
    );
    // Center after scale has been applied.
    // Imagine the scene scaling underneath the viewport while the viewport
    // stays fixed, then this is the new point under the center of the viewport.
    final Point<double> scaledCenterOfScreen = originalCenterOfScreen * (1 / _scale);
    // Center after scale and offset have been applied.
    final Point<double> finalCenterOfScreen = scaledCenterOfScreen + _offset;
    // Translate the original center of the screen to the final center.
    final Vector2 translationVector = Vector2(
        finalCenterOfScreen.x - originalCenterOfScreen.x,
        finalCenterOfScreen.y - originalCenterOfScreen.y,
    );
    final Matrix4 translate = Matrix4(
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      translationVector.x, translationVector.y, 0, 1,
    );

    return scale * translate;
  }

  // Handle panning and pinch zooming events
  void onScaleStart(ScaleStartDetails details) {
    _controller.stop();
    setState(() {
      _scaleStart = _scale;
      _translateFrom = Point<double>(details.focalPoint.dx, details.focalPoint.dy);
    });
  }
  void onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (_scaleStart != null) {
        _scale = _scaleStart * details.scale;
        if (_scale > MAX_SCALE) {
          _scale = MAX_SCALE;
        }
        if (_scale < MIN_SCALE) {
          _scale = MIN_SCALE;
        }
      }
      if (_translateFrom != null && details.scale == 1.0) {
        // The coordinates given by details.focalPoint are screen coordinates
        // that are not affected by _scale. So, dividing by scale here properly
        // gives us more distance when zoomed out and less when zoomed in so
        // that the point under the user's finger stays constant during a drag.
        _offset = Point<double>(
          _offset.x + (details.focalPoint.dx - _translateFrom.x) / _scale,
          _offset.y + (details.focalPoint.dy - _translateFrom.y) / _scale,
        );
        _translateFrom = Point<double>(
          details.focalPoint.dx,
          details.focalPoint.dy,
        );
      }
    });
  }
  void onScaleEnd(ScaleEndDetails details) {
    setState(() {
      _scaleStart = null;
      _translateFrom = null;
    });

    _animation.removeListener(animationListener);
    _controller.reset();

    if (details.velocity.pixelsPerSecond.dx == 0
      && details.velocity.pixelsPerSecond.dy == 0) {
      return;
    }

    final Inertia inertia = Inertia(details.velocity, _offset);
    _controller.duration = Duration(milliseconds: inertia.getDuration().toInt());
    animationListener = () {
      if (_animation.value <= 0) {
        return;
      }

      setState(() {
        final Point<double> offsetNext = inertia.getPositionAt(
          Duration(milliseconds: (_animation.value * _controller.duration.inMilliseconds).toInt()),
        );

        if (_offset.distanceTo(offsetNext) == 0) {
          _animation.removeListener(animationListener);
          return;
        }
        _offset = offsetNext;
      });
    };
    _animation.addListener(animationListener);
    _controller.forward();
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
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    void drawBoardPoint(BoardPoint boardPoint) {
      canvas.drawPath(board.getPathForBoardPoint(boardPoint), hexagonFillPaint);
    }

    board.forEach(drawBoardPoint);
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) => false;
}

class Inertia {
  Inertia(this._initialVelocity, this._initialPosition);

  static const double FRICTIONAL_ACCELERATION = 0.01;
  Velocity _initialVelocity;
  Point<double> _initialPosition;

  Point<double> getPositionAt(Duration time) {
    final double velocityTotal = _initialVelocity.pixelsPerSecond.dx.abs() + _initialVelocity.pixelsPerSecond.dy.abs();
    if (velocityTotal == 0) {
      return _initialPosition;
    }

    final double xf = _getPosition(
      r0: _initialPosition.x,
      v0: _initialVelocity.pixelsPerSecond.dx / 1000,
      t: time.inMilliseconds,
      a: acceleration.x,
    );
    final double yf = _getPosition(
      r0: _initialPosition.y,
      v0: _initialVelocity.pixelsPerSecond.dy / 1000,
      t: time.inMilliseconds,
      a: acceleration.y,
    );
    return Point<double>(xf, yf);
  }

  // The acceleration opposing the initial velocity
  Vector2 get acceleration {
    final double velocityTotal = _initialVelocity.pixelsPerSecond.dx.abs() + _initialVelocity.pixelsPerSecond.dy.abs();
    final double vRatioX = _initialVelocity.pixelsPerSecond.dx.abs() / velocityTotal;
    final double vRatioY = _initialVelocity.pixelsPerSecond.dy.abs() / velocityTotal;
    final double vSignX = _initialVelocity.pixelsPerSecond.dx.isNegative ? 1 : -1;
    final double vSignY = _initialVelocity.pixelsPerSecond.dy.isNegative ? 1 : -1;
    return Vector2(
      vSignX * FRICTIONAL_ACCELERATION * vRatioX,
      vSignY * FRICTIONAL_ACCELERATION * vRatioY,
    );
  }

  // Get the total time that the animation takes to stop
  double getDuration() {
    return (_initialVelocity.pixelsPerSecond.dx / 1000 / acceleration.x).abs();
  }

  // Physics equation of motion
  double _getPosition({double r0, double v0, int t, double a}) {
    // Stop movement when it would otherwise reverse direction
    final double stopTime = (v0 / a).abs();
    if (t > stopTime) {
      t = stopTime.toInt();
    }

    final double answer = r0 + v0 * t + 0.5 * a * pow(t, 2);
    return answer;
  }
}
