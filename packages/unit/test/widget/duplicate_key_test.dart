// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

class Item {
  GlobalKey key1 = new GlobalKey();
  GlobalKey key2 = new GlobalKey();
  String toString() => "Item($key1, $key2)";
}
List<Item> items = <Item>[new Item(), new Item()];

class StatefulLeaf extends StatefulComponent {
  StatefulLeaf({ GlobalKey key }) : super(key: key);
  StatefulLeafState createState() => new StatefulLeafState();
}

class StatefulLeafState extends State<StatefulLeaf> {
  void test() { setState(() { }); }
  Widget build(BuildContext context) => new Text('leaf');
}

class KeyedWrapper extends StatelessComponent {
  KeyedWrapper(this.key1, this.key2);
  Key key1, key2;
  Widget build(BuildContext context) {
    return new Container(
      key: key1,
      child: new StatefulLeaf(
        key: key2
      )
    );
  }
}

Widget builder() {
  return new Column(<Widget>[
    new KeyedWrapper(items[1].key1, items[1].key2),
    new KeyedWrapper(items[0].key1, items[0].key2)
  ]);
}

void main() {
  test('duplicate key smoke test', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(builder());
      StatefulLeafState leaf = tester.findStateOfType(StatefulLeafState);
      leaf.test();
      tester.pump();
      Item lastItem = items[1];
      items.remove(lastItem);
      items.insert(0, lastItem);
      tester.pumpWidget(builder()); // this marks the app dirty and rebuilds it
    });
  });
}
