import 'dart:math';
import 'package:flutter/material.dart';

class PanAndZoomDemo extends StatelessWidget {
  const PanAndZoomDemo({Key key}) : super(key: key);

  static const String routeName = '/pan_and_zoom';

  @override
  Widget build(BuildContext context) => PanAndZoom();
}

class PanAndZoom extends StatelessWidget {
  @override
  Widget build (BuildContext context) {
    final MapPainter painter = MapPainter();
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

class MapInteraction extends StatefulWidget {
  const MapInteraction({
    @required this.child,
    @required this.screenSize,
  });

  final Widget child;
  final Size screenSize;

  @override _MapInteractionState createState() => _MapInteractionState();
}

class _MapInteractionState extends State<MapInteraction> {
  static const double MAX_SCALE = 2.5;
  static const double MIN_SCALE = 0.25;
  Point<double> _offset;
  Point<double> _translateFrom;
  double _scaleStart = 1.0; // Scale value at start of scaling gesture
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();

    // Start out looking at the center
    // TODO should accept this in the constructor
    _offset = const Point<double>(0.0, 0.0);
  }

  @override
  Widget build (BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
    final Matrix4 translateToOrigin = Matrix4(
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      widget.screenSize.width / 2, widget.screenSize.height / 2, 0, 1,
    );
    final Matrix4 scale = Matrix4(
      _scale, 0, 0, 0,
      0, _scale, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    );
    final Matrix4 translateFromOrigin = Matrix4(
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      - widget.screenSize.width / 2, - widget.screenSize.height / 2, 0, 1,
    );
    final Matrix4 translate = Matrix4(
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      _offset.x, _offset.y, 0, 1,
    );
    final Matrix4 transform = translateToOrigin * scale * translateFromOrigin * translate;
    return transform;
  }

  // Handle panning and pinch zooming
  void onScaleStart(ScaleStartDetails details) {
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
        _offset = Point<double>(
          _offset.x + details.focalPoint.dx - _translateFrom.x,
          _offset.y + details.focalPoint.dy - _translateFrom.y,
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
  }
}

class MapPainter extends CustomPainter {
  static const Color SHADOW_COLOR = Colors.grey[700];
  static const double RADIUS = 64.0;

  @override
  void paint(Canvas canvas, Size size) {
    drawMap(canvas, size, 4);
  }

  // Draw the game map with the given radius
  void drawMap(Canvas canvas, Size size, int radius) {
    final Path hexagon = createHexagonAt(size);
    canvas.drawPath(
      hexagon,
      Paint()
        ..color = Colors.grey
        ..style = PaintingStyle.fill
        ..strokeWidth = 2.0,
    );
    canvas.drawPath(
      Path.from(hexagon),
      Paint()
        ..color = Colors.grey[800]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  Path createHexagonAt(Size size) {
    // Center of hexagon with the proper canvas center
    final Point<double> center = Point<double>(size.width / 2, size.height / 2);
    /*
    Point<double> centerOfHex = Point<double>(
      centerOfHexZeroCenter.x + center.x,
      centerOfHexZeroCenter.y + center.y,
    );
    */

    // Start point of hexagon (top vertex)
    final Point<double> hexStart = Point<double>(
      center.x,
      center.y - RADIUS,
    );

    return createHexagonAtPixels(hexStart);
  }

  // Return a hexagon where the top vertex is at the given point in pixels
  Path createHexagonAtPixels(Point<double> point) {
    final Path hexagon = Path();
    hexagon.moveTo(point.x, point.y);
    hexagon.lineTo(point.x + sqrt(3) / 2 * RADIUS, point.y + 0.5 * RADIUS);
    hexagon.lineTo(point.x + sqrt(3) / 2 * RADIUS, point.y + 1.5 * RADIUS);
    hexagon.lineTo(point.x, point.y + 2 * RADIUS);
    hexagon.lineTo(point.x - sqrt(3) / 2 * RADIUS, point.y + 1.5 * RADIUS);
    hexagon.lineTo(point.x - sqrt(3) / 2 * RADIUS, point.y + 0.5 * RADIUS);
    hexagon.close();
    return hexagon;
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) => false;
}
