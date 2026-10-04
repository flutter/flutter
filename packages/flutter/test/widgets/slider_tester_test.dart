// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'slider_tester.dart';

Widget _buildSlider({required double value, required ValueChanged<double> onChanged}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: TestSlider(value: value, onChanged: onChanged),
    ),
  );
}

void main() {
  testWidgets('TestSlider has correct size', (WidgetTester tester) async {
    await tester.pumpWidget(_buildSlider(value: 0.5, onChanged: (_) {}));

    final Size size = tester.getSize(find.byType(SizedBox));
    expect(size, const Size(200.0, 36.0));
  });

  testWidgets('TestSlider provides correct semantics', (WidgetTester tester) async {
    await tester.pumpWidget(_buildSlider(value: 0.5, onChanged: (_) {}));

    final SemanticsNode node = tester.getSemantics(find.byType(TestSlider));
    expect(node.value, '50%');
    expect(node.increasedValue, '60%');
    expect(node.decreasedValue, '40%');
  });

  testWidgets('TestSlider increase action increments value by 10%', (WidgetTester tester) async {
    var value = 0.5;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return _buildSlider(
            value: value,
            onChanged: (double newValue) {
              setState(() {
                value = newValue;
              });
            },
          );
        },
      ),
    );

    final SemanticsHandle handle = tester.ensureSemantics();
    final SemanticsNode node = tester.getSemantics(find.byType(TestSlider));
    tester.binding.pipelineOwner.semanticsOwner!.performAction(node.id, SemanticsAction.increase);
    await tester.pump();

    expect(value, closeTo(0.6, 0.001));
    handle.dispose();
  });

  testWidgets('TestSlider decrease action decrements value by 10%', (WidgetTester tester) async {
    var value = 0.5;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return _buildSlider(
            value: value,
            onChanged: (double newValue) {
              setState(() {
                value = newValue;
              });
            },
          );
        },
      ),
    );

    final SemanticsHandle handle = tester.ensureSemantics();
    final SemanticsNode node = tester.getSemantics(find.byType(TestSlider));
    tester.binding.pipelineOwner.semanticsOwner!.performAction(node.id, SemanticsAction.decrease);
    await tester.pump();

    expect(value, closeTo(0.4, 0.001));
    handle.dispose();
  });

  testWidgets('TestSlider clamps value at maximum of 1.0', (WidgetTester tester) async {
    var value = 0.95;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return _buildSlider(
            value: value,
            onChanged: (double newValue) {
              setState(() {
                value = newValue;
              });
            },
          );
        },
      ),
    );

    final SemanticsHandle handle = tester.ensureSemantics();
    final SemanticsNode node = tester.getSemantics(find.byType(TestSlider));
    tester.binding.pipelineOwner.semanticsOwner!.performAction(node.id, SemanticsAction.increase);
    await tester.pump();

    expect(value, 1.0);
    handle.dispose();
  });

  testWidgets('TestSlider clamps value at minimum of 0.0', (WidgetTester tester) async {
    var value = 0.05;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return _buildSlider(
            value: value,
            onChanged: (double newValue) {
              setState(() {
                value = newValue;
              });
            },
          );
        },
      ),
    );

    final SemanticsHandle handle = tester.ensureSemantics();
    final SemanticsNode node = tester.getSemantics(find.byType(TestSlider));
    tester.binding.pipelineOwner.semanticsOwner!.performAction(node.id, SemanticsAction.decrease);
    await tester.pump();

    expect(value, 0.0);
    handle.dispose();
  });

  testWidgets('TestSlider semantics reflect boundary values correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildSlider(value: 0.0, onChanged: (_) {}));

    final SemanticsNode nodeAtMin = tester.getSemantics(find.byType(TestSlider));
    expect(nodeAtMin.value, '0%');
    expect(nodeAtMin.decreasedValue, '0%');
    expect(nodeAtMin.increasedValue, '10%');

    await tester.pumpWidget(_buildSlider(value: 1.0, onChanged: (_) {}));

    final SemanticsNode nodeAtMax = tester.getSemantics(find.byType(TestSlider));
    expect(nodeAtMax.value, '100%');
    expect(nodeAtMax.increasedValue, '100%');
    expect(nodeAtMax.decreasedValue, '90%');
  });
}
