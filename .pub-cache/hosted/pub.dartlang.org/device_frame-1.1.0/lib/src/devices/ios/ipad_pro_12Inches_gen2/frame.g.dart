// ignore_for_file: require_trailing_commas, non_constant_identifier_names

part of 'device.dart';

// Generated manually with https://fluttershapemaker.com/
class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {

    Paint paint_0_fill = Paint()..style=PaintingStyle.fill;
    paint_0_fill.color = Color(0xff3A4245).withOpacity(1.0);
    canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(size.width*0.003658750,0,size.width*0.9961124,size.height),bottomRight: Radius.circular(size.width*0.02752294),bottomLeft:  Radius.circular(size.width*0.02752294),topLeft:  Radius.circular(size.width*0.02752294),topRight:  Radius.circular(size.width*0.02752294)),paint_0_fill);

    Paint paint_1_fill = Paint()..style=PaintingStyle.fill;
    paint_1_fill.color = Color(0xff121515).withOpacity(1.0);
    canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(size.width*0.006571617,size.height*0.002108385,size.width*0.9902867,size.height*0.9957825),bottomRight: Radius.circular(size.width*0.02580275),bottomLeft:  Radius.circular(size.width*0.02580275),topLeft:  Radius.circular(size.width*0.02580275),topRight:  Radius.circular(size.width*0.02580275)),paint_1_fill);

    Path path_2 = Path();
    path_2.moveTo(832.508,2332);
    path_2.cubicTo(832.508,2355.75,851.536,2375,875.008,2375);
    path_2.cubicTo(898.48,2375,917.508,2355.75,917.508,2332);
    path_2.cubicTo(917.508,2308.25,898.48,2289,875.008,2289);
    path_2.cubicTo(851.536,2289,832.508,2308.25,832.508,2332);
    path_2.close();
    path_2.moveTo(912.112,2332);
    path_2.cubicTo(912.112,2352.73,895.5,2369.54,875.009,2369.54);
    path_2.cubicTo(854.517,2369.54,837.906,2352.73,837.906,2332);
    path_2.cubicTo(837.906,2311.27,854.517,2294.46,875.009,2294.46);
    path_2.cubicTo(895.5,2294.46,912.112,2311.27,912.112,2332);
    path_2.close();

    Paint paint_2_fill = Paint()..style=PaintingStyle.fill;
    paint_2_fill.color = Color(0xff262C2D).withOpacity(1.0);
    canvas.drawPath(path_2,paint_2_fill);

    Path path_3 = Path();
    path_3.moveTo(837.374,101.713);
    path_3.cubicTo(844.026,101.713,849.419,96.3206,849.419,89.6683);
    path_3.cubicTo(849.419,83.016,844.026,77.6233,837.374,77.6233);
    path_3.cubicTo(830.722,77.6233,825.329,83.016,825.329,89.6683);
    path_3.cubicTo(825.329,96.3206,830.722,101.713,837.374,101.713);
    path_3.close();

    Paint paint_3_fill = Paint()..style=PaintingStyle.fill;
    paint_3_fill.color = Color(0xff262C2D).withOpacity(1.0);
    canvas.drawPath(path_3,paint_3_fill);

    Path path_4 = Path();
    path_4.moveTo(837.374,97.1964);
    path_4.cubicTo(841.531,97.1964,844.902,93.8259,844.902,89.6683);
    path_4.cubicTo(844.902,85.5106,841.531,82.1401,837.374,82.1401);
    path_4.cubicTo(833.216,82.1401,829.846,85.5106,829.846,89.6683);
    path_4.cubicTo(829.846,93.8259,833.216,97.1964,837.374,97.1964);
    path_4.close();

    Paint paint_4_fill = Paint()..style=PaintingStyle.fill;
    paint_4_fill.color = Color(0xff121515).withOpacity(1.0);
    canvas.drawPath(path_4,paint_4_fill);

    Path path_5 = Path();
    path_5.moveTo(837.374,88.1626);
    path_5.cubicTo(838.205,88.1626,838.879,87.4885,838.879,86.657);
    path_5.cubicTo(838.879,85.8255,838.205,85.1514,837.374,85.1514);
    path_5.cubicTo(836.542,85.1514,835.868,85.8255,835.868,86.657);
    path_5.cubicTo(835.868,87.4885,836.542,88.1626,837.374,88.1626);
    path_5.close();

    Paint paint_5_fill = Paint()..style=PaintingStyle.fill;
    paint_5_fill.color = Color(0xff636F73).withOpacity(1.0);
    canvas.drawPath(path_5,paint_5_fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}