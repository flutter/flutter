import 'package:flutter/material.dart';
//import 'dart:js_util' as js_util;

void main() {
  runApp(MaterialApp(
      home: Scaffold(body: WebPerformanceSpike2()
      )
  ));
}

bool enableShadows = false;
double spinCount = 2;
bool useRepaintBoundaries = true;

class WebPerformanceSpike2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
        builder: (_, setState) => Stack(
          children: <Widget>[
            //Left
            Positioned(top: 0, bottom: 0, left: 0, width: 200, child: _ShadowBox(spinCount > 0)),
            //Top
            Positioned(top: 0, left: 200, right: 200, height: 200, child: _ShadowBox(spinCount > 1)),
            //Right
            Positioned(top: 0, bottom: 0, right: 0, width: 200, child: _ShadowBox(spinCount > 2)),
            Positioned(
                top: 200,
                bottom: 0,
                left: 200,
                right: 200,
                child: ListView(
                  children: <Widget>[
                    //Bottom
                    _ShadowBox(spinCount > 3),
                    _ShadowBox(spinCount > 4),
                    _ShadowBox(spinCount > 5),
                    _ShadowBox(spinCount > 6),
                    _ShadowBox(spinCount > 7),
                  ],
                )),
            Positioned(
              left: 250,
              top: 30,
              width: 600,
              child: Column(
                children: <Widget>[
                  FpsIndicator(),
                  Text("Shadows:"),
                  Checkbox(tristate: false, value: enableShadows, onChanged: (v) => setState(() => enableShadows = v)),
                  SizedBox(
                    width: 20,
                  ),
                  Text("RepaintBoundary:"),
                  Checkbox(
                      tristate: false,
                      value: useRepaintBoundaries,
                      onChanged: (v) => setState(() => useRepaintBoundaries = v)),
                  SizedBox(
                    width: 20,
                  ),
                  Text("Spin Count:"),
                  Slider(
                      min: 1, max: 8, divisions: 7, value: spinCount, onChanged: (v) => setState(() => spinCount = v)),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

class _ShadowBox extends StatelessWidget {
  final bool showIndicator;

  const _ShadowBox(this.showIndicator, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    BoxShadow shadow = BoxShadow(spreadRadius: 5, blurRadius: 5, color: Colors.black.withOpacity(.05));
    Widget spinner = !useRepaintBoundaries
        ? CircularProgressIndicator()
        : RepaintBoundary(child: CircularProgressIndicator(backgroundColor: Colors.red));
    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, boxShadow: enableShadows ? [shadow] : null),
      alignment: Alignment.center,
      width: double.infinity,
      height: 100,
      child: SizedBox(width: 10, height: 10, child: showIndicator ?? true ? spinner : Container()),
    );
  }
}

class FpsIndicator extends StatelessWidget {
  int get nowMs => DateTime.now().millisecondsSinceEpoch;

  @override
  Widget build(BuildContext context) {
    int lastFps = nowMs;
    int ticks = 0;
    int fpsValue = 60;
    return Container(
      width: 50,
      alignment: Alignment.center,
      child: StatefulBuilder(builder: (_, setState) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(days: 1),
          builder: (_, value, __) {
            if (nowMs - lastFps > 1000) {
              fpsValue = ticks;
              ticks = 0;
              lastFps = nowMs;
            }
            ticks++;
            return Text("FPS: $fpsValue", softWrap: false, maxLines: 1);
          },
        );
      }),
    );
  }
}
