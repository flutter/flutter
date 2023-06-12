// ignore_for_file: require_trailing_commas, non_constant_identifier_names

part of 'device.dart';

// Generated manually with https://fluttershapemaker.com/
class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {

    Paint paint_0_fill = Paint()..style=PaintingStyle.fill;
    paint_0_fill.color = Color(0xff3A4245).withOpacity(1.0);
    canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(size.width*0.0003262249,size.height*0.007120380,size.width*0.9964216,size.height*0.9926980),bottomRight: Radius.circular(size.width*0.05891892),bottomLeft:  Radius.circular(size.width*0.05891892),topLeft:  Radius.circular(size.width*0.05891892),topRight:  Radius.circular(size.width*0.05891892)),paint_0_fill);

    Paint paint_1_fill = Paint()..style=PaintingStyle.fill;
    paint_1_fill.color = Color(0xff121515).withOpacity(1.0);
    canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(size.width*0.004544973,size.height*0.01005611,size.width*0.9885297,size.height*0.9869802),bottomRight: Radius.circular(size.width*0.05405405),bottomLeft:  Radius.circular(size.width*0.05405405),topLeft:  Radius.circular(size.width*0.05405405),topRight:  Radius.circular(size.width*0.05405405)),paint_1_fill);

    Path path_2 = Path();
    path_2.moveTo(1843.99,183.302);
    path_2.cubicTo(1847.12,183.302,1849.67,184.073,1849.67,185.025);
    path_2.lineTo(1849.67,267.72);
    path_2.cubicTo(1849.67,268.671,1847.12,269.442,1843.99,269.442);
    path_2.lineTo(1843.99,183.302);
    path_2.close();

    Paint paint_2_fill = Paint()..style=PaintingStyle.fill;
    paint_2_fill.color = Color(0xff121515).withOpacity(1.0);
    canvas.drawPath(path_2,paint_2_fill);

    Path path_3 = Path();
    path_3.moveTo(1843.99,288.202);
    path_3.cubicTo(1847.12,288.202,1849.67,288.973,1849.67,289.925);
    path_3.lineTo(1849.67,372.619);
    path_3.cubicTo(1849.67,373.571,1847.12,374.342,1843.99,374.342);
    path_3.lineTo(1843.99,288.202);
    path_3.close();

    Paint paint_3_fill = Paint()..style=PaintingStyle.fill;
    paint_3_fill.color = Color(0xff121515).withOpacity(1.0);
    canvas.drawPath(path_3,paint_3_fill);

    Path path_4 = Path();
    path_4.moveTo(1633.03,17.2598);
    path_4.cubicTo(1633.03,14.3084,1633.93,11.9159,1635.05,11.9159);
    path_4.lineTo(1732.14,11.9159);
    path_4.cubicTo(1733.26,11.9159,1734.16,14.3084,1734.16,17.2598);
    path_4.lineTo(1633.03,17.2598);
    path_4.close();

    Paint paint_4_fill = Paint()..style=PaintingStyle.fill;
    paint_4_fill.color = Color(0xff121515).withOpacity(1.0);
    canvas.drawPath(path_4,paint_4_fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}