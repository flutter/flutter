// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

List<String> ancestors = <String>[];

class TestWidget extends StatefulWidget {
  const TestWidget({ Key key }) : super(key: key);
  @override
  TestWidgetState createState() => TestWidgetState();
}

class TestWidgetState extends State<TestWidget> {
  @override
  void initState() {
    super.initState();
    context.visitAncestorElements((Element element) {
      ancestors.add(element.widget.runtimeType.toString());
      return true;
    });
  }

  @override
  Widget build(BuildContext context) => Container();
}

void main() {
  testWidgets('initState() is called when we are in the tree', (WidgetTester tester) async {
    await tester.pumpWidget(Container(child: const TestWidget()));
    expect(ancestors, equals(<String>['Container', 'RenderObjectToWidgetAdapter<RenderBox>']));
  });
}
