import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

ui.Shader createShader(Rect bounds) {
  return new LinearGradient(
      begin: Point.origin,
      end: new Point(0.0, bounds.height),
      colors: <Color>[const Color(0x00FFFFFF), const Color(0xFFFFFFFF)],
      stops: <double>[0.1, 0.35]
  )
  .createShader();
}


void main() {
  test('Can be constructed', () {
    testWidgets((WidgetTester tester) {
      Widget child = new Container(width: 100.0, height: 100.0);
      tester.pumpWidget(new ShaderMask(child: child, shaderCallback: createShader));
    });
  });
}
