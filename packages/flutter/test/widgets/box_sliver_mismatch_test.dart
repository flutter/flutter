// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sliver in a box', (WidgetTester tester) async {
    await tester.pumpWidget(
      DecoratedBox(
        decoration: const BoxDecoration(),
        child: SliverList(
          delegate: SliverChildListDelegate(const <Widget>[]),
        ),
      ),
    );

    expect(tester.takeException(), isFlutterError);

    await tester.pumpWidget(
      Row(
        children: <Widget>[
          SliverList(
            delegate: SliverChildListDelegate(const <Widget>[]),
          ),
        ],
      ),
    );

    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('Box in a sliver', (WidgetTester tester) async {
    late ViewportOffset offset1;
    addTearDown(() => offset1.dispose());
    await tester.pumpWidget(
      Viewport(
        crossAxisDirection: AxisDirection.right,
        offset: offset1 = ViewportOffset.zero(),
        slivers: const <Widget>[
          SizedBox(),
        ],
      ),
    );

    expect(tester.takeException(), isFlutterError);

    late ViewportOffset offset2;
    addTearDown(() => offset2.dispose());
    await tester.pumpWidget(
      Viewport(
        crossAxisDirection: AxisDirection.right,
        offset: offset2 = ViewportOffset.zero(),
        slivers: const <Widget>[
          SliverPadding(
            padding: EdgeInsets.zero,
            sliver: SizedBox(),
          ),
        ],
      ),
    );

    expect(tester.takeException(), isFlutterError);
  });
}
