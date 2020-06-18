// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Render and element tree stay in sync when keyed children move around', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/48855.

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: const <Widget>[
            Text('0', key: ValueKey<int>(0)),
            Text('1', key: ValueKey<int>(1)),
            Text('2', key: ValueKey<int>(2)),
            Text('3', key: ValueKey<int>(3)),
            Text('4', key: ValueKey<int>(4)),
            Text('5', key: ValueKey<int>(5)),
            Text('6', key: ValueKey<int>(6)),
            Text('7', key: ValueKey<int>(7)),
            Text('8', key: ValueKey<int>(8)),
          ],
        ),
      ),
    );

    expect(
      _getChildOrder(tester.renderObject<RenderFlex>(find.byType(Column))),
      <String>['0', '1', '2', '3', '4', '5', '6', '7', '8'],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: const <Widget>[
            Text('0', key: ValueKey<int>(0)),
            Text('6', key: ValueKey<int>(6)),
            Text('7', key: ValueKey<int>(7)),
            Text('8', key: ValueKey<int>(8)),
            Text('1', key: ValueKey<int>(1)),
            Text('2', key: ValueKey<int>(2)),
            Text('3', key: ValueKey<int>(3)),
            Text('4', key: ValueKey<int>(4)),
            Text('5', key: ValueKey<int>(5)),
          ],
        ),
      ),
    );

    expect(
      _getChildOrder(tester.renderObject<RenderFlex>(find.byType(Column))),
      <String>['0', '6', '7', '8', '1', '2', '3', '4', '5'],
    );
  });
}

// Do not use tester.renderObjectList(find.byType(RenderParagraph). That returns
// the RenderObjects in the order of their associated RenderObjectWidgets. The
// point of this test is to assert the children order in the render tree, though.
List<String> _getChildOrder(RenderFlex flex) {
  final List<String> childOrder = <String>[];
  flex.visitChildren((RenderObject child) {
    childOrder.add(((child as RenderParagraph).text as TextSpan).text);
  });
  return childOrder;
}
