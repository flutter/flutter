import 'dart:math';
import 'package:flutter/material.dart';

import 'popup_window.dart';
import 'window_settings.dart';

class RegularWindowContent extends StatefulWidget {
  const RegularWindowContent({super.key});

  @override
  State<RegularWindowContent> createState() => _RegularWindowContentState();
}

class _RegularWindowContentState extends State<RegularWindowContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  late final Color cubeColor;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 2 * pi,
      duration: const Duration(seconds: 15),
    )..repeat();
    cubeColor = _generateRandomDarkColor();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  Color _generateRandomDarkColor() {
    final random = Random();
    const int lowerBound = 32;
    const int span = 160;
    int red = lowerBound + random.nextInt(span);
    int green = lowerBound + random.nextInt(span);
    int blue = lowerBound + random.nextInt(span);
    return Color.fromARGB(255, red, green, blue);
  }

  @override
  Widget build(BuildContext context) {
    final window = WindowContext.of(context)!.window;
    final dpr = MediaQuery.of(context).devicePixelRatio;

    final widget = Scaffold(
      appBar: AppBar(title: const Text('Regular')),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(200, 200),
                      painter: RotatedWireCube(
                          angle: _animation.value, color: cubeColor),
                    );
                  },
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await createRegular(
                        context: context,
                        size: WindowSettings().regularSize,
                        builder: (BuildContext context) =>
                            const MaterialApp(home: RegularWindowContent()));
                  },
                  child: const Text('New Regular'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    await createPopup(
                        context: context,
                        parent: window,
                        size: WindowSettings().popupSize,
                        anchorRect: Rect.fromLTWH(
                            0,
                            0,
                            window.view.physicalSize.width / dpr,
                            window.view.physicalSize.height / dpr),
                        positioner: const WindowPositioner(
                          parentAnchor: WindowPositionerAnchor.center,
                          childAnchor: WindowPositionerAnchor.center,
                          offset: Offset(0, 0),
                          constraintAdjustment: <WindowPositionerConstraintAdjustment>{
                            WindowPositionerConstraintAdjustment.slideX,
                            WindowPositionerConstraintAdjustment.slideY,
                          },
                        ),
                        builder: (BuildContext context) =>
                            const PopupWindowContent());
                  },
                  child: const Text('Child Popup'),
                ),
                const SizedBox(height: 20),
                Text(
                  'View ID: ${window.view.viewId}\n'
                  'Parent View ID: ${window.parent?.view.viewId}\n'
                  'View Size: ${(window.view.physicalSize.width / dpr).toStringAsFixed(1)}\u00D7${(window.view.physicalSize.height / dpr).toStringAsFixed(1)}\n'
                  'Window Size: ${window.size.width}\u00D7${window.size.height}\n'
                  'Device Pixel Ratio: $dpr',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final List<Widget> childViews = window.children.map((childWindow) {
      return View(
        view: childWindow.view,
        child: WindowContext(
          window: childWindow,
          child: childWindow.builder(context),
        ),
      );
    }).toList();

    return ViewAnchor(view: ViewCollection(views: childViews), child: widget);
  }
}

class RotatedWireCube extends CustomPainter {
  static const List<List<double>> vertices = [
    [-.5, -.5, -.5],
    [.5, -.5, -.5],
    [.5, .5, -.5],
    [-.5, .5, -.5],
    [-.5, -.5, .5],
    [.5, -.5, .5],
    [.5, .5, .5],
    [-.5, .5, .5],
  ];

  static const List<List<int>> edges = [
    [0, 1], [1, 2], [2, 3], [3, 0], // Front face
    [4, 5], [5, 6], [6, 7], [7, 4], // Back face
    [0, 4], [1, 5], [2, 6], [3, 7], // Connecting front and back
  ];

  final double angle;
  final Color color;

  RotatedWireCube({required this.angle, required this.color});

  List<double> rotateX(double angle, List<double> point) {
    final cosAngle = cos(angle);
    final sinAngle = sin(angle);
    final y = point[1] * cosAngle - point[2] * sinAngle;
    final z = point[1] * sinAngle + point[2] * cosAngle;
    return [point[0], y, z];
  }

  List<double> rotateY(double angle, List<double> point) {
    final cosAngle = cos(angle);
    final sinAngle = sin(angle);
    final x = point[0] * cosAngle + point[2] * sinAngle;
    final z = -point[0] * sinAngle + point[2] * cosAngle;
    return [x, point[1], z];
  }

  List<double> rotateZ(double angle, List<double> point) {
    final cosAngle = cos(angle);
    final sinAngle = sin(angle);
    final x = point[0] * cosAngle - point[1] * sinAngle;
    final y = point[0] * sinAngle + point[1] * cosAngle;
    return [x, y, point[2]];
  }

  Offset scaleAndCenter(List<double> point, double size, Offset center) {
    final scale = size / 2;
    return Offset(center.dx + point[0] * scale, center.dy - point[1] * scale);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rotatedVertices = vertices
        .map((vertex) => rotateX(angle, vertex))
        .map((vertex) => rotateY(angle, vertex))
        .map((vertex) => rotateZ(angle, vertex))
        .toList();

    final center = Offset(size.width / 2, size.height / 2);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var edge in edges) {
      final p1 = scaleAndCenter(rotatedVertices[edge[0]], size.width, center);
      final p2 = scaleAndCenter(rotatedVertices[edge[1]], size.width, center);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(RotatedWireCube oldDelegate) => true;
}
