// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

class Changer extends StatefulWidget {
  @override
  ChangerState createState() => new ChangerState();
}

class ChangerState extends State<Changer> {
  void test0() { setState(() { }); }
  void test1() { setState(() => 1); }
  void test2() { setState(() async { }); }

  @override
  Widget build(BuildContext context) => new Text('test');
}

void main() {
  testWidgets('setState() catches being used with an async callback', (WidgetTester tester) async {
    await tester.pumpWidget(new Changer());
    ChangerState s = tester.state(find.byType(Changer));
    expect(s.test0, isNot(throws));
    expect(s.test1, isNot(throws));
    expect(s.test2, throws);
  });
}
