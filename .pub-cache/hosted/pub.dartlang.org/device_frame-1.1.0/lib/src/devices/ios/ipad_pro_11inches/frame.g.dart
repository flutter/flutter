// ignore_for_file: require_trailing_commas, non_constant_identifier_names

part of 'device.dart';

// Generated manually with https://fluttershapemaker.com/
class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path_0 = Path();
    path_0.moveTo(0, 128.369);
    path_0.cubicTo(0, 60.4267, 55.0779, 5.34875, 123.02, 5.34875);
    path_0.lineTo(1612.63, 5.34875);
    path_0.cubicTo(1680.57, 5.34875, 1735.65, 60.4267, 1735.65, 128.369);
    path_0.lineTo(1735.65, 2289.24);
    path_0.cubicTo(1735.65, 2357.18, 1680.57, 2412.26, 1612.63, 2412.26);
    path_0.lineTo(123.02, 2412.26);
    path_0.cubicTo(55.0779, 2412.26, 0, 2357.18, 0, 2289.24);
    path_0.lineTo(0, 128.369);
    path_0.close();

    final paint_0_fill = Paint()..style = PaintingStyle.fill;
    paint_0_fill.color = const Color(0xff3A4245);
    canvas.drawPath(path_0, paint_0_fill);

    final path_1 = Path();
    path_1.moveTo(10.6973, 128.369);
    path_1.cubicTo(10.6973, 66.3347, 60.9858, 16.0461, 123.02, 16.0461);
    path_1.lineTo(1612.63, 16.0461);
    path_1.cubicTo(1674.67, 16.0461, 1724.95, 66.3347, 1724.95, 128.369);
    path_1.lineTo(1724.95, 2289.24);
    path_1.cubicTo(1724.95, 2351.28, 1674.67, 2401.56, 1612.63, 2401.56);
    path_1.lineTo(123.02, 2401.56);
    path_1.cubicTo(60.9858, 2401.56, 10.6973, 2351.28, 10.6973, 2289.24);
    path_1.lineTo(10.6973, 128.369);
    path_1.close();

    final paint_1_fill = Paint()..style = PaintingStyle.fill;
    paint_1_fill.color = const Color(0xff121515);
    canvas.drawPath(path_1, paint_1_fill);

    final path_2 = Path();
    path_2.moveTo(1735.65, 195.227);
    path_2.cubicTo(1738.61, 195.227, 1741, 196.137, 1741, 197.26);
    path_2.lineTo(1741, 294.82);
    path_2.cubicTo(1741, 295.942, 1738.61, 296.852, 1735.65, 296.852);
    path_2.lineTo(1735.65, 195.227);
    path_2.close();

    final paint_2_fill = Paint()..style = PaintingStyle.fill;
    paint_2_fill.color = const Color(0xff121515);
    canvas.drawPath(path_2, paint_2_fill);

    final path_3 = Path();
    path_3.moveTo(1735.65, 310.224);
    path_3.cubicTo(1738.61, 310.224, 1741, 311.134, 1741, 312.257);
    path_3.lineTo(1741, 409.817);
    path_3.cubicTo(1741, 410.939, 1738.61, 411.849, 1735.65, 411.849);
    path_3.lineTo(1735.65, 310.224);
    path_3.close();

    final paint_3_fill = Paint()..style = PaintingStyle.fill;
    paint_3_fill.color = const Color(0xff121515);
    canvas.drawPath(path_3, paint_3_fill);

    final path_4 = Path();
    path_4.moveTo(1494.96, 5.34875);
    path_4.cubicTo(1494.96, 2.39475, 1496.04, 0, 1497.37, 0);
    path_4.lineTo(1612.9, 0);
    path_4.cubicTo(1614.23, 0, 1615.31, 2.39475, 1615.31, 5.34875);
    path_4.lineTo(1494.96, 5.34875);
    path_4.close();

    final paint_4_fill = Paint()..style = PaintingStyle.fill;
    paint_4_fill.color = const Color(0xff121515);
    canvas.drawPath(path_4, paint_4_fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
