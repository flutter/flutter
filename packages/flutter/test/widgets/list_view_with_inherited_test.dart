// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

List<int> items = <int>[0, 1, 2, 3, 4, 5];

Widget buildCard(BuildContext context, int index) {
  if (index >= items.length)
    return null;
  return Container(
    key: ValueKey<int>(items[index]),
    height: 100.0,
    child: DefaultTextStyle(
      style: TextStyle(fontSize: 2.0 + items.length.toDouble()),
      child: Text('${items[index]}', textDirection: TextDirection.ltr)
    )
  );
}

Widget buildFrame() {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: ListView.builder(
      itemBuilder: buildCard,
    ),
  );
}

void main() {
  testWidgets('ListView is a build function (smoketest)', (WidgetTester tester) async {
    await tester.pumpWidget(buildFrame());
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    items.removeAt(2);
    await tester.pumpWidget(buildFrame());
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsOneWidget);
  });
}
