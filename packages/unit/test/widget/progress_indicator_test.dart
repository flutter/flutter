
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('LinearProgressIndicator changes when its value changes', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Block(<Widget>[new LinearProgressIndicator(value: 0.0)]));

      List<Layer> layers1 = tester.layers;

      tester.pumpWidget(new Block(<Widget>[new LinearProgressIndicator(value: 0.5)]));

      List<Layer> layers2 = tester.layers;
      expect(layers1, isNot(equals(layers2)));
    });
  });
}
