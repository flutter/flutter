// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Sliver in a box', (WidgetTester tester) async {
    await tester.pumpWidget(
      new DecoratedBox(
        decoration: const BoxDecoration(),
        child: new SliverList(
          delegate: const SliverChildListDelegate(const <Widget>[]),
        ),
      ),
    );

    expect(tester.takeException(), isFlutterError);

    await tester.pumpWidget(
      new Row(
        children: <Widget>[
          new SliverList(
            delegate: const SliverChildListDelegate(const <Widget>[]),
          ),
        ],
      ),
    );

    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('Box in a sliver', (WidgetTester tester) async {
    await tester.pumpWidget(
      new CustomScrollView(
        slivers: <Widget>[
          const SizedBox(),
        ],
      )
    );

    expect(tester.takeException(), isFlutterError);

    await tester.pumpWidget(
      new CustomScrollView(
        slivers: <Widget>[
          const SliverPadding(
            padding: EdgeInsets.zero,
            sliver: const SizedBox(),
          ),
        ],
      )
    );

    expect(tester.takeException(), isFlutterError);
  });
}
