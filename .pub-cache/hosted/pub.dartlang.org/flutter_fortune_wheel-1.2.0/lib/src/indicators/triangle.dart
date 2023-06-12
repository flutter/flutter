part of 'indicators.dart';

class _TrianglePainter extends CustomPainter {
  final Color fillColor;
  final Color? strokeColor;
  final double strokeWidth;
  final double elevation;

  const _TrianglePainter({
    required this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1,
    this.elevation = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(size.width / 2, 0);

    final strokeColor = this.strokeColor ?? fillColor;
    final fillPaint = Paint()..color = fillColor;
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawShadow(path, Colors.black, elevation, true);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) {
    return fillColor != oldDelegate.fillColor ||
        elevation != oldDelegate.elevation ||
        strokeWidth != oldDelegate.strokeWidth ||
        strokeColor != oldDelegate.strokeColor;
  }
}

class _Triangle extends StatelessWidget {
  final Color color;
  final Color? borderColor;
  final double borderWidth;
  final double elevation;

  const _Triangle({
    required this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrianglePainter(
        fillColor: color,
        strokeColor: borderColor,
        strokeWidth: borderWidth,
        elevation: elevation,
      ),
    );
  }
}
