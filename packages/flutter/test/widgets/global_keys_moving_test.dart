// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

class Item {
  GlobalKey key1 = GlobalKey();
  GlobalKey key2 = GlobalKey();

  @override
  String toString() => 'Item($key1, $key2)';
}
List<Item> items = <Item>[Item(), Item()];

class StatefulLeaf extends StatefulWidget {
  const StatefulLeaf({ GlobalKey key }) : super(key: key);

  @override
  StatefulLeafState createState() => StatefulLeafState();
}

class StatefulLeafState extends State<StatefulLeaf> {
  void markNeedsBuild() { setState(() { }); }

  @override
  Widget build(BuildContext context) => const Text('leaf', textDirection: TextDirection.ltr);
}

class KeyedWrapper extends StatelessWidget {
  const KeyedWrapper(this.key1, this.key2);

  final Key key1;
  final Key key2;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key1,
      child: StatefulLeaf(
        key: key2,
      )
    );
  }
}

Widget builder() {
  return Column(
    children: <Widget>[
      KeyedWrapper(items[1].key1, items[1].key2),
      KeyedWrapper(items[0].key1, items[0].key2),
    ],
  );
}

void main() {
  testWidgets('moving subtrees with global keys - smoketest', (WidgetTester tester) async {
    await tester.pumpWidget(builder());
    final StatefulLeafState leaf = tester.firstState(find.byType(StatefulLeaf));
    leaf.markNeedsBuild();
    await tester.pump();
    final Item lastItem = items[1];
    items.remove(lastItem);
    items.insert(0, lastItem);
    await tester.pumpWidget(builder()); // this marks the app dirty and rebuilds it
  });
}
