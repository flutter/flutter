// ignore_for_file: require_trailing_commas, non_constant_identifier_names

part of 'device.dart';

// Generated manually with https://fluttershapemaker.com/
class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path_0 = Path();
    path_0.moveTo(0, 133.53);
    path_0.cubicTo(0, 62.8561, 57.2924, 5.56372, 127.966, 5.56372);
    path_0.lineTo(1677.47, 5.56372);
    path_0.cubicTo(1748.14, 5.56372, 1805.44, 62.8561, 1805.44, 133.53);
    path_0.lineTo(1805.44, 2381.28);
    path_0.cubicTo(1805.44, 2451.96, 1748.14, 2509.25, 1677.47, 2509.25);
    path_0.lineTo(127.966, 2509.25);
    path_0.cubicTo(57.2924, 2509.25, 0, 2451.96, 0, 2381.28);
    path_0.lineTo(0, 133.53);
    path_0.close();

    final paint_0_fill = Paint()..style = PaintingStyle.fill;
    paint_0_fill.color = const Color(0xff3A4245);
    canvas.drawPath(path_0, paint_0_fill);

    final path_1 = Path();
    path_1.moveTo(11.1279, 133.53);
    path_1.cubicTo(11.1279, 69.0018, 63.4384, 16.6913, 127.967, 16.6913);
    path_1.lineTo(1677.47, 16.6913);
    path_1.cubicTo(1742, 16.6913, 1794.31, 69.0018, 1794.31, 133.53);
    path_1.lineTo(1794.31, 2381.28);
    path_1.cubicTo(1794.31, 2445.81, 1742, 2498.12, 1677.47, 2498.12);
    path_1.lineTo(127.967, 2498.12);
    path_1.cubicTo(63.4384, 2498.12, 11.1279, 2445.81, 11.1279, 2381.28);
    path_1.lineTo(11.1279, 133.53);
    path_1.close();

    final paint_1_fill = Paint()..style = PaintingStyle.fill;
    paint_1_fill.color = const Color(0xff121515);
    canvas.drawPath(path_1, paint_1_fill);

    final path_2 = Path();
    path_2.moveTo(1805.44, 203.077);
    path_2.cubicTo(1808.51, 203.077, 1811, 203.974, 1811, 205.08);
    path_2.lineTo(1811, 301.221);
    path_2.cubicTo(1811, 302.328, 1808.51, 303.224, 1805.44, 303.224);
    path_2.lineTo(1805.44, 203.077);
    path_2.close();

    final paint_2_fill = Paint()..style = PaintingStyle.fill;
    paint_2_fill.color = const Color(0xff121515);
    canvas.drawPath(path_2, paint_2_fill);

    final path_3 = Path();
    path_3.moveTo(1805.44, 322.697);
    path_3.cubicTo(1808.51, 322.697, 1811, 323.619, 1811, 324.756);
    path_3.lineTo(1811, 423.568);
    path_3.cubicTo(1811, 424.705, 1808.51, 425.627, 1805.44, 425.627);
    path_3.lineTo(1805.44, 322.697);
    path_3.close();

    final paint_3_fill = Paint()..style = PaintingStyle.fill;
    paint_3_fill.color = const Color(0xff121515);
    canvas.drawPath(path_3, paint_3_fill);

    final path_4 = Path();
    path_4.moveTo(1504.99, 5.56372);
    path_4.cubicTo(1504.99, 2.49095, 1506.54, 0, 1508.44, 0);
    path_4.cubicTo(0, 0, 1677.47, 2.49094, 1677.47, 5.56371);
    path_4.lineTo(1504.99, 5.56372);
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
