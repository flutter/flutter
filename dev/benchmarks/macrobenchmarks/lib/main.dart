import 'package:flutter/foundation.dart' show defaultShaderWarmUp;
import 'package:flutter/material.dart';

import 'common.dart';
import 'src/cubic_bezier.dart';
import 'src/cull_opacity.dart';

const String kMacrobenchmarks ='Macrobenchmarks';

void main() => runApp(
  MacrobenchmarksApp(),
  shaderWarmUp: (Canvas canvas) {
    defaultShaderWarmUp(canvas);

    // Warm up the cubic shaders used by CubicBezierPage.
    //
    // This tests that our custom shader warm up is working properly.
    // Without this custom shader warm up, the worst frame time is about 115ms.
    // With this, the worst frame time is about 70ms. (Data collected on a Moto
    // G4 based on Flutter version 704814c67a874077710524d30412337884bf0254.
    final Path path = Path();
    path.moveTo(20, 20);
    // This cubic path is copied from
    // https://skia.org/user/api/SkPath_Reference#SkPath_cubicTo
    path.cubicTo(300, 80, -140, 90, 220, 10);
    final Paint paint = Paint();
    paint.isAntiAlias = true;
    paint.strokeWidth = 18.0;
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }
);

class MacrobenchmarksApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kMacrobenchmarks,
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => HomePage(),
        kCullOpacityRouteName: (BuildContext context) => CullOpacityPage(),
        kCubicBezierRouteName: (BuildContext context) => CubicBezierPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(kMacrobenchmarks)),
      body: ListView(
        children: <Widget>[
          RaisedButton(
            key: const Key(kCullOpacityRouteName),
            child: const Text('Cull opacity'),
            onPressed: (){
              Navigator.pushNamed(context, kCullOpacityRouteName);
            },
          ),
          RaisedButton(
            key: const Key(kCubicBezierRouteName),
            child: const Text('Cubic Bezier'),
            onPressed: (){
              Navigator.pushNamed(context, kCubicBezierRouteName);
            },
          )
        ],
      ),
    );
  }
}
